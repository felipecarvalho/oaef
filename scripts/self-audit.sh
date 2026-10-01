#!/usr/bin/env bash
# ==============================================================================
# OAEF Framework Self-Audit
# Installs every supported stack into a temporary sandbox and verifies that the
# generated repository satisfies the OAEF conformance checklist (doctor + lint).
# Author & Creator: Felipe Carvalho | License: Apache License 2.0
# ==============================================================================

set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ALL_STACKS=(dart-flutter react-native expo typescript-web kotlin-multiplatform kotlin python go rust swift dotnet universal)
STACKS=("${ALL_STACKS[@]}")

usage() {
  echo "OAEF Framework Self-Audit"
  echo "Usage: bash scripts/self-audit.sh [--stack <name|all>]"
  echo ""
  echo "Stacks: ${ALL_STACKS[*]}"
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --stack)
      if [ "$2" = "all" ]; then
        STACKS=("${ALL_STACKS[@]}")
      else
        STACKS=("$2")
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown flag: $1"
      usage
      exit 1
      ;;
  esac
done

TOTAL_FAILURES=0
FAILED_STACKS=()
LAST_CONFORMANCE_FAILURES=0

native_doctor_available() {
  case "$1" in
    universal) return 0 ;;
    typescript-web|react-native|expo) command -v node >/dev/null 2>&1 ;;
    python) command -v python3 >/dev/null 2>&1 ;;
    go) command -v go >/dev/null 2>&1 ;;
    dart-flutter) command -v dart >/dev/null 2>&1 ;;
    kotlin|kotlin-multiplatform) command -v kotlinc >/dev/null 2>&1 ;;
    swift) command -v swift >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

run_native_doctor() {
  case "$1" in
    universal) bash tool/governance.sh doctor ;;
    typescript-web|react-native|expo) node tool/governance.mjs doctor ;;
    python) python3 tool/governance.py doctor ;;
    go) go run tool/governance.go doctor ;;
    dart-flutter) dart run tool/governance.dart doctor ;;
    kotlin|kotlin-multiplatform) kotlinc -script tool/governance.main.kts doctor ;;
    swift) swift tool/governance.swift doctor ;;
  esac
}

run_native_lint() {
  case "$1" in
    universal) bash tool/governance.sh lint ;;
    typescript-web|react-native|expo) node tool/governance.mjs lint ;;
    python) python3 tool/governance.py lint ;;
    go) go run tool/governance.go lint ;;
    dart-flutter) dart run tool/governance.dart lint ;;
    kotlin|kotlin-multiplatform) kotlinc -script tool/governance.main.kts lint ;;
    swift) swift tool/governance.swift lint ;;
  esac
}

