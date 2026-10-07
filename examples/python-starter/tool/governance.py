#!/usr/bin/env python3
# ==============================================================================
# OAEF Governance Engine - Python 3 Runtime
# Implements docs/standards/governance_checks.md for the `python` stack.
# Author: Felipe Carvalho | License: Apache 2.0
# ==============================================================================

import json
import os
import re
import shutil
import subprocess
import sys

# ------------------------------------------------------------------------------
# Repository root resolution (engine installed at tool/governance.py)
# ------------------------------------------------------------------------------
_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(_SCRIPT_DIR) if os.path.basename(_SCRIPT_DIR) == "tool" else os.getcwd()
os.chdir(ROOT)

# ------------------------------------------------------------------------------
# Canonical catalog (must stay byte-identical to AGENTS.md section 3)
# ------------------------------------------------------------------------------
SKILLS = [
    "ponytail",
    "nullable-types",
    "architecture-audit",
    "screen-builder",
    "component-author",
    "responsive-layout",
    "ui-preview",
    "fix-layout-issues",
    "test-generator",
    "collect-coverage",
    "run-static-analysis",
    "code-review",
    "conformance-audit",
]

TRIGGERS = {
    "ponytail": ["new", "refactor", "add", "simple", "minimal", "yagni", "dead code", "delete", "remove"],
    "nullable-types": ["null", "optional", "nil", "guard clause", "defensive"],
    "architecture-audit": ["architecture", "boundary", "coupling", "cycle"],
    "screen-builder": ["screen", "page", "feature", "flow", "view"],
    "component-author": ["component", "widget", "button", "card", "modal"],
    "responsive-layout": ["responsive", "adaptive", "breakpoint", "tablet", "foldable", "viewport"],
    "ui-preview": ["preview", "storybook", "isolated render"],
    "fix-layout-issues": ["overflow", "unbounded", "layout", "layout broken", "render error"],
    "test-generator": ["test", "coverage", "mock", "fixture"],
    "collect-coverage": ["coverage", "lcov", "jacoco", "cobertura", "branches"],
    "run-static-analysis": ["analyze", "lint", "typecheck", "warnings"],
    "code-review": ["review", "pr", "checklist", "pre-pr"],
    "conformance-audit": ["conformance", "doctor", "parity", "frontmatter"],
}

META_SKILL = ("ponytail", "collect-coverage", "run-static-analysis", "conformance-audit")

ROUTING_FIXTURES = [
    ("create a new screen for the booking flow", "screen-builder"),
    ("build a reusable button component", "component-author"),
    ("the layout overflows on small screens", "fix-layout-issues"),
    ("add responsive breakpoints for tablet", "responsive-layout"),
    ("write unit tests for the payment service", "test-generator"),
    ("collect coverage and check the branch floor", "collect-coverage"),
    ("fix all analyzer warnings", "run-static-analysis"),
    ("this optional list parameter is always null", "nullable-types"),
    ("audit module boundaries and cyclic imports", "architecture-audit"),
    ("verify the repo conforms to the framework", "conformance-audit"),
    ("review my PR before I open it", "code-review"),
    ("remove the dead code and the 1-line use case", "ponytail"),
]

RECIPES = [
    "1. Feature / Screen Construction: ponytail -> screen-builder + responsive-layout -> ui-preview -> test-generator -> collect-coverage -> run-static-analysis -> code-review",
    "2. Reusable Component / Module Authoring: ponytail -> component-author -> ui-preview -> responsive-layout -> test-generator -> run-static-analysis",
    "3. Bug Fix / Root-Cause Remediation: ponytail (root-cause caller grep) -> fix-layout-issues (UI) / nullable-types (logic) -> test-generator -> run-static-analysis",
    "4. Domain, Data & Infrastructure: ponytail -> nullable-types -> test-generator -> collect-coverage -> run-static-analysis",
    "5. Pre-Submission / Pull Request Cycle: collect-coverage -> run-static-analysis -> code-review",
]

MIRROR_DIRS = [".claude/skills", ".cursor/rules", ".windsurf/skills", ".cline/skills", ".grok/agents"]

ENGINE_FILES = [
    "tool/governance.dart", "tool/governance.mjs", "tool/governance.py", "tool/governance.go",
    "tool/governance.rs", "tool/governance.main.kts", "tool/governance.swift",
    "tool/Governance.cs", "tool/governance.sh",
]

CONTEXT_FILE = "oaef.context.json"
BASELINE_FILE = "docs/wiki/metrics/baseline.json"
ADOPTION_LEDGER = "docs/wiki/metrics/adoption.json"
AGENTS_FILE = "AGENTS.md"
LLMS_FILE = "llms.txt"

CRYPTIC = set(
    "cb fn res req btn val tmp ctx el usr mgr idx cnt buf str num doc elem curr prev".split()
)

EXCLUDED_SEGMENTS = set(
    ".git .github .agents .claude .cursor .windsurf .cline .grok .oaef node_modules vendor "
    "build dist target obj bin tool docs templates examples coverage generated .venv venv "
    "__pycache__ .dart_tool .gradle .idea".split()
)
TEST_SEGMENTS = set("test tests __tests__ spec specs androidTest iosTest".split())

EXCLUDED_FILE_PATTERNS = [
    re.compile(r".*\.g\..*"),
    re.compile(r".*_pb2\.py$"),
    re.compile(r".*_pb2_grpc\.py$"),
    re.compile(r".*\.min\.js$"),
    re.compile(r".*\.generated\..*"),
    re.compile(r".*\.freezed\..*"),
    re.compile(r".*\.designer\..*"),
]
TEST_FILE_PATTERNS = [
    re.compile(r".*_test\..*"),
    re.compile(r".*\.spec\..*"),
    re.compile(r".*\.test\..*"),
    re.compile(r"^test_.*\.py$"),
    re.compile(r".*Tests\.cs$"),
    re.compile(r".*Test\.kt$"),
]

CC_MESSAGES = {
    "CC-01": 'prohibited single-letter identifier "<name>"; use a descriptive name',
    "CC-02": 'prohibited cryptic abbreviation "<name>"; use the full identifier',
    "CC-03": "prohibited mutable lazy initialization; inject the dependency via constructor",
    "CC-04": "prohibited hardcoded placeholder/secret; source it from configuration/environment",
    "CC-05": "prohibited raw print/debug output in production code; use the logging interface",
    "CC-06": "prohibited silent exception swallowing; log with error+stack trace or rethrow",
    "CC-07": "prohibited service-locator resolution outside the composition root/presentation layer; inject via constructor",
    "CC-08": "prohibited nullable collection parameter; default to a constant empty collection",
    "CC-09": "prohibited unimplemented placeholder in production contract; implement the contract (LSP)",
    "CC-10": "prohibited concrete network-client instantiation outside the composition root; depend on an abstraction (DIP)",
    "CC-11": "[advisory] avoidable allocation on hot path; inspect without copying and return the original reference",
}

