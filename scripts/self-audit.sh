#!/usr/bin/env bash
# ==============================================================================
# OAEF Framework Self-Audit
# Installs every supported stack into a temporary sandbox and verifies that the
# generated repository satisfies the OAEF v1.1.0 conformance checklist:
# structure, the 13 skills, the 8 standards, harness mirrors, the governance
# engine (executed when its interpreter is present, statically audited otherwise)
# and the adoption/upgrade path over the legacy fixture.
# Author & Creator: Felipe Carvalho | License: Apache License 2.0
# ==============================================================================

set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ALL_STACKS=(dart-flutter react-native expo typescript-web kotlin-multiplatform kotlin python go rust swift dotnet universal)
STACKS=("${ALL_STACKS[@]}")
RUN_STACKS="yes"
RUN_LEGACY_FIXTURE="no"

CATALOG_SKILLS="ponytail nullable-types architecture-audit screen-builder component-author responsive-layout ui-preview fix-layout-issues test-generator collect-coverage run-static-analysis code-review conformance-audit"
MIRROR_DIRS=".claude/skills .cursor/rules .windsurf/skills .cline/skills .grok/agents"
ENGINE_FILES="tool/governance.dart tool/governance.mjs tool/governance.py tool/governance.go tool/governance.rs tool/governance.main.kts tool/governance.swift tool/Governance.cs tool/governance.sh"
CANONICAL_MESSAGES=(
  "prohibited single-letter identifier"
  "prohibited cryptic abbreviation"
  "prohibited hardcoded placeholder/secret"
  "prohibited silent exception swallowing"
  "prohibited unimplemented placeholder"
  "harness mirror"
  "routing self-test failed"
  "ponytail:"
)

usage() {
  echo "OAEF Framework Self-Audit"
  echo "Usage: bash scripts/self-audit.sh [--stack <name|all>] [--legacy-fixture]"
  echo ""
  echo "Stacks: ${ALL_STACKS[*]}"
  echo "  --legacy-fixture   also exercise examples/legacy-sample (adopt + upgrade idempotence)"
  echo "  --fixture-only     exercise only the adoption/upgrade fixture"
  echo "  --stacks-only      exercise only the stack sandboxes"
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
    --legacy-fixture)
      RUN_LEGACY_FIXTURE="yes"
      shift
      ;;
    --stacks-only)
      RUN_STACKS="yes"
      RUN_LEGACY_FIXTURE="no"
      shift
      ;;
    --fixture-only)
      RUN_STACKS="no"
      RUN_LEGACY_FIXTURE="yes"
      shift
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
DEGRADED_STACKS=()

# ------------------------------------------------------------------------------
# Interpreter discovery (never installs anything; degrades to static auditing)
# ------------------------------------------------------------------------------

engine_path() {
  local project_dir="$1"
  local candidate
  for candidate in $ENGINE_FILES; do
    [ -f "$project_dir/$candidate" ] && { printf '%s\n' "$candidate"; return 0; }
  done
  return 1
}

native_engine_available() {
  case "$1" in
    universal) command -v bash >/dev/null 2>&1 ;;
    typescript-web|react-native|expo) command -v node >/dev/null 2>&1 ;;
    python) command -v python3 >/dev/null 2>&1 ;;
    go) command -v go >/dev/null 2>&1 ;;
    rust) command -v rustc >/dev/null 2>&1 ;;
    dart-flutter) command -v dart >/dev/null 2>&1 ;;
    kotlin|kotlin-multiplatform) command -v kotlinc >/dev/null 2>&1 ;;
    swift) command -v swift >/dev/null 2>&1 ;;
    dotnet) command -v dotnet >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

run_native() { # run_native <stack> <command...>
  local stack="$1"
  shift
  case "$stack" in
    universal) bash tool/governance.sh "$@" ;;
    typescript-web|react-native|expo) node tool/governance.mjs "$@" ;;
    python) python3 tool/governance.py "$@" ;;
    go) go run tool/governance.go "$@" ;;
    rust)
      mkdir -p .oaef
      rustc -O tool/governance.rs -o .oaef/governance-rust >/dev/null 2>&1 || return 1
      ./.oaef/governance-rust "$@"
      ;;
    dart-flutter) dart run tool/governance.dart "$@" ;;
    kotlin|kotlin-multiplatform) OAEF_GOVERNANCE_ARGS="$*" kotlinc -script tool/governance.main.kts ;;
    swift) swift tool/governance.swift "$@" ;;
    dotnet) dotnet run --project tool/Governance.csproj -- "$@" ;;
    *) return 1 ;;
  esac
}

# ------------------------------------------------------------------------------
# Structural conformance (interpreter independent)
# ------------------------------------------------------------------------------

