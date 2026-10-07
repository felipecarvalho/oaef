#!/usr/bin/env bash
# ==============================================================================
# OAEF Universal POSIX Governance Engine
# Implements docs/standards/governance_checks.md for the `universal` stack.
# Author: Felipe Carvalho | License: Apache 2.0
# ==============================================================================

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

# ------------------------------------------------------------------------------
# Canonical catalog (must stay byte-identical to AGENTS.md section 3)
# ------------------------------------------------------------------------------
SKILLS="ponytail nullable-types architecture-audit screen-builder component-author responsive-layout ui-preview fix-layout-issues test-generator collect-coverage run-static-analysis code-review conformance-audit"

skill_triggers() {
  case "$1" in
    ponytail) echo "new|refactor|add|simple|minimal|yagni|dead code|delete|remove" ;;
    screen-builder) echo "screen|page|feature|flow|view" ;;
    component-author) echo "component|widget|button|card|modal" ;;
    ui-preview) echo "preview|storybook|isolated render" ;;
    responsive-layout) echo "responsive|adaptive|breakpoint|tablet|foldable|viewport" ;;
    fix-layout-issues) echo "overflow|unbounded|layout|layout broken|render error" ;;
    test-generator) echo "test|coverage|mock|fixture" ;;
    collect-coverage) echo "coverage|lcov|jacoco|cobertura|branches" ;;
    run-static-analysis) echo "analyze|lint|typecheck|warnings" ;;
    nullable-types) echo "null|optional|nil|guard clause|defensive" ;;
    architecture-audit) echo "architecture|boundary|coupling|cycle" ;;
    conformance-audit) echo "conformance|doctor|parity|frontmatter" ;;
    code-review) echo "review|pr|checklist|pre-pr" ;;
    *) echo "" ;;
  esac
}

skill_meta() {
  case "$1" in
    ponytail|collect-coverage|run-static-analysis|conformance-audit) echo "—" ;;
    *) echo "ponytail" ;;
  esac
}

routing_fixtures() {
  printf '%s\n' \
    "create a new screen for the booking flow|screen-builder" \
    "build a reusable button component|component-author" \
    "the layout overflows on small screens|fix-layout-issues" \
    "add responsive breakpoints for tablet|responsive-layout" \
    "write unit tests for the payment service|test-generator" \
    "collect coverage and check the branch floor|collect-coverage" \
    "fix all analyzer warnings|run-static-analysis" \
    "this optional list parameter is always null|nullable-types" \
    "audit module boundaries and cyclic imports|architecture-audit" \
    "verify the repo conforms to the framework|conformance-audit" \
    "review my PR before I open it|code-review" \
    "remove the dead code and the 1-line use case|ponytail"
}

recipes_file() {
  printf '%s\n' \
    "1. Feature / Screen Construction: ponytail -> screen-builder + responsive-layout -> ui-preview -> test-generator -> collect-coverage -> run-static-analysis -> code-review" \
    "2. Reusable Component / Module Authoring: ponytail -> component-author -> ui-preview -> responsive-layout -> test-generator -> run-static-analysis" \
    "3. Bug Fix / Root-Cause Remediation: ponytail (root-cause caller grep) -> fix-layout-issues (UI) / nullable-types (logic) -> test-generator -> run-static-analysis" \
    "4. Domain, Data & Infrastructure: ponytail -> nullable-types -> test-generator -> collect-coverage -> run-static-analysis" \
    "5. Pre-Submission / Pull Request Cycle: collect-coverage -> run-static-analysis -> code-review"
}

recipes_containing() {
  local skill="$1"
  recipes_file | grep -F -- "$skill" || true
}

MIRROR_DIRS=".claude/skills .cursor/rules .windsurf/skills .cline/skills .grok/agents"

# ------------------------------------------------------------------------------
# Profile & adoption resolution
# ------------------------------------------------------------------------------
CONTEXT_FILE="oaef.context.json"
BASELINE_FILE="docs/wiki/metrics/baseline.json"
ADOPTION_LEDGER="docs/wiki/metrics/adoption.json"
PROFILE="strict"
ADOPTION_MODE="install"

json_value() { # json_value <key> <file>
  [ -f "$2" ] || return 0
  sed -n 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$2" | head -1
}

resolve_profile() {
  local context_profile
  context_profile="$(json_value strictness "$CONTEXT_FILE")"
  if [ -n "$context_profile" ]; then
    PROFILE="$context_profile"
  else
    context_profile="$(json_value profile "$BASELINE_FILE")"
    [ -n "$context_profile" ] && PROFILE="$context_profile"
  fi
  ADOPTION_MODE="$(json_value adoption_mode "$CONTEXT_FILE")"
  [ -n "$ADOPTION_MODE" ] || ADOPTION_MODE="install"
  # In adoption mode the effective profile is the adoption mode itself: the clean-code
  # summary then reports `legacy`/`upgrade` (spec section 2) and every CC-* stays
  # advisory, while `--standard` can still override the word for a single invocation.
  [ "$ADOPTION_MODE" != "install" ] && PROFILE="$ADOPTION_MODE"
}

is_adoption() { [ "$ADOPTION_MODE" != "install" ]; }

user_owned_skill() { # skills listed in the adoption ledger user_skills array
  [ -f "$ADOPTION_LEDGER" ] || return 1
  awk -v wanted="$1" '
    /"user_skills"/ { inside = 1; next }
    inside && /\]/ { exit }
    inside && index($0, "\"" wanted "\"") > 0 { found = 1; exit }
    END { exit(found ? 0 : 1) }
  ' "$ADOPTION_LEDGER"
}

cc_blocking() { # cc_blocking <check-id>
  [ "$1" = "CC-04" ] && return 0
  is_adoption && return 1
  [ "$PROFILE" = "strict" ] || return 1
  return 0
}

cc_threshold() { # cc_threshold <check-id> -> baseline max, default 0
  local key=""
  case "$1" in
    CC-01) key="max_single_letter_identifiers" ;;
    CC-02) key="max_cryptic_abbreviations" ;;
    CC-03) key="max_mutable_lazy_initializations" ;;
    CC-04) key="max_dummy_keys" ;;
    CC-05) key="max_raw_prints" ;;
    CC-06) key="max_silent_catches" ;;
    CC-07) key="max_service_locator_leaks" ;;
    CC-08) key="max_nullable_collections" ;;
    CC-09) key="max_unimplemented_placeholders" ;;
    CC-10) key="max_concrete_client_instantiations" ;;
    CC-11) key="max_silent_catches" ;;
    *) key="" ;;
  esac
  local value=""
  if [ -n "$key" ]; then
    value="$(sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*\([0-9][0-9.]*\).*/\1/p' "$BASELINE_FILE" 2>/dev/null | head -1)"
  fi
  [ -n "$value" ] && echo "$value" || echo "0"
}

