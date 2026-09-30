#!/usr/bin/env python3
# ==============================================================================
# OAEF Governance Engine - Python 3 Runtime
# Author: Felipe Carvalho | License: Apache 2.0
# ==============================================================================

import os
import sys
import json
import re
import subprocess

def main():
    args = sys.argv[1:]
    if not args:
        print_usage()
        sys.exit(1)

    cmd = args[0]
    if cmd in ("quality-gate", "audit"):
        record = "--record" in args or "--ratchet" in args
        run_quality_gate(record=record)
    elif cmd == "metrics":
        run_metrics()
    elif cmd == "lint":
        run_lint()
    elif cmd == "sync":
        run_sync()
    else:
        print(f"Unknown command: {cmd}")
        print_usage()
        sys.exit(1)

def print_usage():
    print("""OAEF Governance Tool (Python Engine)
Usage: python3 tool/governance.py <command>
Commands:
  quality-gate [--record]  Audit Quality Gates & ratchet baseline
  metrics                  Display historical metrics report
  lint                     Audit links, cascade references & secrets
  sync                     Synchronize AGENTS.md to mirrors""")

def run_quality_gate(record=False):
    print("\n🔍 Initiating OAEF Quality Gate Audit (Python)...")
    baseline_path = "docs/wiki/metrics/baseline.json"
    baseline = {}
    if os.path.exists(baseline_path):
        with open(baseline_path, "r", encoding="utf-8") as f:
            baseline = json.load(f).get("baseline", {})

    coverage_cfg = baseline.get("coverage", {})
    min_line = coverage_cfg.get("lines_min_percentage", 95.0)
    sizing_cfg = baseline.get("clean_sizing", {})
    max_file_lines = sizing_cfg.get("file_max_lines", 300)

    # Run tests
    print("ℹ️  Running pytest with coverage...")
    try:
        subprocess.run(["pytest", "--cov=.", "--cov-report=lcov"], check=True)
    except Exception:
        print("❌ Tests failed.", file=sys.stderr)
        sys.exit(1)

    # Parse LCOV
    lines_found = 0
    lines_hit = 0
    lcov_file = "coverage.lcov"
    if os.path.exists(lcov_file):
        with open(lcov_file, "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("LF:"):
                    lines_found += int(line[3:].strip() or 0)
                elif line.startswith("LH:"):
                    lines_hit += int(line[3:].strip() or 0)

    line_percent = 100.0 if lines_found == 0 else (lines_hit / lines_found) * 100.0
    print(f"📊 Line Coverage: {line_percent:.1f}% (Floor: {min_line}%)")

    # Clean sizing
    oversized = 0
    for root, _, files in os.walk("."):
        if any(ignored in root for ignored in (".venv", "venv", ".git", "build", "__pycache__")):
            continue
        for file in files:
            if file.endswith(".py") and not file.startswith("test_"):
                path = os.path.join(root, file)
                with open(path, "r", encoding="utf-8", errors="ignore") as f:
                    count = len(f.readlines())
                    if count > max_file_lines:
                        oversized += 1
                        print(f"⚠️  Oversized file ({count}L > {max_file_lines}L): {path}", file=sys.stderr)

    if line_percent < min_line or oversized > 0:
        print("❌ Quality Gates Failed.", file=sys.stderr)
        sys.exit(1)

    print("\n🎉 Quality Gates PASSED!\n")
    if record and line_percent > min_line:
        coverage_cfg["lines_min_percentage"] = round(line_percent, 1)
        baseline["coverage"] = coverage_cfg
        with open(baseline_path, "w", encoding="utf-8") as f:
            json.dump({"baseline": baseline}, f, indent=2)
        print(f"🔒 Monotonic Ratchet: Updated baseline floor to {line_percent:.1f}%")

def run_lint():
    print("🔍 Executing OAEF Integrity & Secret Audits...")
    failed = False

    # Mirror parity
    if os.path.exists("AGENTS.md") and os.path.exists("CLAUDE.md"):
        with open("AGENTS.md", "r", encoding="utf-8") as f:
            agents = f.read().strip()
        with open("CLAUDE.md", "r", encoding="utf-8") as f:
            claude = f.read().strip()
        if claude.startswith("<!--"):
            end = claude.find("-->")
            if end != -1:
                claude = claude[end+3:].strip()
        if agents != claude:
            print("❌ [LINT] CLAUDE.md diverged from AGENTS.md.", file=sys.stderr)
            failed = True

    # Secret scanner
    patterns = [
        re.compile(r"sk-[a-zA-Z0-9]{20,}"),
        re.compile(r"ghp_[a-zA-Z0-9]{20,}"),
        re.compile(r"AKIA[0-9A-Z]{16}"),
        re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
    ]

    for root, _, files in os.walk("docs"):
        for file in files:
            if file.endswith(".md"):
                p = os.path.join(root, file)
                with open(p, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                    for pat in patterns:
                        if pat.search(content):
                            print(f"🚨 [SECURITY] Potential secret detected in {p}!", file=sys.stderr)
                            failed = True

    # Anti-suppression scanner (# noqa, # type: ignore, # pylint: disable)
    suppression_patterns = [
        re.compile(r"#\s*noqa"),
        re.compile(r"#\s*type:\s*ignore"),
        re.compile(r"#\s*pylint:\s*disable"),
    ]
    allowed_deprecation_tokens = ["W1505", "B005", "deprecated-method", "type: ignore[deprecated]"]

    for root, _, files in os.walk("."):
        if any(ignored in root for ignored in (".venv", "venv", ".git", "build", "__pycache__")):
            continue
        for file in files:
            if file.endswith(".py") and not file.startswith("test_"):
                # Exempt machine-generated protobuf/grpc files
                if file.endswith("_pb2.py") or file.endswith("_pb2_grpc.py") or file.endswith(".generated.py"):
                    continue
                path = os.path.join(root, file)
                with open(path, "r", encoding="utf-8", errors="ignore") as f:
                    file_content = f.read()
                    if "# Generated by" in file_content or "# Code generated" in file_content:
                        continue
                    for line_idx, line in enumerate(file_content.splitlines(), start=1):
                        for sp in suppression_patterns:
                            if sp.search(line):
                                # Check if line matches an allowed scoped deprecation exception
                                if any(tok in line for tok in allowed_deprecation_tokens):
                                    continue
                                print(f"🚨 [LINT] Unallowed suppression in {path}:{line_idx}: {line.strip()}", file=sys.stderr)
                                failed = True

    if failed:
        sys.exit(1)
    print("✅ [LINT] All audits passed cleanly.")

def run_sync():
    if not os.path.exists("AGENTS.md"):
        print("AGENTS.md not found.", file=sys.stderr)
        sys.exit(1)
    with open("AGENTS.md", "r", encoding="utf-8") as f:
        content = f.read()
    with open("CLAUDE.md", "w", encoding="utf-8") as f:
        f.write("<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->\n\n" + content)
    print("✅ Synchronized AGENTS.md -> CLAUDE.md")

def run_metrics():
    p = "docs/wiki/metrics/baseline.json"
    if os.path.exists(p):
        with open(p, "r", encoding="utf-8") as f:
            print(f.read())

if __name__ == "__main__":
    main()