structural_conformance() {
  local project_dir="$1"
  local failures=0
  local entry
  local required_files=(
    AGENTS.md CLAUDE.md llms.txt oaef.context.json
    docs/INDEX.md docs/MANIFESTO.md docs/DESIGN.md docs/HARNESSES.md
    docs/standards/coding_patterns.md docs/standards/testing.md docs/standards/logging.md
    docs/standards/clean_code.md docs/standards/solid.md docs/standards/review.md
    docs/standards/analytics_and_telemetry.md docs/standards/governance_checks.md
    docs/wiki/metrics/baseline.json docs/wiki/memory/handoff.md docs/wiki/log.md
    .github/workflows/ci.yml .github/pull_request_template.md
    .gitignore CONTRIBUTING.md SECURITY.md bin/oaef
  )

  for entry in "${required_files[@]}"; do
    if [ ! -e "$project_dir/$entry" ]; then
      echo "   ❌ missing: $entry"
      failures=$((failures + 1))
    fi
  done

  for entry in $CATALOG_SKILLS; do
    if [ ! -f "$project_dir/.agents/skills/$entry/SKILL.md" ]; then
      echo "   ❌ missing skill: $entry"
      failures=$((failures + 1))
    fi
  done

  local skill_count
  skill_count="$(find "$project_dir/.agents/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$skill_count" != "13" ]; then
    echo "   ❌ skill catalog size is $skill_count, expected 13"
    failures=$((failures + 1))
  fi

  local engine
  if ! engine="$(engine_path "$project_dir")"; then
    echo "   ❌ missing: tool/governance.* runtime"
    failures=$((failures + 1))
    engine=""
  fi

  if [ -n "$engine" ]; then
    for token in clean-code ponytail skills-audit skills-route sync-mirrors doctor; do
      if ! grep -q -- "$token" "$project_dir/$engine" 2>/dev/null; then
        echo "   ❌ $engine does not implement the '$token' subcommand"
        failures=$((failures + 1))
      fi
    done
    local message
    for message in "${CANONICAL_MESSAGES[@]}"; do
      if ! grep -q -- "$message" "$project_dir/$engine" 2>/dev/null; then
        echo "   ❌ $engine is missing the canonical message: $message"
        failures=$((failures + 1))
      fi
    done
  fi

  # Harness skill mirrors
  local mirror skill mirror_entry
  for mirror in $MIRROR_DIRS; do
    [ -e "$project_dir/$mirror" ] || [ -L "$project_dir/$mirror" ] || continue
    for skill in $CATALOG_SKILLS; do
      mirror_entry="$project_dir/$mirror/$skill/SKILL.md"
      if [ ! -e "$mirror_entry" ] && [ ! -e "$project_dir/$mirror/$skill.md" ]; then
        echo "   ❌ mirror $mirror does not expose $skill"
        failures=$((failures + 1))
        continue
      fi
      if [ -e "$mirror_entry" ] && ! cmp -s "$project_dir/.agents/skills/$skill/SKILL.md" "$mirror_entry"; then
        echo "   ❌ mirror $mirror diverges for $skill"
        failures=$((failures + 1))
      fi
    done
  done

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

  if ! grep -q '"version": "1.1.0"' "$project_dir/oaef.context.json" 2>/dev/null; then
    echo "   ❌ oaef.context.json does not declare version 1.1.0"
    failures=$((failures + 1))
  fi

  if ! grep -q '"clean_code"' "$project_dir/docs/wiki/metrics/baseline.json" 2>/dev/null; then
    echo "   ❌ baseline.json has no clean_code block"
    failures=$((failures + 1))
  fi

  if ! grep -q "governance_checks.md" "$project_dir/llms.txt" 2>/dev/null; then
    echo "   ❌ llms.txt does not reference the governance check catalog"
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

  if native_engine_available "$stack"; then
    local command
    for command in "doctor" "lint" "clean-code" "skills-audit --selftest"; do
      echo "   🩺 native: $command"
      if (cd "$sandbox" && run_native "$stack" $command) > "$sandbox/native.log" 2>&1; then
        tail -1 "$sandbox/native.log" | sed 's/^/   /'
      else
        echo "   ❌ native '$command' failed"
        tail -6 "$sandbox/native.log"
        stack_failures=$((stack_failures + 1))
      fi
    done
    echo "   🩺 native: clean-code --standard"
    if (cd "$sandbox" && run_native "$stack" clean-code --standard) >/dev/null 2>&1; then
      echo "   ✅ advisory profile exits 0"
    else
      echo "   ❌ advisory profile did not exit 0"
      stack_failures=$((stack_failures + 1))
    fi
  else
    echo "   🩺 static engine audit (interpreter unavailable — engine not executed)"
    DEGRADED_STACKS+=("$stack")
  fi

  structural_conformance "$sandbox"
  if [ "$LAST_CONFORMANCE_FAILURES" -gt 0 ]; then
    stack_failures=$((stack_failures + LAST_CONFORMANCE_FAILURES))
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

# ------------------------------------------------------------------------------
# Adoption / upgrade fixture
# ------------------------------------------------------------------------------

audit_legacy_fixture() {
  local fixture="$ROOT_DIR/examples/legacy-sample"
  local sandbox
  echo ""
  echo "═══ [legacy-fixture] adoption + upgrade over examples/legacy-sample"

  if [ ! -d "$fixture" ]; then
    echo "   ❌ fixture missing: examples/legacy-sample"
    TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
    FAILED_STACKS+=("legacy-fixture")
    return
  fi

  sandbox="$(mktemp -d)"
  cp -R "$fixture/." "$sandbox/"
  local failures=0

  if ! (cd "$sandbox" && "$ROOT_DIR/install.sh" --target . --stack auto --legacy --non-interactive) > "$sandbox/adopt.log" 2>&1; then
    echo "   ❌ adoption failed"
    tail -6 "$sandbox/adopt.log"
    failures=$((failures + 1))
  fi

  if grep -q "PROJECT-SPECIFIC-CONVENTIONS" "$sandbox/AGENTS.md" 2>/dev/null; then
    echo "   ✅ user content preserved in AGENTS.md"
  else
    echo "   ❌ user content lost in AGENTS.md"
    failures=$((failures + 1))
  fi

  if grep -q "oaef:section:skills-catalog" "$sandbox/AGENTS.md" 2>/dev/null \
    && grep -q "oaef:section:rule-4.19" "$sandbox/AGENTS.md" 2>/dev/null; then
    echo "   ✅ canonical sections merged into AGENTS.md"
  else
    echo "   ❌ canonical sections missing from AGENTS.md"
    failures=$((failures + 1))
  fi

  if [ -f "$sandbox/docs/wiki/memory/adoption.md" ] && [ -f "$sandbox/docs/wiki/metrics/adoption.json" ]; then
    echo "   ✅ adoption ledger generated"
  else
    echo "   ❌ adoption ledger missing"
    failures=$((failures + 1))
  fi

  if [ -f "$sandbox/.agents/skills/legacy-audit/SKILL.md" ] && [ ! -f "$sandbox/.agents/skills/legacy-audit/SKILL.md.oaef-new" ]; then
    echo "   ✅ user-owned skill preserved without a proposal"
  else
    echo "   ❌ user-owned skill was touched"
    failures=$((failures + 1))
  fi

  if grep -q '"user_skills"' "$sandbox/docs/wiki/metrics/adoption.json" 2>/dev/null; then
    echo "   ✅ user-owned skills recorded in the ledger"
  else
    echo "   ❌ user_skills not recorded in the ledger"
    failures=$((failures + 1))
  fi

  if (cd "$sandbox" && "$ROOT_DIR/install.sh" --target . --stack auto --upgrade --non-interactive) > "$sandbox/upgrade1.log" 2>&1; then
    cp "$sandbox/AGENTS.md" "$sandbox/agents-after-first-upgrade.md"
    if (cd "$sandbox" && "$ROOT_DIR/install.sh" --target . --stack auto --upgrade --non-interactive) > "$sandbox/upgrade2.log" 2>&1; then
      if diff -q "$sandbox/agents-after-first-upgrade.md" "$sandbox/AGENTS.md" >/dev/null 2>&1; then
        echo "   ✅ upgrade is idempotent"
      else
        echo "   ❌ upgrade is not idempotent"
        failures=$((failures + 1))
      fi
    else
      echo "   ❌ second upgrade failed"
      failures=$((failures + 1))
    fi
  else
    echo "   ❌ upgrade failed"
    failures=$((failures + 1))
  fi

  if grep -q "PROJECT-SPECIFIC-CONVENTIONS" "$sandbox/AGENTS.md" 2>/dev/null; then
    echo "   ✅ user content still present after upgrade"
  else
    echo "   ❌ user content lost during upgrade"
    failures=$((failures + 1))
  fi

  if (cd "$sandbox" && python3 tool/governance.py doctor) > "$sandbox/doctor.log" 2>&1; then
    tail -1 "$sandbox/doctor.log" | sed 's/^/   /'
    echo "   ✅ doctor passes on the adopted repository"
  else
    echo "   ❌ doctor failed on the adopted repository"
    tail -6 "$sandbox/doctor.log"
    failures=$((failures + 1))
  fi

  if [ "$failures" -eq 0 ]; then
    echo "   ✅ legacy fixture conformance verified"
  else
    echo "   ❌ legacy fixture: $failures failure(s)"
    TOTAL_FAILURES=$((TOTAL_FAILURES + failures))
    FAILED_STACKS+=("legacy-fixture")
  fi

  rm -rf "$sandbox"
}

if [ "$RUN_STACKS" = "yes" ]; then
  for stack in "${STACKS[@]}"; do
    audit_stack "$stack"
  done
fi

if [ "$RUN_LEGACY_FIXTURE" = "yes" ]; then
  audit_legacy_fixture
fi

echo ""
echo "══════════════════════════════════════════════════════════"
if [ "${#DEGRADED_STACKS[@]}" -gt 0 ]; then
  echo "ℹ️  static-only stacks (interpreter unavailable): ${DEGRADED_STACKS[*]}"
fi
if [ "$TOTAL_FAILURES" -eq 0 ]; then
  echo "✅ OAEF self-audit passed"
else
  echo "❌ OAEF self-audit failures (${TOTAL_FAILURES}): ${FAILED_STACKS[*]}"
  exit 1
fi