# ------------------------------------------------------------------------------
# File discovery
# ------------------------------------------------------------------------------
EXCLUDED_SEGMENTS=" .git node_modules vendor build dist target obj tool docs templates examples coverage generated .oaef .github .agents .claude .cursor .windsurf .cline .grok bin .dart_tool .gradle .idea .venv venv __pycache__ "
TEST_SEGMENTS=" test tests __tests__ spec specs androidTest iosTest "

is_segment_listed() { # is_segment_listed <segment> <space-delimited list>
  case "$2" in *" $1 "*) return 0 ;; esac
  return 1
}

path_segments() { printf '%s' "${1//\// }"; }

is_excluded_path() {
  local segment
  for segment in $(path_segments "$1"); do
    is_segment_listed "$segment" "$EXCLUDED_SEGMENTS" && return 0
  done
  case "$(basename "$1")" in
    *.g.*|*_pb2.py|*_pb2_grpc.py|*.min.js|*.generated.*|*.freezed.*|*.designer.*) return 0 ;;
  esac
  return 1
}

is_test_path() {
  local segment
  for segment in $(path_segments "$1"); do
    is_segment_listed "$segment" "$TEST_SEGMENTS" && return 0
  done
  case "$(basename "$1")" in
    *_test.*|*.spec.*|*.test.*|test_*.py|*Tests.cs|*Test.kt) return 0 ;;
  esac
  return 1
}

is_source_file() {
  case "$1" in
    *.dart|*.ts|*.tsx|*.js|*.mjs|*.cjs|*.jsx|*.py|*.go|*.rs|*.kt|*.kts|*.swift|*.cs|*.sh|*.bash) return 0 ;;
  esac
  return 1
}

production_files() {
  find . -type f -print | sed 's|^\./||' | sort | while IFS= read -r candidate; do
    is_source_file "$candidate" || continue
    is_excluded_path "$candidate" && continue
    is_test_path "$candidate" && continue
    printf '%s\n' "$candidate"
  done
}

all_source_files() {
  find . -type f -print | sed 's|^\./||' | sort | while IFS= read -r candidate; do
    is_source_file "$candidate" || continue
    is_excluded_path "$candidate" && continue
    printf '%s\n' "$candidate"
  done
}

# ------------------------------------------------------------------------------
# Finding emission
# ------------------------------------------------------------------------------
CC_TOTAL=0
CC_01=0; CC_02=0; CC_03=0; CC_04=0; CC_05=0; CC_06=0; CC_07=0; CC_08=0; CC_09=0; CC_10=0; CC_11=0
SK_FAILURES=0

emit() { # emit <id> <path> <line> <message>
  printf '%s %s:%s — %s\n' "$1" "$2" "$3" "$4"
  case "$1" in
    CC-01) CC_01=$((CC_01 + 1)) ;;
    CC-02) CC_02=$((CC_02 + 1)) ;;
    CC-03) CC_03=$((CC_03 + 1)) ;;
    CC-04) CC_04=$((CC_04 + 1)) ;;
    CC-05) CC_05=$((CC_05 + 1)) ;;
    CC-06) CC_06=$((CC_06 + 1)) ;;
    CC-07) CC_07=$((CC_07 + 1)) ;;
    CC-08) CC_08=$((CC_08 + 1)) ;;
    CC-09) CC_09=$((CC_09 + 1)) ;;
    CC-10) CC_10=$((CC_10 + 1)) ;;
    CC-11) CC_11=$((CC_11 + 1)) ;;
  esac
  case "$1" in CC-*) CC_TOTAL=$((CC_TOTAL + 1)) ;; esac
}

emit_skill() { # emit_skill <id> <path> <line> <message>
  printf '%s %s:%s — %s\n' "$1" "$2" "$3" "$4"
  SK_FAILURES=$((SK_FAILURES + 1))
}

count_for() { # count_for <id>
  case "$1" in
    CC-01) echo "$CC_01" ;;
    CC-02) echo "$CC_02" ;;
    CC-03) echo "$CC_03" ;;
    CC-04) echo "$CC_04" ;;
    CC-05) echo "$CC_05" ;;
    CC-06) echo "$CC_06" ;;
    CC-07) echo "$CC_07" ;;
    CC-08) echo "$CC_08" ;;
    CC-09) echo "$CC_09" ;;
    CC-10) echo "$CC_10" ;;
    CC-11) echo "$CC_11" ;;
  esac
}

# ------------------------------------------------------------------------------
# CC-01 / CC-02 : identifier discipline
# ------------------------------------------------------------------------------
CRYPTIC="cb fn res req btn val tmp ctx el usr mgr idx cnt buf str num doc elem curr prev"

is_cryptic() {
  local lowered
  lowered="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case " $CRYPTIC " in *" $lowered "*) return 0 ;; esac
  return 1
}

check_identifier_discipline() {
  local file="$1"
  local lineno line name
  while IFS= read -r entry; do
    lineno="${entry%%:*}"
    line="${entry#*:}"
    case "$line" in \#*) continue ;; esac

    name="$(printf '%s' "$line" | sed -nE \
      -e 's/^[[:space:]]*(final|var|let|const|val|auto|local|def|func|fn|string|bool|int|double|float|List|Map|Set)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=.*/\2/p' \
      -e 's/.*[(,][[:space:]]*([A-Za-z][A-Za-z0-9_]*)[[:space:]]*[,):].*(=>|->|\{|:).*/\1/p' \
      -e 's/.*catch[[:space:]]*\([[:space:]]*[A-Za-z_.]*[[:space:]]*([A-Za-z][A-Za-z0-9_]*)[[:space:]]*\).*/\1/p' \
      -e 's/.*except[[:space:]]+[A-Za-z_.]+[[:space:]]+as[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\1/p' \
      -e 's/.*lambda[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*:.*/\1/p' \
      -e 's/^[[:space:]]*([a-z])[[:space:]]*[=:].*/\1/p' \
      -e 's/^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[^=].*/\1/p' | head -1)"

    [ -n "$name" ] || continue

    if [ "${#name}" -eq 1 ]; then
      case "$name" in
        _) continue ;;
        i|j)
          case "$line" in *for*) continue ;; esac
          ;;
      esac
      emit CC-01 "$file" "$lineno" "prohibited single-letter identifier \"$name\"; use a descriptive name"
    elif is_cryptic "$name"; then
      emit CC-02 "$file" "$lineno" "prohibited cryptic abbreviation \"$name\"; use the full identifier"
    fi
  done < <(grep -nE '[^[:space:]]' "$file" 2>/dev/null)
}