bash_conformance() {
  local project_dir="$1"
  local failures=0
  local entry
  local required_files=(
    AGENTS.md CLAUDE.md llms.txt oaef.context.json
    docs/INDEX.md docs/MANIFESTO.md docs/DESIGN.md
    docs/standards/coding_patterns.md docs/standards/testing.md docs/standards/logging.md
    docs/wiki/metrics/baseline.json docs/wiki/memory/handoff.md docs/wiki/log.md
    docs/HARNESSES.md
    .github/workflows/ci.yml .github/pull_request_template.md
    .gitignore CONTRIBUTING.md SECURITY.md
  )
  local required_skills=(
    architecture-audit code-review collect-coverage component-author
    fix-layout-issues nullable-types run-static-analysis screen-builder
    test-generator ui-preview conformance-audit
  )

  for entry in "${required_files[@]}"; do
    if [ ! -e "$project_dir/$entry" ]; then
      echo "   ❌ missing: $entry"
      failures=$((failures + 1))
    fi
  done

  for entry in "${required_skills[@]}"; do
    if [ ! -f "$project_dir/.agents/skills/$entry/SKILL.md" ]; then
      echo "   ❌ missing skill: $entry"
      failures=$((failures + 1))
    fi
  done

  local runtime_found=0
  for entry in tool/governance.sh tool/governance.mjs tool/governance.py tool/governance.dart tool/governance.go tool/governance.rs tool/governance.main.kts tool/governance.swift tool/Governance.cs; do
    [ -f "$project_dir/$entry" ] && runtime_found=1
  done
  if [ "$runtime_found" -ne 1 ]; then
    echo "   ❌ missing: tool/governance.* runtime"
    failures=$((failures + 1))
  fi

  if [ -f "$project_dir/AGENTS.md" ] && [ -f "$project_dir/CLAUDE.md" ]; then
    if ! diff -q <(grep -v '^<!--' "$project_dir/AGENTS.md" | tr -d '\r\n ') <(grep -v '^<!--' "$project_dir/CLAUDE.md" | tr -d '\r\n ') >/dev/null 2>&1; then
      echo "   ❌ mirror parity: CLAUDE.md diverged from AGENTS.md"
      failures=$((failures + 1))
    fi
  else
    echo "   ❌ mirror parity not verifiable (missing AGENTS.md or CLAUDE.md)"
    failures=$((failures + 1))
  fi

  if grep -q "{{PROJECT_NAME}}\|{{TECH_STACK}}\|{{STACK_SPECIFIC_RULES}}" "$project_dir/AGENTS.md" "$project_dir/llms.txt" 2>/dev/null; then
    echo "   ❌ unresolved template placeholders in AGENTS.md/llms.txt"
    failures=$((failures + 1))
  fi

  LAST_CONFORMANCE_FAILURES=$failures
}

audit_stack() {
  local stack="$1"
  local sandbox
  sandbox="$(mktemp -d)"
  echo ""
  echo "═══ [$stack] installing into sandbox: $sandbox"

  if ! "$ROOT_DIR/install.sh" --target "$sandbox" --stack "$stack" --non-interactive > "$sandbox/install.log" 2>&1; then
    echo "   ❌ installer failed"
    tail -5 "$sandbox/install.log"
    TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
    FAILED_STACKS+=("$stack")
    rm -rf "$sandbox"
    return
  fi

  local stack_failures=0

  if native_doctor_available "$stack"; then
    echo "   🩺 native doctor"
    if (cd "$sandbox" && run_native_doctor "$stack") > "$sandbox/doctor.log" 2>&1; then
      tail -1 "$sandbox/doctor.log" | sed 's/^/   /'
    else
      echo "   ❌ native doctor failed"
      tail -5 "$sandbox/doctor.log"
      stack_failures=$((stack_failures + 1))
    fi
  else
    echo "   🩺 bash conformance fallback (interpreter unavailable)"
  fi

  bash_conformance "$sandbox"
  if [ "$LAST_CONFORMANCE_FAILURES" -gt 0 ]; then
    stack_failures=$((stack_failures + LAST_CONFORMANCE_FAILURES))
  fi

  if native_doctor_available "$stack"; then
    if ! (cd "$sandbox" && run_native_lint "$stack") > "$sandbox/lint.log" 2>&1; then
      echo "   ❌ native lint failed"
      tail -5 "$sandbox/lint.log"
      stack_failures=$((stack_failures + 1))
    fi
  fi

  if [ "$stack_failures" -eq 0 ]; then
    echo "   ✅ $stack conformance verified"
  else
    echo "   ❌ $stack: $stack_failures failure(s)"
    TOTAL_FAILURES=$((TOTAL_FAILURES + stack_failures))
    FAILED_STACKS+=("$stack")
  fi

  rm -rf "$sandbox"
}

for stack in "${STACKS[@]}"; do
  audit_stack "$stack"
done

echo ""
echo "══════════════════════════════════════════════════════════"
if [ "$TOTAL_FAILURES" -eq 0 ]; then
  echo "✅ OAEF self-audit passed for: ${STACKS[*]}"
else
  echo "❌ OAEF self-audit failures (${TOTAL_FAILURES}): ${FAILED_STACKS[*]}"
  exit 1
fi