THRESHOLD_KEYS = {
    "CC-01": "max_single_letter_identifiers",
    "CC-02": "max_cryptic_abbreviations",
    "CC-03": "max_mutable_lazy_initializations",
    "CC-04": "max_dummy_keys",
    "CC-05": "max_raw_prints",
    "CC-06": "max_silent_catches",
    "CC-07": "max_service_locator_leaks",
    "CC-08": "max_nullable_collections",
    "CC-09": "max_unimplemented_placeholders",
    "CC-10": "max_concrete_client_instantiations",
    "CC-11": "max_avoidable_allocations",
}

CC_IDS = ["CC-01", "CC-02", "CC-03", "CC-04", "CC-05", "CC-06", "CC-07", "CC-08", "CC-09", "CC-10", "CC-11"]

# ------------------------------------------------------------------------------
# Global state
# ------------------------------------------------------------------------------
PROFILE = "strict"
ADOPTION_MODE = "install"

CC_TOTAL = 0
CC_COUNTS = {check_id: 0 for check_id in CC_IDS}
SK_FAILURES = 0

_FILE_CACHE = {}


# ------------------------------------------------------------------------------
# Small helpers
# ------------------------------------------------------------------------------
def read_lines(path):
    if path not in _FILE_CACHE:
        try:
            with open(path, "r", encoding="utf-8", errors="ignore") as handle:
                _FILE_CACHE[path] = handle.read().splitlines()
        except OSError:
            _FILE_CACHE[path] = []
    return _FILE_CACHE[path]


def indent_of(line):
    return len(line) - len(line.lstrip())


def strip_inline_comment(line):
    quote = None
    position = 0
    while position < len(line):
        char = line[position]
        if quote:
            if char == "\\":
                position += 2
                continue
            if char == quote:
                quote = None
        else:
            if char in ('"', "'"):
                quote = char
            elif char == "#":
                return line[:position]
        position += 1
    return line


def json_value(key, path):
    if not os.path.exists(path):
        return ""
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as handle:
            data = json.load(handle)
    except (OSError, ValueError):
        return ""
    value = data.get(key) if isinstance(data, dict) else None
    return value if isinstance(value, str) else ""


def resolve_profile(force_standard=False):
    global PROFILE, ADOPTION_MODE
    context_profile = json_value("strictness", CONTEXT_FILE)
    if context_profile:
        PROFILE = context_profile
    else:
        baseline_profile = json_value("profile", BASELINE_FILE)
        if baseline_profile:
            PROFILE = baseline_profile
    ADOPTION_MODE = json_value("adoption_mode", CONTEXT_FILE) or "install"
    if force_standard:
        PROFILE = "standard"
    elif ADOPTION_MODE != "install":
        PROFILE = ADOPTION_MODE


def is_adoption():
    return ADOPTION_MODE != "install"


def user_owned_skill(skill):
    if not os.path.exists(ADOPTION_LEDGER):
        return False
    try:
        with open(ADOPTION_LEDGER, "r", encoding="utf-8", errors="ignore") as handle:
            data = json.load(handle)
    except (OSError, ValueError):
        return False
    declared = data.get("user_skills") if isinstance(data, dict) else None
    return bool(declared) and skill in declared


def cc_blocking(check_id):
    if check_id == "CC-04":
        return True
    if check_id == "CC-11":
        return False
    if is_adoption():
        return False
    return PROFILE == "strict"


def cc_threshold(check_id):
    key = THRESHOLD_KEYS.get(check_id)
    if not key or not os.path.exists(BASELINE_FILE):
        return 0
    try:
        with open(BASELINE_FILE, "r", encoding="utf-8", errors="ignore") as handle:
            data = json.load(handle)
        value = data["baseline"]["clean_code"][key]
    except (OSError, ValueError, KeyError, TypeError):
        return 0
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return 0
    return value


# ------------------------------------------------------------------------------
# File discovery (production scope: repository root recursive, *.py)
# ------------------------------------------------------------------------------
def is_excluded_name(name):
    return any(pattern.match(name) for pattern in EXCLUDED_FILE_PATTERNS)


def is_test_path(rel):
    for segment in rel.split("/"):
        if segment in TEST_SEGMENTS:
            return True
    return any(pattern.match(os.path.basename(rel)) for pattern in TEST_FILE_PATTERNS)


def iter_python_files():
    for dirpath, dirnames, filenames in os.walk("."):
        dirnames[:] = sorted(name for name in dirnames if name not in EXCLUDED_SEGMENTS)
        for name in sorted(filenames):
            if not name.endswith(".py") or is_excluded_name(name):
                continue
            rel = os.path.relpath(os.path.join(dirpath, name), ".")
            yield rel.replace(os.sep, "/")


def production_files():
    return [rel for rel in iter_python_files() if not is_test_path(rel)]


def all_source_files():
    return list(iter_python_files())


def test_files():
    return [rel for rel in iter_python_files() if is_test_path(rel)]


# ------------------------------------------------------------------------------
# Finding emission
# ------------------------------------------------------------------------------
def emit(check_id, path, line, message):
    global CC_TOTAL
    sys.stdout.write("%s %s:%s \u2014 %s\n" % (check_id, path, line, message))
    CC_COUNTS[check_id] = CC_COUNTS.get(check_id, 0) + 1
    if check_id.startswith("CC-"):
        CC_TOTAL += 1


def emit_skill(check_id, path, line, message):
    global SK_FAILURES
    sys.stdout.write("%s %s:%s \u2014 %s\n" % (check_id, path, line, message))
    SK_FAILURES += 1


# ------------------------------------------------------------------------------
# CC-01 / CC-02 : identifier discipline
# ------------------------------------------------------------------------------
def split_params(text):
    parts = []
    depth = 0
    current = ""
    for char in text:
        if char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
        if char == "," and depth == 0:
            parts.append(current)
            current = ""
        else:
            current += char
    if current:
        parts.append(current)
    names = []
    for part in parts:
        part = part.strip().split("=")[0].strip().lstrip("*").strip()
        if not part or part in ("/", "*"):
            continue
        match = re.match(r"([A-Za-z_][A-Za-z0-9_]*)", part)
        if match:
            names.append(match.group(1))
    return names