# ------------------------------------------------------------------------------
# CC-03 : mutable lazy initialization
# ------------------------------------------------------------------------------
check_lazy_init() {
  local file="$1"
  local lineno line
  while IFS= read -r entry; do
    lineno="${entry%%:*}"
    line="${entry#*:}"
    case "$line" in
      *'??='*)
        case "$line" in
          *client*|*Client*|*instance*|*Instance*|*service*|*Service*|*provider*|*Provider*)
            emit CC-03 "$file" "$lineno" "prohibited mutable lazy initialization; inject the dependency via constructor"
            ;;
        esac
        ;;
      *'= '*)
        case "$line" in
          *'x = x or'*|*'is None:'*) : ;;
        esac
        ;;
    esac
  done < <(grep -nE '\?\?=|=[[:space:]]*[A-Za-z_]' "$file" 2>/dev/null)
  return 0
}

# ------------------------------------------------------------------------------
# CC-04 : hardcoded placeholder / secret
# ------------------------------------------------------------------------------
check_secrets() {
  local file="$1"
  local lineno line
  while IFS= read -r entry; do
    lineno="${entry%%:*}"
    line="${entry#*:}"
    emit CC-04 "$file" "$lineno" "prohibited hardcoded placeholder/secret; source it from configuration/environment"
  done < <(grep -nE '(dummy_|changeme|TODO_KEY|(api[_-]?key|secret|password|token)[[:space:]]*[:=][[:space:]]*"[^"]*"|(api[_-]?key|secret|password|token)[[:space:]]*[:=][[:space:]]*'"''"')' "$file" 2>/dev/null | grep -vE '(api[_-]?key|secret|password|token)[[:space:]]*[:=][[:space:]]*("[^"]*\{[^"]*"|\$|process\.env|System\.getenv|os\.environ|env\[)')
}

# ------------------------------------------------------------------------------
# CC-05 : raw print / debug output
# ------------------------------------------------------------------------------
check_raw_prints() {
  local file="$1"
  local lineno line
  while IFS= read -r entry; do
    lineno="${entry%%:*}"
    line="${entry#*:}"
    case "$line" in \#!*) continue ;; esac
    emit CC-05 "$file" "$lineno" "prohibited raw print/debug output in production code; use the logging interface"
  done < <(grep -nE '(^|[^A-Za-z0-9_.])(print|println)\(|console\.(log|debug|warn)\(|fmt\.Print|println!|print!|dbg!|Console\.(Write|WriteLine|Error\.Write)|Debug\.WriteLine' "$file" 2>/dev/null)
}

# ------------------------------------------------------------------------------
# CC-06 : silent exception swallowing
# ------------------------------------------------------------------------------
check_silent_catches() {
  local file="$1"
  case "$file" in *.sh|*.bash) return 0 ;; esac
  # The awk pass only reports the 1-based line number of each empty handler; the shell
  # turns every line into a canonical CC-06 finding through `emit`, so the finding is
  # counted, summarised and gated exactly like every other CC-* check. `lineno` is
  # captured before any look-ahead `getline` so multi-line handlers keep their own line.
  while IFS= read -r lineno; do
    [ -n "$lineno" ] || continue
    emit CC-06 "$file" "$lineno" "prohibited silent exception swallowing; log with error+stack trace or rethrow"
  done < <(awk '
    function is_blank(text) { return text ~ /^[[:space:]]*$/ || text ~ /^[[:space:]]*(\/\/|#|\*)/ }
    {
      line = $0
      lineno = NR
      if (line ~ /catch/ && line ~ /\{[[:space:]]*\}[[:space:]]*$/) { print lineno; next }
      if (line ~ /catch[[:space:]]*(\([^)]*\))?[[:space:]]*\{[[:space:]]*$/) {
        emptied = 1
        for (lookahead = 1; lookahead <= 3; lookahead++) {
          if ((getline upcoming) <= 0) break
          if (is_blank(upcoming)) continue
          if (upcoming ~ /^[[:space:]]*\}/) break
          emptied = 0
          break
        }
        if (emptied) print lineno
        next
      }
      if (line ~ /except[^:]*:[[:space:]]*pass[[:space:]]*$/) { print lineno; next }
      if (line ~ /except[^:]*:[[:space:]]*$/) {
        if ((getline upcoming) > 0) {
          if (upcoming ~ /^[[:space:]]*pass[[:space:]]*$/) print lineno
        }
        next
      }
      if (line ~ /if[[:space:]]+let[[:space:]]+Err\(_\)/ && line ~ /\{[[:space:]]*\}[[:space:]]*$/) { print lineno; next }
      if (line ~ /Err\(_\)[[:space:]]*=>[[:space:]]*\{[[:space:]]*\}/) { print lineno; next }
      if (line ~ /if[[:space:]]+err[[:space:]]*!=[[:space:]]*nil[[:space:]]*\{[[:space:]]*\}[[:space:]]*$/) { print lineno; next }
      if (line ~ /if[[:space:]]+err[[:space:]]*!=[[:space:]]*nil[[:space:]]*\{[[:space:]]*$/) {
        emptied = 1
        for (lookahead = 1; lookahead <= 3; lookahead++) {
          if ((getline upcoming) <= 0) break
          if (is_blank(upcoming)) continue
          if (upcoming ~ /^[[:space:]]*\}/) break
          emptied = 0
          break
        }
        if (emptied) print lineno
        next
      }
      if (line ~ /^[[:space:]]*_[[:space:]]*=[[:space:]]*err[[:space:]]*;?[[:space:]]*$/) { print lineno; next }
      if (line ~ /\.ok\(\)[[:space:]]*;[[:space:]]*$/) { print lineno; next }
    }
  ' "$file" 2>/dev/null)
}

# ------------------------------------------------------------------------------
# CC-09 : unimplemented placeholder
# ------------------------------------------------------------------------------
check_unimplemented() {
  local file="$1"
  local lineno line
  case "$file" in *.md) return 0 ;; esac
  # The universal engine scans a polyglot tree, so the token set is the union of the
  # per-stack CC-09 tokens of docs/standards/governance_checks.md section 4 (dart, ts,
  # python, go, rust, kotlin, swift, dotnet). Comment-only mentions are not findings.
  local unimplemented="UnimplementedError\(|NotImplementedError|NotImplementedException\(|unimplemented!\(\)|todo!\(\)|TODO\(|panic\(\"not implemented\"|panic\(\"TODO\"|fatalError\(\"TODO|preconditionFailure\(|throw new Error\('Not implemented'"
  while IFS= read -r entry; do
    lineno="${entry%%:*}"
    line="${entry#*:}"
    emit CC-09 "$file" "$lineno" "prohibited unimplemented placeholder in production contract; implement the contract (LSP)"
  done < <(grep -nE "$unimplemented" "$file" 2>/dev/null \
    | grep -vE 'echo "not implemented"' \
    | grep -vE '^[[:space:]]*(//|#|\*)')
}

