#!/usr/bin/env bash
# ==============================================================================
# OAEF Universal POSIX Governance Engine
# Author: Felipe Carvalho | License: Apache 2.0
# ==============================================================================

set -e

COMMAND="${1:-}"

case "$COMMAND" in
  quality-gate|audit)
    echo "🔍 Initiating OAEF Universal Quality Gate Audit..."
    BASELINE="docs/wiki/metrics/baseline.json"
    if [ -f "$BASELINE" ]; then
      echo "✅ Baseline loaded from $BASELINE"
    fi

    # Check Clean Sizing (Files > 300 lines)
    OVERSIZED=0
    while IFS= read -r file; do
      LINES=$(wc -l < "$file" | tr -d ' ')
      if [ "$LINES" -gt 300 ]; then
        echo "⚠️  Oversized file (${LINES}L > 300L): $file" >&2
        OVERSIZED=$((OVERSIZED + 1))
      fi
    done < <(find . -type f \( -name "*.dart" -o -name "*.ts" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.kt" -o -name "*.swift" -o -name "*.cs" \) ! -path "*/.*" ! -path "*/node_modules/*" ! -path "*/build/*" ! -path "*/dist/*")

    if [ "$OVERSIZED" -gt 0 ]; then
      echo "❌ Quality Gate Failed: $OVERSIZED oversized files detected." >&2
      exit 1
    fi
    echo "🎉 Quality Gates PASSED!"
    ;;

  metrics)
    if [ -f "docs/wiki/metrics/baseline.json" ]; then
      cat "docs/wiki/metrics/baseline.json"
    fi
    ;;

  lint)
    echo "🔍 Auditing OAEF Integrity & Secret Leaks..."
    FAILED=0

    # Mirror Parity
    if [ -f "AGENTS.md" ] && [ -f "CLAUDE.md" ]; then
      DIFF=$(diff -u <(grep -v "^<!--" AGENTS.md | tr -d '\r\n ') <(grep -v "^<!--" CLAUDE.md | tr -d '\r\n ') || true)
      if [ -n "$DIFF" ]; then
        echo "❌ [LINT] CLAUDE.md diverged from AGENTS.md. Run 'oaef sync'." >&2
        FAILED=1
      else
        echo "✅ [LINT] Mirror parity verified."
      fi
    fi

    # Secret Scanning
    if grep -r -E "(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)" docs/ 2>/dev/null; then
      echo "🚨 [SECURITY] Potential secret detected in docs/!" >&2
      FAILED=1
    fi

    # Anti-Suppression Scanner
    SUPPRESSIONS=$(grep -rn -E "(//[[:space:]]*ignore:|\/\*[[:space:]]*eslint-disable|//[[:space:]]*@ts-ignore|#[[:space:]]*noqa|#[[:space:]]*type:[[:space:]]*ignore|//nolint|#\[allow\(|@Suppress\(|//[[:space:]]*swiftlint:disable|#pragma warning disable)" \
      --exclude-dir=".git" \
      --exclude-dir="node_modules" \
      --exclude-dir="build" \
      --exclude-dir="dist" \
      --exclude-dir="docs" \
      --exclude-dir="tool" \
      --exclude-dir="templates" \
      --exclude="*.md" \
      . 2>/dev/null | grep -v -E "(deprecated_member_use|type=lint|SA1019|CS0618|CS0612|DEPRECATION|DeprecatedCallableAddReplaceWith|#\[allow\(deprecated\)|@typescript-eslint/no-deprecated|W1505|B005|deprecated-method|type:[[:space:]]*ignore\[deprecated\]|DO NOT EDIT|@generated|\.g\.)" || true)
    if [ -n "$SUPPRESSIONS" ]; then
      echo "🚨 [LINT] Unallowed linter/compiler suppression comments detected:" >&2
      echo "$SUPPRESSIONS" >&2
      FAILED=1
    fi

    if [ "$FAILED" -ne 0 ]; then
      exit 1
    fi
    echo "✅ [LINT] All audits passed cleanly."
    ;;

  sync)
    if [ -f "AGENTS.md" ]; then
      echo "<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->" > CLAUDE.md
      echo "<!-- To modify rules, edit AGENTS.md and run 'oaef sync'. -->" >> CLAUDE.md
      echo "" >> CLAUDE.md
      cat AGENTS.md >> CLAUDE.md
      echo "✅ Synchronized AGENTS.md -> CLAUDE.md"
    fi
    ;;

  *)
    echo "Usage: bash tool/governance.sh [quality-gate|metrics|lint|sync]"
    exit 1
    ;;
esac