def collect_signatures(lines):
    signatures = {}
    index = 0
    total = len(lines)
    while index < total:
        match = re.match(r"^\s*def\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(", lines[index])
        if match:
            text = lines[index]
            depth = text.count("(") - text.count(")")
            cursor = index
            while depth > 0 and cursor + 1 < total:
                cursor += 1
                text += " " + lines[cursor]
                depth += lines[cursor].count("(") - lines[cursor].count(")")
            start = text.index("(")
            depth = 0
            end = None
            for position in range(start, len(text)):
                if text[position] == "(":
                    depth += 1
                elif text[position] == ")":
                    depth -= 1
                    if depth == 0:
                        end = position
                        break
            params = text[start + 1:end] if end is not None else text[start + 1:]
            signatures[index] = (match.group(1), params, text)
        index += 1
    return signatures


def block_span(indents, index):
    indentation = indents[index]
    total = len(indents)
    start = index
    while start - 1 >= 0 and indents[start - 1] >= indentation:
        start -= 1
    end = index
    while end + 1 < total and indents[end + 1] >= indentation:
        end += 1
    return end - start + 1


def check_identifier_discipline(rel, lines, signatures):
    indents = [indent_of(line) for line in lines]
    for index, line in enumerate(lines):
        work = strip_inline_comment(line)
        if not work.strip():
            continue
        bindings = []
        match = re.match(r"^\s*for\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\b", work)
        if match:
            bindings.append((match.group(1), True))
        for match in re.finditer(r"\bas\s+([A-Za-z_][A-Za-z0-9_]*)", work):
            bindings.append((match.group(1), False))
        for match in re.finditer(r"\blambda\b([^:]*):", work):
            for name in split_params(match.group(1)):
                bindings.append((name, False))
        if index in signatures:
            for name in split_params(signatures[index][1]):
                bindings.append((name, False))
        match = re.match(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*(?::[^=]+)?=(?!=)", work)
        if match:
            bindings.append((match.group(1), False))

        seen = set()
        for name, is_loop in bindings:
            if name in seen or name in ("self", "cls"):
                continue
            seen.add(name)
            if len(name) == 1:
                if name == "_":
                    continue
                if name in ("i", "j") and (is_loop or block_span(indents, index) <= 5):
                    continue
                emit("CC-01", rel, index + 1, CC_MESSAGES["CC-01"].replace("<name>", name))
            elif name.lower() in CRYPTIC:
                emit("CC-02", rel, index + 1, CC_MESSAGES["CC-02"].replace("<name>", name))


# ------------------------------------------------------------------------------
# CC-03 : mutable lazy initialization
# ------------------------------------------------------------------------------
FIELD_TOKENS = re.compile(r"client|service|instance|provider", re.IGNORECASE)


def check_lazy_init(rel, lines):
    for index, line in enumerate(lines):
        work = strip_inline_comment(line)
        if not work.strip():
            continue
        match = re.match(
            r"^\s*(?:self\.)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?:self\.)?([A-Za-z_][A-Za-z0-9_]*)\s+or\b",
            work,
        )
        if match and match.group(1) == match.group(2) and FIELD_TOKENS.search(match.group(1)):
            emit("CC-03", rel, index + 1, CC_MESSAGES["CC-03"])
            continue
        match = re.match(
            r"^\s*if\s+(?:self\.)?([A-Za-z_][A-Za-z0-9_]*)\s+is\s+None\s*:\s*(?:self\.)?([A-Za-z_][A-Za-z0-9_]*)\s*=",
            work,
        )
        if match and match.group(1) == match.group(2) and FIELD_TOKENS.search(match.group(1)):
            emit("CC-03", rel, index + 1, CC_MESSAGES["CC-03"])
            continue
        match = re.match(r"^\s*if\s+(?:self\.)?([A-Za-z_][A-Za-z0-9_]*)\s+is\s+None\s*:\s*$", work)
        if match and FIELD_TOKENS.search(match.group(1)):
            for lookahead in range(index + 1, min(index + 4, len(lines))):
                candidate = strip_inline_comment(lines[lookahead]).strip()
                if not candidate:
                    continue
                assign = re.match(r"^(?:self\.)?([A-Za-z_][A-Za-z0-9_]*)\s*=", candidate)
                if assign and assign.group(1) == match.group(1):
                    emit("CC-03", rel, index + 1, CC_MESSAGES["CC-03"])
                break


# ------------------------------------------------------------------------------
# CC-04 : hardcoded placeholder / secret
# ------------------------------------------------------------------------------
SECRET_ASSIGN = re.compile(
    r"\b(api[_-]?key|secret|password|token)\s*(?::\s*[^=]+?)?=\s*(?P<val>.*)$",
    re.IGNORECASE,
)
PLACEHOLDER_TOKEN = re.compile(r"dummy_|changeme|TODO_KEY")
ENV_REFERENCE = re.compile(
    r"\{|\$|os\.environ|os\.getenv|environ|getenv|process\.env|System\.getenv"
)


def check_secrets(rel, lines):
    for index, line in enumerate(lines):
        work = strip_inline_comment(line)
        if not work.strip():
            continue
        if PLACEHOLDER_TOKEN.search(work):
            emit("CC-04", rel, index + 1, CC_MESSAGES["CC-04"])
            continue
        match = SECRET_ASSIGN.search(work)
        if match:
            value = match.group("val").strip()
            if value and value[0] in ('"', "'") and not ENV_REFERENCE.search(value):
                emit("CC-04", rel, index + 1, CC_MESSAGES["CC-04"])


# ------------------------------------------------------------------------------
# CC-05 : raw print / debug output
# ------------------------------------------------------------------------------
RAW_PRINT = re.compile(r"(?<![\w.])print\s*\(")


def check_raw_prints(rel, lines):
    for index, line in enumerate(lines):
        if line.lstrip().startswith("#!"):
            continue
        work = strip_inline_comment(line)
        if RAW_PRINT.search(work):
            emit("CC-05", rel, index + 1, CC_MESSAGES["CC-05"])


# ------------------------------------------------------------------------------
# CC-06 : silent exception swallowing
# ------------------------------------------------------------------------------
def handler_is_empty(body):
    effective = [strip_inline_comment(entry).strip() for entry in body]
    effective = [entry for entry in effective if entry]
    if not effective:
        return True
    return all(entry == "pass" for entry in effective)


def check_silent_catches(rel, lines):
    total = len(lines)
    for index, line in enumerate(lines):
        match = re.match(r"^(\s*)except\b([^:]*):\s*(.*)$", line)
        if not match:
            continue
        inline = match.group(3)
        if strip_inline_comment(inline).strip():
            if handler_is_empty([inline]):
                emit("CC-06", rel, index + 1, CC_MESSAGES["CC-06"])
            continue
        indentation = len(match.group(1))
        body = []
        cursor = index + 1
        while cursor < total:
            entry = lines[cursor]
            if not entry.strip():
                body.append(entry)
                cursor += 1
                continue
            if indent_of(entry) <= indentation:
                break
            body.append(entry)
            cursor += 1
        if handler_is_empty(body):
            emit("CC-06", rel, index + 1, CC_MESSAGES["CC-06"])


# ------------------------------------------------------------------------------
# CC-07 : service-locator confinement
# CC-10 : concrete network client
# ------------------------------------------------------------------------------
DI_TOKENS = re.compile(r"injector\.get\(|container\.resolve\(|Container\(\)\.resolve\(")
NETWORK_TOKENS = re.compile(r"requests\.Session\(|httpx\.Client\(|aiohttp\.ClientSession\(")


def allowed_composition_root(rel):
    parts = rel.split("/")
    if parts[-1] == "main.py":
        return True
    if "di" in parts[:-1]:
        return True
    return parts[-1].startswith("composition_root")


def check_service_locator(rel, lines):
    for index, line in enumerate(lines):
        work = strip_inline_comment(line)
        if DI_TOKENS.search(work) and not allowed_composition_root(rel):
            emit("CC-07", rel, index + 1, CC_MESSAGES["CC-07"])


def check_concrete_client(rel, lines):
    for index, line in enumerate(lines):
        work = strip_inline_comment(line)
        if NETWORK_TOKENS.search(work) and not allowed_composition_root(rel):
            emit("CC-10", rel, index + 1, CC_MESSAGES["CC-10"])


# ------------------------------------------------------------------------------
# CC-08 : nullable collection in a signature
# ------------------------------------------------------------------------------
OPTIONAL_COLLECTION = re.compile(
    r"Optional\s*\[\s*(?:[A-Za-z_][\w.]*\s*\.\s*)?(?:List|Dict|Set|list|dict|set)\b"
)
UNION_COLLECTION = re.compile(
    r"\b(?:list|dict|set|List|Dict|Set)\s*\[[^\[\]]*\]\s*\|\s*None\b"
)


def check_nullable_collections(rel, signatures):
    for index, (_, _, full) in signatures.items():
        if OPTIONAL_COLLECTION.search(full) or UNION_COLLECTION.search(full):
            emit("CC-08", rel, index + 1, CC_MESSAGES["CC-08"])


# ------------------------------------------------------------------------------
# CC-09 : unimplemented placeholder
# ------------------------------------------------------------------------------
UNIMPLEMENTED = re.compile(r"\braise\s+NotImplementedError\b")


def check_unimplemented(rel, lines):
    for index, line in enumerate(lines):
        work = strip_inline_comment(line)
        if work.strip().startswith("#"):
            continue
        if UNIMPLEMENTED.search(work):
            emit("CC-09", rel, index + 1, CC_MESSAGES["CC-09"])


# ------------------------------------------------------------------------------
# CC-11 : avoidable allocation on a hot path (advisory; also scans tests)
# ------------------------------------------------------------------------------
LOOP_HEADER = re.compile(r"^\s*(?:for|while)\b")
ALLOCATION_CALL = re.compile(r"\b(?:list|dict)\s*\(")
LIST_DISPLAY = re.compile(r"(?:^|[=\(\[,]|\breturn\s+)\s*\[")


def check_allocations(rel, lines):
    total = len(lines)
    for index, line in enumerate(lines):
        if not LOOP_HEADER.match(line):
            continue
        base = indent_of(line)
        cursor = index + 1
        while cursor < total:
            entry = lines[cursor]
            if not entry.strip():
                cursor += 1
                continue
            if indent_of(entry) <= base:
                break
            work = strip_inline_comment(entry)
            if work.strip().startswith("#"):
                cursor += 1
                continue
            if ALLOCATION_CALL.search(work) or LIST_DISPLAY.search(work):
                emit("CC-11", rel, cursor + 1, CC_MESSAGES["CC-11"])
            cursor += 1


# ------------------------------------------------------------------------------
# The CC-* suite
# ------------------------------------------------------------------------------
def run_clean_code_report():
    for rel in production_files():
        lines = read_lines(rel)
        signatures = collect_signatures(lines)
        check_identifier_discipline(rel, lines, signatures)
        check_lazy_init(rel, lines)
        check_secrets(rel, lines)
        check_raw_prints(rel, lines)
        check_silent_catches(rel, lines)
        check_service_locator(rel, lines)
        check_nullable_collections(rel, signatures)
        check_unimplemented(rel, lines)
        check_concrete_client(rel, lines)
        check_allocations(rel, lines)
    for rel in test_files():
        check_allocations(rel, read_lines(rel))


def blocking_total():
    total = 0
    for check_id in CC_IDS:
        count = CC_COUNTS.get(check_id, 0)
        if count <= 0:
            continue
        if cc_blocking(check_id) and count > cc_threshold(check_id):
            total += count
    return total


def run_clean_code(args):
    resolve_profile(force_standard="--standard" in args)
    run_clean_code_report()
    behavior = "blocking" if cc_blocking("CC-01") else "advisory"
    sys.stdout.write(
        "Clean Code: %s violation(s) (%s profile: %s)\n" % (CC_TOTAL, PROFILE, behavior)
    )
    if blocking_total() > 0:
        sys.exit(1)


# ------------------------------------------------------------------------------
# PT-01 : ponytail debt markers
# ------------------------------------------------------------------------------
PONYTAIL_MARKER = re.compile(r"(?:^|[^A-Za-z])(?://|#|--|/\*|///|<!--)[^\n]*ponytail:")


def scan_debt_markers(files):
    for rel in files:
        for index, line in enumerate(read_lines(rel)):
            if PONYTAIL_MARKER.search(line):
                position = line.index("ponytail:") + len("ponytail:")
                reason = line[position:].strip()
                sys.stdout.write("PT-01 %s:%s \u2014 %s\n" % (rel, index + 1, reason))


def run_ponytail_debt():
    scan_debt_markers(all_source_files())


NARRATION_COMMENT = re.compile(
    r"^\s*#\s*(increment|decrement|set|assign|call|return|loop|iterate|initialize|create|check|store)\b"
)
SINGLE_STATEMENT_DELEGATION = re.compile(
    r"^\s*def\s+\w+\([^)]*\)\s*:\s*return\s+[\w.]+\([^)]*\)\s*$"
)


def run_ponytail_audit():
    scan_debt_markers(all_source_files())
    for rel in production_files():
        for index, line in enumerate(read_lines(rel)):
            if NARRATION_COMMENT.match(line):
                sys.stdout.write(
                    "[advisory] [DELETE] %s:%s \u2014 narration comment restates the next line\n"
                    % (rel, index + 1)
                )
            if SINGLE_STATEMENT_DELEGATION.match(line):
                sys.stdout.write(
                    "[advisory] [SHRINK] %s:%s \u2014 single-statement delegation; verify a caller justifies the layer\n"
                    % (rel, index + 1)
                )


# ------------------------------------------------------------------------------
# SK-01 .. SK-06 : skill activation invariants
# ------------------------------------------------------------------------------
def skill_dir(skill):
    return ".agents/skills/%s" % skill


def skill_file(skill):
    return "%s/SKILL.md" % skill_dir(skill)


def frontmatter_block(skill):
    lines = read_lines(skill_file(skill))
    if not lines or lines[0].strip() != "---":
        return None
    for index in range(1, len(lines)):
        if lines[index].strip() == "---":
            return lines[1:index]
    return None


def frontmatter_value(skill, key):
    block = frontmatter_block(skill)
    if block is None:
        return ""
    index = 0
    while index < len(block):
        match = re.match(r"^([A-Za-z][A-Za-z0-9_-]*):\s*(.*)$", block[index])
        if match and match.group(1) == key:
            raw = match.group(2).strip()
            if raw in ("", ">", ">-", ">+", "|", "|-", "|+"):
                parts = []
                cursor = index + 1
                while cursor < len(block) and (
                    not block[cursor].strip() or block[cursor][:1] in (" ", "\t")
                ):
                    if block[cursor].strip():
                        parts.append(block[cursor].strip())
                    cursor += 1
                return " ".join(parts)
            return raw
        index += 1
    return ""


def frontmatter_keys(skill):
    block = frontmatter_block(skill)
    if block is None:
        return []
    keys = []
    for line in block:
        match = re.match(r"^([A-Za-z][A-Za-z0-9_-]*):", line)
        if match:
            keys.append(match.group(1))
    return keys


def body_contains(rel, needle):
    return any(needle in line for line in read_lines(rel))


SK02_MESSAGE = (
    'skill "%s" frontmatter must declare "Use when", "Triggers on:" and "Chains into:" '
    "with >=150 characters and name==directory"
)


def audit_skills_parity():
    for skill in SKILLS:
        if not os.path.isfile(skill_file(skill)):
            emit_skill("SK-01", skill_dir(skill), 0, 'skill "%s" is not listed in .agents/skills (parity required)' % skill)
            continue
        if os.path.isfile(AGENTS_FILE) and ("`%s`" % skill) not in "".join(read_lines(AGENTS_FILE)):
            emit_skill("SK-01", AGENTS_FILE, 0, 'skill "%s" is not listed in AGENTS.md (parity required)' % skill)
        if os.path.isfile("README.md") and skill not in "".join(read_lines("README.md")):
            emit_skill("SK-01", "README.md", 0, 'skill "%s" is not listed in README.md (parity required)' % skill)


def audit_skills_frontmatter():
    allowed_keys = {"name", "description", "argument-hint", "license", "metadata"}
    for skill in SKILLS:
        rel = skill_file(skill)
        if not os.path.isfile(rel):
            continue
        if is_adoption() and user_owned_skill(skill):
            continue
        description = frontmatter_value(skill, "description")
        invalid = (
            not description
            or "Use when" not in description
            or "Triggers on:" not in description
            or "Chains into:" not in description
            or len(description) < 150
        )
        if invalid:
            emit_skill("SK-02", rel, 0, SK02_MESSAGE % skill)
            continue
        if frontmatter_value(skill, "name") != skill:
            emit_skill("SK-02", rel, 0, SK02_MESSAGE % skill)
            continue
        unknown = [key for key in frontmatter_keys(skill) if key not in allowed_keys]
        if unknown:
            emit_skill("SK-02", rel, 0, SK02_MESSAGE % skill)
            continue
        if not body_contains(rel, "## Territory") or not body_contains(rel, "## Repository Conformance Gate"):
            emit_skill("SK-02", rel, 0, SK02_MESSAGE % skill)


def audit_entrypoint_parity():
    llms_text = "".join(read_lines(LLMS_FILE))
    for skill in SKILLS:
        if os.path.isfile(LLMS_FILE) and skill not in llms_text:
            emit_skill("SK-03", LLMS_FILE, 0, 'skill "%s" is not listed in llms.txt' % skill)
    for entry in ("README.md", "docs/INDEX.md", "docs/MANIFESTO.md"):
        if not os.path.isfile(entry):
            continue
        if "llms.txt" not in "".join(read_lines(entry)):
            emit_skill("SK-03", entry, 0, "entrypoint %s does not reference llms.txt" % entry)


def matrix_rows():
    rows = {}
    inside = False
    for line in read_lines(AGENTS_FILE):
        if re.match(r"^### 3\.3", line):
            inside = True
            continue
        if inside and line.startswith("#"):
            inside = False
            continue
        if inside and line.startswith("|"):
            cells = line.split("|")
            if len(cells) < 7:
                continue
            primary = re.sub(r"[\s`]", "", cells[4])
            if not re.match(r"^[a-z][a-z0-9-]*$", primary):
                continue
            triggers = re.findall(r'"([^"]+)"', cells[3])
            rows.setdefault(primary, triggers)
    return rows


def audit_trigger_coherence():
    rows = matrix_rows()
    for skill in SKILLS:
        if skill not in rows:
            emit_skill("SK-04", AGENTS_FILE, 0, 'skill "%s" has no dispatch-matrix row' % skill)
            continue
        if is_adoption() and user_owned_skill(skill):
            continue
        description = frontmatter_value(skill, "description").lower()
        for trigger in rows[skill]:
            if trigger.lower() not in description:
                emit_skill(
                    "SK-04",
                    AGENTS_FILE,
                    0,
                    'trigger "%s" for skill "%s" is missing from its frontmatter "Triggers on:"'
                    % (trigger, skill),
                )


def same_bytes(first, second):
    try:
        with open(first, "rb") as handle_a, open(second, "rb") as handle_b:
            return handle_a.read() == handle_b.read()
    except OSError:
        return False


def mirror_of(directory, skill):
    if not (os.path.exists(directory) or os.path.islink(directory)):
        return None
    nested = os.path.join(directory, skill)
    if os.path.isdir(nested):
        candidate = os.path.join(nested, "SKILL.md")
        return candidate if os.path.isfile(candidate) else None
    for suffix in (".md", ".mdc"):
        candidate = os.path.join(directory, skill + suffix)
        if os.path.isfile(candidate):
            return candidate
    return None


def audit_mirror_parity():
    for directory in MIRROR_DIRS:
        if not (os.path.exists(directory) or os.path.islink(directory)):
            continue
        for skill in SKILLS:
            canonical = skill_file(skill)
            if not os.path.isfile(canonical):
                continue
            mirror = mirror_of(directory, skill)
            if mirror and same_bytes(canonical, mirror):
                continue
            emit_skill(
                "SK-05",
                directory,
                0,
                'harness mirror "%s" diverges from .agents/skills for skill "%s" '
                "(run: oaef skills sync-mirrors)" % (directory, skill),
            )


# --- routing ------------------------------------------------------------------
def candidate_forms(token):
    forms = [token]
    if token.endswith("ies"):
        forms.append(token[:-3] + "y")
    if token.endswith("es"):
        forms.append(token[:-2])
    if token.endswith("s"):
        forms.append(token[:-1])
    if token.endswith("ing"):
        forms.append(token[:-3])
    if token.endswith("ed"):
        forms.append(token[:-2])
    if token.endswith("ion"):
        forms.append(token[:-3])
    return forms


def common_prefix(left, right):
    limit = min(len(left), len(right))
    for position in range(limit):
        if left[position] != right[position]:
            return position
    return limit


def word_match(token, word):
    if not word:
        return False
    for candidate in candidate_forms(token):
        if candidate == word:
            return True
        if len(candidate) >= 4 and common_prefix(candidate, word) >= 4:
            return True
    return False


TERRITORY_VOCABULARY = {
    "features", "screens", "pages", "components", "shared", "ui", "core",
    "domain", "data", "infra", "test", "tests",
}


def route_prompt(prompt):
    lowered = prompt.lower()
    tokens = [token for token in re.split(r"[^a-z0-9-]+", lowered) if token]
    best = "ponytail"
    best_score = 0
    for skill in SKILLS:
        score = 0
        for word in skill.split("-"):
            for token in tokens:
                if word_match(token, word):
                    score += 5
                    break
        for trigger in TRIGGERS.get(skill, []):
            weight = min(len(trigger), 8)
            if " " in trigger:
                if trigger in lowered:
                    score += 3 + weight
            else:
                for token in tokens:
                    if word_match(token, trigger):
                        score += 3 + weight
                        break
        for token in tokens:
            if token in TERRITORY_VOCABULARY:
                score += 1
        if score > best_score:
            best_score = score
            best = skill
    return best if best_score > 0 else "ponytail"


def recipes_containing(skill):
    return [recipe for recipe in RECIPES if skill in recipe]


def run_skills_route(args):
    query = " ".join(args)
    primary = route_prompt(query)
    meta = "\u2014" if primary in META_SKILL else "ponytail"
    sys.stdout.write('Routing: "%s"\n' % query)
    sys.stdout.write("Primary skill: %s %s/SKILL.md\n" % (primary, skill_dir(primary)))
    sys.stdout.write("Meta-skill: %s\n" % meta)
    sys.stdout.write("Recipes containing %s:\n" % primary)
    for recipe in recipes_containing(primary):
        sys.stdout.write("  %s\n" % recipe)


def run_skills_selftest():
    for prompt, expected in ROUTING_FIXTURES:
        got = route_prompt(prompt)
        if got != expected:
            emit_skill(
                "SK-06",
                AGENTS_FILE,
                0,
                'routing self-test failed: prompt "%s" resolved to "%s" but expected "%s"'
                % (prompt, got, expected),
            )


def run_skills_audit(args):
    resolve_profile()
    audit_skills_parity()
    audit_skills_frontmatter()
    audit_entrypoint_parity()
    audit_trigger_coherence()
    audit_mirror_parity()
    if "--selftest" in args:
        run_skills_selftest()
    sys.stdout.write("Skills: %s finding(s)\n" % SK_FAILURES)
    if SK_FAILURES > 0:
        sys.exit(1)


def run_skills_sync_mirrors(args):
    global SK_FAILURES
    check_only = "--check" in args
    resolve_profile()
    repaired = 0
    for directory in MIRROR_DIRS:
        if not (os.path.exists(directory) or os.path.islink(directory)):
            continue
        if os.path.isdir(directory) and os.path.islink(directory) and \
                os.path.realpath(directory) == os.path.realpath(".agents/skills"):
            sys.stdout.write("✅ %s is a symlink to .agents/skills (parity by construction)\n" % directory)
            continue
        if not os.path.isdir(directory):
            continue
        for skill in SKILLS:
            canonical = skill_file(skill)
            if not os.path.isfile(canonical):
                continue
            entry = mirror_of(directory, skill)
            if entry:
                if not check_only and not same_bytes(canonical, entry):
                    shutil.copyfile(canonical, entry)
                    sys.stdout.write(
                        "🔧 %s: repaired mirror for %s (canonical catalog is authoritative)\n" % (directory, skill)
                    )
                    repaired += 1
                continue
            if check_only:
                continue
            target = os.path.join(directory, skill)
            link_target = os.path.relpath(skill_dir(skill), directory)
            created = False
            try:
                os.symlink(link_target, target)
                created = os.path.exists(target)
            except OSError:
                created = False
            if created:
                sys.stdout.write("🔧 %s: created mirror link for %s\n" % (directory, skill))
            else:
                if os.path.islink(target) or os.path.exists(target):
                    try:
                        os.remove(target)
                    except OSError:
                        pass
                shutil.copytree(skill_dir(skill), target)
                sys.stdout.write("🔧 %s: created mirror copy for %s\n" % (directory, skill))
            repaired += 1
    SK_FAILURES = 0
    audit_mirror_parity()
    if check_only:
        if SK_FAILURES > 0:
            sys.stdout.write("Mirrors: %s divergence(s) detected\n" % SK_FAILURES)
            sys.exit(1)
        sys.stdout.write("Mirrors: parity verified\n")
        return
    if SK_FAILURES > 0:
        sys.stdout.write("Mirrors: %s divergence(s) remain (user-owned entries are preserved)\n" % SK_FAILURES)
        sys.exit(1)
    sys.stdout.write("Mirrors: %s entry(ies) synchronized, parity verified\n" % repaired)


# ------------------------------------------------------------------------------
# lint / doctor / quality gate / sync / metrics
# ------------------------------------------------------------------------------
def normalize_mirror_text(text):
    lines = [line for line in text.splitlines() if not line.startswith("<!--")]
    return re.sub(r"\s+", "", "".join(lines))


SECRET_PATTERNS = [
    re.compile(r"sk-[a-zA-Z0-9]{20,}"),
    re.compile(r"ghp_[a-zA-Z0-9]{20,}"),
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
]
SUPPRESSION_PATTERNS = [
    re.compile(r"#\s*noqa"),
    re.compile(r"#\s*type:\s*ignore"),
    re.compile(r"#\s*pylint:\s*disable"),
]
ALLOWED_DEPRECATION_TOKENS = ["W1505", "B005", "deprecated-method", "type: ignore[deprecated]"]
IGNORED_WALK_SEGMENTS = (".venv", "venv", ".git", "build", "__pycache__", ".claude", ".cursor",
                         ".windsurf", ".cline", ".grok", ".agents", ".oaef", "tool", "templates",
                         "examples", "node_modules", "dist")


def run_lint():
    resolve_profile()
    sys.stdout.write("🔍 Executing OAEF Integrity & Secret Audits...\n")
    failed = False

    if os.path.isfile(AGENTS_FILE) and os.path.isfile("CLAUDE.md"):
        if normalize_mirror_text("\n".join(read_lines(AGENTS_FILE))) != normalize_mirror_text("\n".join(read_lines("CLAUDE.md"))):
            sys.stderr.write('❌ [LINT] CLAUDE.md diverged from AGENTS.md. Run "oaef sync".\n')
            failed = True

    if os.path.isdir("docs"):
        for dirpath, _, filenames in os.walk("docs"):
            for name in filenames:
                path = os.path.join(dirpath, name)
                content = "\n".join(read_lines(path))
                for pattern in SECRET_PATTERNS:
                    if pattern.search(content):
                        sys.stderr.write("🚨 [SECURITY] Potential secret detected in %s!\n" % path)
                        failed = True

    for dirpath, dirnames, filenames in os.walk("."):
        dirnames[:] = [name for name in dirnames if name not in IGNORED_WALK_SEGMENTS]
        for name in filenames:
            if not name.endswith(".py") or name.startswith("test_"):
                continue
            if name.endswith("_pb2.py") or name.endswith("_pb2_grpc.py") or name.endswith(".generated.py"):
                continue
            path = os.path.join(dirpath, name)
            lines = read_lines(path)
            content = "\n".join(lines)
            if "# Generated by" in content or "# Code generated" in content:
                continue
            for line_index, line in enumerate(lines, start=1):
                for pattern in SUPPRESSION_PATTERNS:
                    if pattern.search(line):
                        if any(token in line for token in ALLOWED_DEPRECATION_TOKENS):
                            continue
                        sys.stderr.write("🚨 [LINT] Unallowed suppression in %s:%s: %s\n" % (path, line_index, line.strip()))
                        failed = True

    run_clean_code_report()
    audit_skills_parity()
    audit_skills_frontmatter()
    audit_entrypoint_parity()
    audit_trigger_coherence()
    audit_mirror_parity()
    run_skills_selftest()
    if SK_FAILURES > 0:
        failed = True

    if failed:
        sys.stderr.write("❌ LINT FAILED.\n")
        sys.exit(1)
    sys.stdout.write("✅ [LINT] All integrity and secret audits passed cleanly.\n")


def run_conform():
    global SK_FAILURES
    resolve_profile()
    sys.stdout.write("🩺 OAEF Conformance Audit (doctor)...\n")
    state = {"checks": 0, "passed": 0, "failed": False}

    def check(condition, label):
        state["checks"] += 1
        if condition:
            state["passed"] += 1
            sys.stdout.write("✅ %s\n" % label)
        else:
            sys.stderr.write("❌ %s\n" % label)
            state["failed"] = True

    required_files = [
        "AGENTS.md", "CLAUDE.md", "llms.txt", "oaef.context.json",
        "docs/INDEX.md", "docs/MANIFESTO.md", "docs/DESIGN.md", "docs/HARNESSES.md",
        "docs/standards/coding_patterns.md", "docs/standards/testing.md", "docs/standards/logging.md",
        "docs/standards/clean_code.md", "docs/standards/solid.md", "docs/standards/review.md",
        "docs/standards/analytics_and_telemetry.md", "docs/standards/governance_checks.md",
        "docs/wiki/metrics/baseline.json", "docs/wiki/memory/handoff.md", "docs/wiki/log.md",
        ".github/workflows/ci.yml", ".github/pull_request_template.md",
        ".gitignore", "CONTRIBUTING.md", "SECURITY.md",
    ]
    for entry in required_files:
        check(os.path.exists(entry), "%s present" % entry)

    for skill in SKILLS:
        check(os.path.isfile(skill_file(skill)), ".agents/skills/%s/SKILL.md present" % skill)

    check(any(os.path.exists(runtime) for runtime in ENGINE_FILES), "governance runtime present in tool/")

    if os.path.isfile(AGENTS_FILE) and os.path.isfile("CLAUDE.md"):
        agents_text = normalize_mirror_text("\n".join(read_lines(AGENTS_FILE)))
        claude_text = normalize_mirror_text("\n".join(read_lines("CLAUDE.md")))
        check(agents_text == claude_text, "CLAUDE.md mirror parity verified")
    else:
        check(False, "mirror parity not verifiable (missing AGENTS.md or CLAUDE.md)")

    placeholder_pattern = re.compile(r"\{\{PROJECT_NAME\}\}|\{\{TECH_STACK\}\}|\{\{STACK_SPECIFIC_RULES\}\}")
    placeholder_hits = False
    for candidate in ("AGENTS.md", "llms.txt"):
        if os.path.isfile(candidate):
            if placeholder_pattern.search("\n".join(read_lines(candidate))):
                placeholder_hits = True
    check(not placeholder_hits, "no unresolved template placeholders")

    SK_FAILURES = 0
    audit_mirror_parity()
    check(SK_FAILURES == 0, "harness skill mirror parity verified")

    SK_FAILURES = 0
    run_skills_selftest()
    check(SK_FAILURES == 0, "routing self-test (SK-06) passed")

    sys.stdout.write("\n📊 Conformance: %s/%s checks passed\n" % (state["passed"], state["checks"]))
    if state["failed"]:
        sys.exit(1)


def run_quality_gate(record=False):
    global CC_TOTAL
    resolve_profile()
    sys.stdout.write("\n🔍 Initiating OAEF Quality Gate Audit (Python)...\n")
    baseline = {}
    if os.path.exists(BASELINE_FILE):
        with open(BASELINE_FILE, "r", encoding="utf-8") as handle:
            baseline = json.load(handle).get("baseline", {})

    coverage_cfg = baseline.get("coverage", {})
    min_line = coverage_cfg.get("lines_min_percentage", 95.0)
    sizing_cfg = baseline.get("clean_sizing", {})
    max_file_lines = sizing_cfg.get("file_max_lines", 300)

    sys.stdout.write("ℹ️  Running pytest with coverage...\n")
    try:
        subprocess.run(["pytest", "--cov=.", "--cov-report=lcov"], check=True)
    except Exception:
        sys.stderr.write("❌ Tests failed.\n")
        sys.exit(1)

    lines_found = 0
    lines_hit = 0
    if os.path.exists("coverage.lcov"):
        with open("coverage.lcov", "r", encoding="utf-8", errors="ignore") as handle:
            for line in handle:
                if line.startswith("LF:"):
                    lines_found += int(line[3:].strip() or 0)
                elif line.startswith("LH:"):
                    lines_hit += int(line[3:].strip() or 0)

    line_percent = 100.0 if lines_found == 0 else (lines_hit / lines_found) * 100.0
    sys.stdout.write("📊 Line Coverage: %.1f%% (Floor: %s%%)\n" % (line_percent, min_line))

    oversized = 0
    for rel in production_files():
        count = len(read_lines(rel))
        if count > max_file_lines:
            oversized += 1
            sys.stderr.write("⚠️  Oversized file (%sL > %sL): %s\n" % (count, max_file_lines, rel))

    if line_percent < min_line or oversized > 0:
        sys.stderr.write("❌ Quality Gates Failed.\n")
        sys.exit(1)

    run_clean_code_report()
    behavior = "blocking" if cc_blocking("CC-01") else "advisory"
    sys.stdout.write("Clean Code: %s violation(s) (%s profile: %s)\n" % (CC_TOTAL, PROFILE, behavior))
    if PROFILE == "strict" and not is_adoption() and blocking_total() > 0:
        sys.stderr.write("❌ Quality Gate Failed: %s clean-code violation(s).\n" % CC_TOTAL)
        sys.exit(1)

    sys.stdout.write("\n🎉 Quality Gates PASSED!\n")
    if record and line_percent > min_line:
        coverage_cfg["lines_min_percentage"] = round(line_percent, 1)
        baseline["coverage"] = coverage_cfg
        with open(BASELINE_FILE, "w", encoding="utf-8") as handle:
            json.dump({"baseline": baseline}, handle, indent=2)
        sys.stdout.write("🔒 Monotonic Ratchet: Updated baseline floor to %.1f%%\n" % line_percent)


def run_sync():
    if not os.path.isfile(AGENTS_FILE):
        sys.stderr.write("AGENTS.md not found.\n")
        sys.exit(1)
    content = "\n".join(read_lines(AGENTS_FILE))
    with open("CLAUDE.md", "w", encoding="utf-8") as handle:
        handle.write(
            "<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->\n"
            "<!-- To modify rules, edit AGENTS.md and run 'oaef sync'. -->\n\n"
            + content
        )
    sys.stdout.write("✅ Synchronized AGENTS.md -> CLAUDE.md\n")


def run_metrics():
    if os.path.exists(BASELINE_FILE):
        with open(BASELINE_FILE, "r", encoding="utf-8") as handle:
            sys.stdout.write(handle.read())


def print_usage():
    sys.stdout.write(
        "OAEF Governance Tool (Python Engine)\n"
        "Usage: python3 tool/governance.py <command>\n"
        "Commands:\n"
        "  quality-gate|audit [--record] Quality Gate audit (coverage, sizing, clean code)\n"
        "  clean-code [--standard]       Governance barriers (docs/standards/governance_checks.md)\n"
        "  ponytail-debt                 Report every ponytail: debt marker (PT-01)\n"
        "  ponytail-audit                Advisory anti-slop audit\n"
        "  skills-audit [--selftest]     Skill activation invariants (SK-01..SK-06)\n"
        "  skills-route \"<query>\"        Resolve a prompt to its governing skill and recipe\n"
        "  skills-sync-mirrors [--check] Rebuild or validate the harness skill mirrors\n"
        "  lint                          Mirror parity, secrets, anti-suppression, clean code, skills\n"
        "  doctor|conform                Conformance audit\n"
        "  metrics                       Display baseline thresholds\n"
        "  sync                          Synchronize AGENTS.md to CLAUDE.md\n"
    )


def main():
    args = sys.argv[1:]
    command = args[0] if args else ""
    rest = args[1:]
    if command in ("quality-gate", "audit"):
        run_quality_gate(record=("--record" in rest or "--ratchet" in rest))
    elif command == "metrics":
        run_metrics()
    elif command == "lint":
        run_lint()
    elif command in ("conform", "doctor"):
        run_conform()
    elif command == "sync":
        run_sync()
    elif command in ("clean-code", "governance-check"):
        run_clean_code(rest)
    elif command == "ponytail-debt":
        run_ponytail_debt()
    elif command == "ponytail-audit":
        run_ponytail_audit()
    elif command == "skills-audit":
        run_skills_audit(rest)
    elif command == "skills-route":
        run_skills_route(rest)
    elif command == "skills-sync-mirrors":
        run_skills_sync_mirrors(rest)
    elif command == "ponytail":
        subcommand = rest[0] if rest else "debt"
        if subcommand == "audit":
            run_ponytail_audit()
        else:
            run_ponytail_debt()
    elif command == "skills":
        subcommand = rest[0] if rest else "audit"
        if subcommand == "sync-mirrors":
            run_skills_sync_mirrors(rest[1:])
        elif subcommand == "audit":
            run_skills_audit(rest[1:])
        elif subcommand == "route":
            run_skills_route(rest[1:])
        else:
            print_usage()
            sys.exit(1)
    else:
        print_usage()
        sys.exit(1)


if __name__ == "__main__":
    main()