run_clean_code() {
  resolve_profile
  # `clean-code --standard` forces the advisory profile for this invocation only.
  case "${1:-}" in --standard) PROFILE="standard" ;; esac
  local file
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    check_identifier_discipline "$file"
    check_lazy_init "$file"
    check_secrets "$file"
    check_raw_prints "$file"
    check_silent_catches "$file"
    check_unimplemented "$file"
  done < <(production_files)

  local id count threshold blocking
  BLOCKING_TOTAL=0
  for id in CC-01 CC-02 CC-03 CC-04 CC-05 CC-06 CC-07 CC-08 CC-09 CC-10 CC-11; do
    count="$(count_for "$id")"
    [ "$count" -gt 0 ] 2>/dev/null || continue
    threshold="$(cc_threshold "$id")"
    if cc_blocking "$id" && [ "$count" -gt "${threshold:-0}" ] ; then
      BLOCKING_TOTAL=$((BLOCKING_TOTAL + count))
    fi
  done

  if cc_blocking CC-01; then CLEAN_CODE_BEHAVIOR="blocking"; else CLEAN_CODE_BEHAVIOR="advisory"; fi
  printf 'Clean Code: %s violation(s) (%s profile: %s)\n' "$CC_TOTAL" "$PROFILE" "$CLEAN_CODE_BEHAVIOR"
  if [ "$BLOCKING_TOTAL" -gt 0 ]; then
    exit 1
  fi
}

# ------------------------------------------------------------------------------
# PT-01 : ponytail debt markers
# ------------------------------------------------------------------------------
scan_debt_markers() {
  local file
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    grep -nE '(^|[^A-Za-z])(//|#|--|/\*|///|<!--)[^\n]*ponytail:' "$file" 2>/dev/null | while IFS= read -r match; do
      local lineno="${match%%:*}"
      local reason="${match#*:ponytail:}"
      reason="${reason#*ponytail:}"
      printf '%s %s:%s — %s\n' "PT-01" "$file" "$lineno" "$(printf '%s' "$reason" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    done
  done < <(all_source_files)
}

run_ponytail_debt() {
  scan_debt_markers
}

run_ponytail_audit() {
  local file
  scan_debt_markers
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    grep -nE '^[[:space:]]*(//|#)[[:space:]]*(increment|decrement|set|assign|call|return|loop|iterate|initialize|create|check|store)[[:space:]]' "$file" 2>/dev/null | while IFS= read -r match; do
      printf '[advisory] [DELETE] %s:%s — narration comment restates the next line\n' "$file" "${match%%:*}"
    done
    grep -nE '=>[[:space:]]*[A-Za-z_][A-Za-z0-9_.]*\([^)]*\)[;]?[[:space:]]*$|^[[:space:]]*\{[[:space:]]*return[[:space:]]+[A-Za-z_][A-Za-z0-9_.]*\([^)]*\);[[:space:]]*\}[[:space:]]*$' "$file" 2>/dev/null | while IFS= read -r match; do
      printf '[advisory] [SHRINK] %s:%s — single-statement delegation; verify a caller justifies the layer\n' "$file" "${match%%:*}"
    done
  done < <(production_files)
}

# ------------------------------------------------------------------------------
# SK-01 .. SK-06 : skill activation invariants
# ------------------------------------------------------------------------------
AGENTS_FILE="AGENTS.md"
LLMS_FILE="llms.txt"

skill_dir() { printf '.agents/skills/%s' "$1"; }

frontmatter_value() { # frontmatter_value <skill> <key>
  local skill_file
  skill_file="$(skill_dir "$1")/SKILL.md"
  [ -f "$skill_file" ] || return 0
  awk -v key="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    NR > 1 {
      if ($0 ~ ("^" key ":")) {
        value = substr($0, length(key) + 2)
        sub(/^[[:space:]]+/, "", value)
        collecting = 1
        next
      }
      if (collecting && $0 ~ /^[[:space:]]+/) {
        trimmed = $0
        sub(/^[[:space:]]+/, "", trimmed)
        if (value ~ /^[>|][-+]?$/ || value == "") value = trimmed
        else value = value " " trimmed
        next
      }
      if (collecting) collecting = 0
    }
    END {
      gsub(/[[:space:]]+$/, "", value)
      print value
    }
  ' "$skill_file"
}

frontmatter_keys() { # frontmatter_keys <skill> -> top-level keys
  local skill_file
  skill_file="$(skill_dir "$1")/SKILL.md"
  [ -f "$skill_file" ] || return 0
  awk '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    NR > 1 && $0 ~ /^[A-Za-z][A-Za-z0-9_-]*:/ { sub(/:.*/, ""); print }
  ' "$skill_file"
}

audit_skills_parity() {
  local skill missing=0
  for skill in $SKILLS; do
    if [ ! -f "$(skill_dir "$skill")/SKILL.md" ]; then
      emit_skill SK-01 ".agents/skills/$skill" 0 "skill \"$skill\" is not listed in .agents/skills (parity required)"
      missing=1
      continue
    fi
    if [ -f "$AGENTS_FILE" ] && ! grep -q "\`$skill\`" "$AGENTS_FILE"; then
      emit_skill SK-01 "$AGENTS_FILE" 0 "skill \"$skill\" is not listed in AGENTS.md (parity required)"
      missing=1
    fi
    if [ -f README.md ] && ! grep -q "$skill" README.md; then
      emit_skill SK-01 "README.md" 0 "skill \"$skill\" is not listed in README.md (parity required)"
      missing=1
    fi
  done
  return 0
}

audit_skills_frontmatter() {
  local skill description keys key allowed
  for skill in $SKILLS; do
    [ -f "$(skill_dir "$skill")/SKILL.md" ] || continue
    if is_adoption && user_owned_skill "$skill"; then continue; fi
    description="$(frontmatter_value "$skill" description)"
    if [ -z "$description" ] \
      || ! printf '%s' "$description" | grep -q "Use when" \
      || ! printf '%s' "$description" | grep -q "Triggers on:" \
      || ! printf '%s' "$description" | grep -q "Chains into:" \
      || [ "${#description}" -lt 150 ]; then
      emit_skill SK-02 "$(skill_dir "$skill")/SKILL.md" 0 "skill \"$skill\" frontmatter must declare \"Use when\", \"Triggers on:\" and \"Chains into:\" with >=150 characters and name==directory"
      continue
    fi
    local declared_name
    declared_name="$(frontmatter_value "$skill" name)"
    if [ "$declared_name" != "$skill" ]; then
      emit_skill SK-02 "$(skill_dir "$skill")/SKILL.md" 0 "skill \"$skill\" frontmatter must declare \"Use when\", \"Triggers on:\" and \"Chains into:\" with >=150 characters and name==directory"
      continue
    fi
    keys="$(frontmatter_keys "$skill")"
    while IFS= read -r key; do
      [ -n "$key" ] || continue
      allowed=0
      case "$key" in name|description|argument-hint|license|metadata) allowed=1 ;; esac
      if [ "$allowed" -eq 0 ]; then
        emit_skill SK-02 "$(skill_dir "$skill")/SKILL.md" 0 "skill \"$skill\" frontmatter must declare \"Use when\", \"Triggers on:\" and \"Chains into:\" with >=150 characters and name==directory"
      fi
    done <<EOF
$keys
EOF
    grep -q '^## Territory' "$(skill_dir "$skill")/SKILL.md" 2>/dev/null || emit_skill SK-02 "$(skill_dir "$skill")/SKILL.md" 0 "skill \"$skill\" frontmatter must declare \"Use when\", \"Triggers on:\" and \"Chains into:\" with >=150 characters and name==directory"
  done
  return 0
}

audit_entrypoint_parity() {
  local skill entry
  for skill in $SKILLS; do
    if [ -f "$LLMS_FILE" ] && ! grep -q "$skill" "$LLMS_FILE"; then
      emit_skill SK-03 "$LLMS_FILE" 0 "skill \"$skill\" is not listed in llms.txt"
    fi
  done
  for entry in README.md docs/INDEX.md docs/MANIFESTO.md; do
    [ -f "$entry" ] || continue
    grep -q "llms.txt" "$entry" || emit_skill SK-03 "$entry" 0 "entrypoint $entry does not reference llms.txt"
  done
  return 0
}

matrix_rows() { # prints "<skill>|<trigger>|<trigger>|..."
  [ -f "$AGENTS_FILE" ] || return 0
  awk '
    /^### 3\.3/ { inside = 1; next }
    inside && /^#/ { inside = 0 }
    inside && /^\|/ {
      count = split($0, cells, "|")
      if (count < 7) next
      triggers = cells[4]
      primary = cells[5]
      gsub(/[`[:space:]]/, "", primary)
      if (primary == "" || primary == "PrimarySkill") next
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", triggers)
      triggers = triggers "|"
      print primary "|" triggers
    }
  ' "$AGENTS_FILE"
}

audit_trigger_coherence() {
  local skill row trigger frontmatter scratch
  scratch="$(mktemp)"
  for skill in $SKILLS; do
    row="$(matrix_rows | grep "^$skill|" | head -1)"
    if [ -z "$row" ]; then
      emit_skill SK-04 "$AGENTS_FILE" 0 "skill \"$skill\" has no dispatch-matrix row"
      continue
    fi
    if is_adoption && user_owned_skill "$skill"; then continue; fi
    frontmatter="$(frontmatter_value "$skill" description | tr '[:upper:]' '[:lower:]')"
    # The Triggers cell is a comma-separated list of quoted keywords; every keyword is
    # checked on its own so SK-04 reports the exact missing trigger (spec section 4).
    printf '%s' "$row" | sed 's/^[^|]*|//; s/|$//' | tr ',' '\n' > "$scratch"
    while IFS= read -r trigger; do
      trigger="$(printf '%s' "$trigger" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^"//;s/"$//' | tr '[:upper:]' '[:lower:]')"
      [ -n "$trigger" ] || continue
      case "$frontmatter" in
        *"$trigger"*) : ;;
        *) emit_skill SK-04 "$AGENTS_FILE" 0 "trigger \"$trigger\" for skill \"$skill\" is missing from its frontmatter \"Triggers on:\"" ;;
      esac
    done < "$scratch"
  done
  rm -f "$scratch"
  return 0
}

mirror_present() { [ -e "$1" ] || [ -L "$1" ]; }

mirror_of() { # mirror_of <dir> <skill> ; prints the mirror file path when present
  local dir="$1" skill="$2"
  mirror_present "$dir" || return 1
  if [ -d "$dir/$skill" ]; then printf '%s/%s/SKILL.md' "$dir" "$skill"; return 0; fi
  if [ -f "$dir/$skill.md" ]; then printf '%s/%s.md' "$dir" "$skill"; return 0; fi
  if [ -f "$dir/$skill.mdc" ]; then printf '%s/%s.mdc' "$dir" "$skill"; return 0; fi
  return 1
}

audit_mirror_parity() {
  local dir skill mirror canonical
  for dir in $MIRROR_DIRS; do
    mirror_present "$dir" || continue
    for skill in $SKILLS; do
      canonical="$(skill_dir "$skill")/SKILL.md"
      [ -f "$canonical" ] || continue
      if ! mirror="$(mirror_of "$dir" "$skill")"; then
        emit_skill SK-05 "$dir" 0 "harness mirror \"$dir\" diverges from .agents/skills for skill \"$skill\" (run: oaef skills sync-mirrors)"
        continue
      fi
      cmp -s "$canonical" "$mirror" || emit_skill SK-05 "$dir" 0 "harness mirror \"$dir\" diverges from .agents/skills for skill \"$skill\" (run: oaef skills sync-mirrors)"
    done
  done
  return 0
}

# --- routing ------------------------------------------------------------------
# Single-process scorer: docs/standards/governance_checks.md section 7.1
route_prompt() {
  awk -v prompt="$(printf '%s' "$*" | tr '[:upper:]' '[:lower:]')" '
    BEGIN {
      skill_count = split("ponytail nullable-types architecture-audit screen-builder component-author responsive-layout ui-preview fix-layout-issues test-generator collect-coverage run-static-analysis code-review conformance-audit", SKILLS, " ")
      triggers["ponytail"] = "new|refactor|add|simple|minimal|yagni|dead code|delete|remove"
      triggers["screen-builder"] = "screen|page|feature|flow|view"
      triggers["component-author"] = "component|widget|button|card|modal"
      triggers["ui-preview"] = "preview|storybook|isolated render"
      triggers["responsive-layout"] = "responsive|adaptive|breakpoint|tablet|foldable|viewport"
      triggers["fix-layout-issues"] = "overflow|unbounded|layout|layout broken|render error"
      triggers["test-generator"] = "test|coverage|mock|fixture"
      triggers["collect-coverage"] = "coverage|lcov|jacoco|cobertura|branches"
      triggers["run-static-analysis"] = "analyze|lint|typecheck|warnings"
      triggers["nullable-types"] = "null|optional|nil|guard clause|defensive"
      triggers["architecture-audit"] = "architecture|boundary|coupling|cycle"
      triggers["conformance-audit"] = "conformance|doctor|parity|frontmatter"
      triggers["code-review"] = "review|pr|checklist|pre-pr"
      territory = " features screens pages components shared ui core domain data infra test tests "
      token_count = split(prompt, TOKENS, /[^a-z0-9-]+/)
      best = "ponytail"
      best_score = 0
      for (skill_index = 1; skill_index <= skill_count; skill_index++) {
        skill = SKILLS[skill_index]
        score = 0
        name_count = split(skill, NAME_WORDS, "-")
        for (name_index = 1; name_index <= name_count; name_index++) {
          for (token_index = 1; token_index <= token_count; token_index++) {
            if (TOKENS[token_index] == "") continue
            if (word_match(TOKENS[token_index], NAME_WORDS[name_index])) { score += 5; break }
          }
        }
        trigger_count = split(triggers[skill], TRIGGERS, "|")
        for (trigger_index = 1; trigger_index <= trigger_count; trigger_index++) {
          trigger = TRIGGERS[trigger_index]
          if (trigger == "") continue
          weight = length(trigger); if (weight > 8) weight = 8
          if (index(trigger, " ") > 0) {
            if (index(prompt, trigger) > 0) score += 3 + weight
          } else {
            for (token_index = 1; token_index <= token_count; token_index++) {
              if (TOKENS[token_index] == "") continue
              if (word_match(TOKENS[token_index], trigger)) { score += 3 + weight; break }
            }
          }
        }
        for (token_index = 1; token_index <= token_count; token_index++) {
          if (TOKENS[token_index] == "") continue
          if (index(territory, " " TOKENS[token_index] " ") > 0) score += 1
        }
        if (score > best_score) { best_score = score; best = skill }
      }
      if (best_score == 0) best = "ponytail"
      print best
    }
    function common_prefix(left, right,    position, limit) {
      limit = length(left) < length(right) ? length(left) : length(right)
      for (position = 1; position <= limit; position++) {
        if (substr(left, position, 1) != substr(right, position, 1)) return position - 1
      }
      return limit
    }
    function word_match(token, word,    count, position, candidate) {
      if (word == "") return 0
      count = candidate_forms(token, FORMS)
      for (position = 1; position <= count; position++) {
        candidate = FORMS[position]
        if (candidate == word) return 1
        if (length(candidate) >= 4 && common_prefix(candidate, word) >= 4) return 1
      }
      return 0
    }
    function candidate_forms(token, out,    count, trimmed) {
      count = 0
      out[++count] = token
      if (token ~ /ies$/) out[++count] = substr(token, 1, length(token) - 3) "y"
      if (token ~ /es$/) out[++count] = substr(token, 1, length(token) - 2)
      if (token ~ /s$/) out[++count] = substr(token, 1, length(token) - 1)
      if (token ~ /ing$/) out[++count] = substr(token, 1, length(token) - 3)
      if (token ~ /ed$/) out[++count] = substr(token, 1, length(token) - 2)
      if (token ~ /ion$/) out[++count] = substr(token, 1, length(token) - 3)
      return count
    }
  '
}

run_skills_route() {
  local query="$*"
  local primary meta
  primary="$(route_prompt "$query")"
  meta="$(skill_meta "$primary")"
  printf 'Routing: "%s"\n' "$query"
  printf 'Primary skill: %s %s/SKILL.md\n' "$primary" "$(skill_dir "$primary")"
  printf 'Meta-skill: %s\n' "$meta"
  printf 'Recipes containing %s:\n' "$primary"
  recipes_containing "$primary" | sed 's/^/  /'
}

run_skills_selftest() {
  local failed=0 row prompt expected got
  while IFS='|' read -r prompt expected; do
    [ -n "$prompt" ] || continue
    got="$(route_prompt "$prompt")"
    if [ "$got" != "$expected" ]; then
      emit_skill SK-06 "$AGENTS_FILE" 0 "routing self-test failed: prompt \"$prompt\" resolved to \"$got\" but expected \"$expected\""
      failed=1
    fi
  done <<EOF
$(routing_fixtures)
EOF
  return 0
}

run_skills_audit() {
  local selftest="no"
  case "${1:-}" in --selftest) selftest="yes" ;; esac
  resolve_profile
  audit_skills_parity
  audit_skills_frontmatter
  audit_entrypoint_parity
  audit_trigger_coherence
  audit_mirror_parity
  if [ "$selftest" = "yes" ]; then
    run_skills_selftest
  fi
  printf 'Skills: %s finding(s)\n' "$SK_FAILURES"
  [ "$SK_FAILURES" -gt 0 ] && exit 1
  return 0
}

run_skills_sync_mirrors() {
  local check_only="no"
  case "${1:-}" in --check) check_only="yes" ;; esac
  resolve_profile
  local dir skill target entry canonical repaired=0
  for dir in $MIRROR_DIRS; do
    mirror_present "$dir" || continue
    if [ -L "$dir" ] && [ "$(readlink "$dir")" = "../.agents/skills" ] && [ -d "$dir" ]; then
      printf '✅ %s is a symlink to .agents/skills (parity by construction)\n' "$dir"
      continue
    fi
    [ -d "$dir" ] || continue
    for skill in $SKILLS; do
      canonical="$(skill_dir "$skill")/SKILL.md"
      [ -f "$canonical" ] || continue
      if entry="$(mirror_of "$dir" "$skill")"; then
        if [ "$check_only" = "no" ] && ! cmp -s "$canonical" "$entry" 2>/dev/null; then
          cp "$canonical" "$entry"
          printf '🔧 %s: repaired mirror for %s (canonical catalog is authoritative)\n' "$dir" "$skill"
          repaired=$((repaired + 1))
        fi
        continue
      fi
      [ "$check_only" = "yes" ] && continue
      target="$dir/$skill"
      if ln -s "../.agents/skills/$skill" "$target" 2>/dev/null && [ -e "$target" ]; then
        printf '🔧 %s: created mirror link for %s\n' "$dir" "$skill"
      else
        rm -f "$target" 2>/dev/null || true
        cp -R "$(skill_dir "$skill")" "$target"
        printf '🔧 %s: created mirror copy for %s\n' "$dir" "$skill"
      fi
      repaired=$((repaired + 1))
    done
  done
  SK_FAILURES=0
  audit_mirror_parity
  if [ "$check_only" = "yes" ]; then
    if [ "$SK_FAILURES" -gt 0 ]; then
      printf 'Mirrors: %s divergence(s) detected\n' "$SK_FAILURES"
      exit 1
    fi
    printf 'Mirrors: parity verified\n'
    return 0
  fi
  if [ "$SK_FAILURES" -gt 0 ]; then
    printf 'Mirrors: %s divergence(s) remain (user-owned entries are preserved)\n' "$SK_FAILURES"
    exit 1
  fi
  printf 'Mirrors: %s entry(ies) synchronized, parity verified\n' "$repaired"
}

# ------------------------------------------------------------------------------
# lint / doctor / quality gate / sync / metrics
# ------------------------------------------------------------------------------
normalize_mirror() {
  grep -v '^<!--' "$1" 2>/dev/null | tr -d ' \t\r\n'
}

run_lint() {
  resolve_profile
  local failed=0
  if [ -f AGENTS.md ] && [ -f CLAUDE.md ]; then
    if [ "$(normalize_mirror AGENTS.md)" != "$(normalize_mirror CLAUDE.md)" ]; then
      printf '%s\n' '❌ [LINT] CLAUDE.md diverged from AGENTS.md. Run "oaef sync".' >&2
      failed=1
    fi
  fi

  if grep -r -E "(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)" docs/ 2>/dev/null; then
    printf '%s\n' '🚨 [SECURITY] Potential secret detected in docs/!' >&2
    failed=1
  fi

  local suppressions
  suppressions="$(grep -rn -E "(//[[:space:]]*ignore:|\/\*[[:space:]]*eslint-disable|//[[:space:]]*@ts-ignore|#[[:space:]]*noqa|#[[:space:]]*type:[[:space:]]*ignore|//nolint|#\[allow\(|@Suppress\(|//[[:space:]]*swiftlint:disable|#pragma warning disable)" \
    --exclude-dir=".git" --exclude-dir="node_modules" --exclude-dir="build" --exclude-dir="dist" \
    --exclude-dir="docs" --exclude-dir="tool" --exclude-dir="templates" --exclude-dir=".agents" \
    --exclude="*.md" . 2>/dev/null | grep -v -E "(deprecated_member_use|type=lint|SA1019|CS0618|CS0612|DEPRECATION|DeprecatedCallableAddReplaceWith|#\[allow\(deprecated\)|@typescript-eslint/no-deprecated|W1505|B005|deprecated-method|type:[[:space:]]*ignore\[deprecated\]|DO NOT EDIT|@generated|\.g\.)" || true)"
  if [ -n "$suppressions" ]; then
    printf '%s\n' '🚨 [LINT] Unallowed linter/compiler suppression comments detected:' >&2
    printf '%s\n' "$suppressions" >&2
    failed=1
  fi

  run_clean_code_report
  audit_skills_parity
  audit_skills_frontmatter
  audit_entrypoint_parity
  audit_trigger_coherence
  audit_mirror_parity
  run_skills_selftest
  [ "$SK_FAILURES" -gt 0 ] && failed=1

  [ "$failed" -ne 0 ] && { printf '%s\n' '❌ LINT FAILED.' >&2; exit 1; }
  printf '%s\n' '✅ [LINT] All integrity and secret audits passed cleanly.'
}

run_clean_code_report() { # advisory form used by lint/doctor
  local file
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    check_identifier_discipline "$file"
    check_lazy_init "$file"
    check_secrets "$file"
    check_raw_prints "$file"
    check_silent_catches "$file"
    check_unimplemented "$file"
  done < <(production_files)
}

run_conform() {
  resolve_profile
  local checks=0 passed=0 failed=0
  local required_files="AGENTS.md CLAUDE.md llms.txt oaef.context.json docs/INDEX.md docs/MANIFESTO.md docs/DESIGN.md docs/HARNESSES.md docs/standards/coding_patterns.md docs/standards/testing.md docs/standards/logging.md docs/standards/clean_code.md docs/standards/solid.md docs/standards/review.md docs/standards/analytics_and_telemetry.md docs/standards/governance_checks.md docs/wiki/metrics/baseline.json docs/wiki/memory/handoff.md docs/wiki/log.md .github/workflows/ci.yml .github/pull_request_template.md .gitignore CONTRIBUTING.md SECURITY.md"
  local entry
  printf '🩺 OAEF Conformance Audit (doctor)...\n'
  for entry in $required_files; do
    checks=$((checks + 1))
    if [ -e "$entry" ]; then
      passed=$((passed + 1))
      printf '✅ %s present\n' "$entry"
    else
      printf '❌ %s missing\n' "$entry" >&2
      failed=1
    fi
  done

  local skill
  for skill in $SKILLS; do
    checks=$((checks + 1))
    if [ -f "$(skill_dir "$skill")/SKILL.md" ]; then
      passed=$((passed + 1))
      printf '✅ .agents/skills/%s/SKILL.md present\n' "$skill"
    else
      printf '❌ .agents/skills/%s/SKILL.md missing\n' "$skill" >&2
      failed=1
    fi
  done

  checks=$((checks + 1))
  if [ -f AGENTS.md ] && [ -f CLAUDE.md ] && [ "$(normalize_mirror AGENTS.md)" = "$(normalize_mirror CLAUDE.md)" ]; then
    passed=$((passed + 1))
    printf '✅ CLAUDE.md mirror parity verified\n'
  else
    printf '❌ CLAUDE.md mirror parity failed (run oaef sync)\n' >&2
    failed=1
  fi

  checks=$((checks + 1))
  if grep -q "{{PROJECT_NAME}}\|{{TECH_STACK}}\|{{STACK_SPECIFIC_RULES}}" AGENTS.md llms.txt 2>/dev/null; then
    printf '❌ unresolved template placeholders found\n' >&2
    failed=1
  else
    passed=$((passed + 1))
    printf '✅ no unresolved template placeholders\n'
  fi

  # Harness mirror parity is a doctor prerequisite (spec section 8): a divergent mirror
  # means the canonical skills are not the ones the harness will load.
  SK_FAILURES=0
  audit_mirror_parity
  checks=$((checks + 1))
  if [ "$SK_FAILURES" -eq 0 ]; then
    passed=$((passed + 1))
    printf '✅ harness skill mirror parity verified\n'
  else
    printf '❌ harness skill mirror parity failed (run oaef skills sync-mirrors)\n' >&2
    failed=1
  fi

  SK_FAILURES=0
  run_skills_selftest
  checks=$((checks + 1))
  if [ "$SK_FAILURES" -eq 0 ]; then
    passed=$((passed + 1))
    printf '✅ routing self-test (SK-06) passed\n'
  else
    printf '❌ routing self-test (SK-06) failed\n' >&2
    failed=1
  fi

  printf '\n📊 Conformance: %s/%s checks passed\n' "$passed" "$checks"
  [ "$failed" -ne 0 ] && exit 1
  return 0
}

run_quality_gate() {
  resolve_profile
  printf '🔍 Initiating OAEF Quality Gate Audit (Universal)...\n'
  local oversized=0 file lines
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    lines="$(wc -l < "$file" | tr -d ' ')"
    if [ "$lines" -gt 300 ]; then
      printf '⚠️  Oversized file (%sL > 300L): %s\n' "$lines" "$file" >&2
      oversized=$((oversized + 1))
    fi
  done < <(production_files)
  if [ "$oversized" -gt 0 ]; then
    printf '❌ Quality Gate Failed: %s oversized files detected.\n' "$oversized" >&2
    exit 1
  fi

  run_clean_code_report
  if cc_blocking CC-01; then CLEAN_CODE_BEHAVIOR="blocking"; else CLEAN_CODE_BEHAVIOR="advisory"; fi
  printf 'Clean Code: %s violation(s) (%s profile: %s)\n' "$CC_TOTAL" "$PROFILE" "$CLEAN_CODE_BEHAVIOR"
  if [ "$PROFILE" = "strict" ] && ! is_adoption && [ "$CC_TOTAL" -gt 0 ]; then
    printf '❌ Quality Gate Failed: %s clean-code violation(s).\n' "$CC_TOTAL" >&2
    exit 1
  fi
  printf '🎉 Quality Gates PASSED!\n'
}

run_sync() {
  if [ -f AGENTS.md ]; then
    { printf '%s\n' "<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->" \
        "<!-- To modify rules, edit AGENTS.md and run \"oaef sync\". -->" ""; cat AGENTS.md; } > CLAUDE.md
    printf '✅ Synchronized AGENTS.md -> CLAUDE.md\n'
  fi
}

run_metrics() {
  [ -f "$BASELINE_FILE" ] && cat "$BASELINE_FILE"
}

usage() {
  cat <<'EOF'
OAEF Governance Tool (Universal POSIX Engine)
Usage: bash tool/governance.sh <command>
Commands:
  quality-gate|audit        Quality Gate audit (coverage, sizing, clean code)
  clean-code [--standard]   Governance barriers (docs/standards/governance_checks.md)
  ponytail-debt             Report every "// ponytail:" debt marker (PT-01)
  ponytail | ponytail-audit Advisory anti-slop audit
  ponytail <debt|audit>     Nested alias for the two commands above
  skills-audit [--selftest] Skill activation invariants (SK-01..SK-06)
  skills-route "<query>"    Resolve a prompt to its governing skill and recipe
  skills-sync-mirrors [--check] Rebuild or validate the harness skill mirrors
  skills sync-mirrors [--check] Nested alias for skills-sync-mirrors
  lint                      Mirror parity, secrets, anti-suppression, skills
  doctor|conform            Conformance audit
  metrics                   Display baseline thresholds
  sync                      Synchronize AGENTS.md to CLAUDE.md
EOF
}

COMMAND="${1:-}"
shift || true
case "$COMMAND" in
  quality-gate|audit) run_quality_gate ;;
  clean-code|governance-check) run_clean_code "${1:-}" ;;
  ponytail-debt) run_ponytail_debt ;;
  ponytail-audit) run_ponytail_audit ;;
  ponytail)
    case "${1:-audit}" in
      debt) run_ponytail_debt ;;
      audit) run_ponytail_audit ;;
      *) usage; exit 1 ;;
    esac
    ;;
  skills-audit) run_skills_audit "${1:-}" ;;
  skills-route) run_skills_route "$@" ;;
  skills-sync-mirrors) run_skills_sync_mirrors "${1:-}" ;;
  skills)
    case "${1:-}" in
      sync-mirrors) run_skills_sync_mirrors "${2:-}" ;;
      audit) run_skills_audit "${2:-}" ;;
      route) shift; run_skills_route "$@" ;;
      *) usage; exit 1 ;;
    esac
    ;;
  lint) run_lint ;;
  conform|doctor) run_conform ;;
  metrics) run_metrics ;;
  sync) run_sync ;;
  *) usage; exit 1 ;;
esac
