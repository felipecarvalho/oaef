#!/usr/bin/env bash
# ==============================================================================
# Open Agentic Engineering Framework (OAEF) - Unified Installer & Discovery
# Author & Creator: Felipe Carvalho
# License: Apache License 2.0
#
# Legacy-safe by default: existing files are NEVER overwritten. Content inside
# "<!-- oaef:section:* -->" markers is framework-owned and is replaced in place;
# everything outside the markers is user-owned and is preserved untouched.
# A file whose merge would be ambiguous is preserved and proposed as
# "<file>.oaef-new" for human review.
# ==============================================================================

set -e

# ANSI Color codes
BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

# Default configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(pwd)"
STACK="auto"
STRICTNESS="strict"
INSTALL_SKILLS="yes"
NON_INTERACTIVE="no"
PROJECT_NAME=""
PROJECT_DESC=""
DRY_RUN="no"
BACKUP="no"
FORCE="no"
COVERAGE_OVERRIDE=""
ADOPTION_MODE="install"
INSTALL_MIRRORS="yes"
ADOPT_REPORT="no"
RATCHET_CLEAN_CODE="no"
MIGRATE_FRONTMATTER="no"
MIRROR_STRATEGY="symlink"
FRAMEWORK_VERSION="$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "1.1.0")"

# Installation bookkeeping
INSTALLED_COUNT=0
UNCHANGED_COUNT=0
PRESERVED_FILES=()
CONFLICT_FILES=()
GENERATED_FILES=()
INSTALLED_PATHS=()
PROPOSAL_PATHS=()
BACKUP_ROOT=""
MERGED_FILES=()
MIGRATED_SKILLS=()
USER_SKILLS=()
PLAN_LINES=()
MIRROR_DIRS_CREATED=()
CONFLICT_SECTIONS=()
CLEAN_CODE_INVENTORY=""

# Parse command line flags
while [[ $# -gt 0 ]]; do
  case $1 in
    --target)
      TARGET_DIR="$2"
      shift 2
      ;;
    --stack)
      STACK="$2"
      shift 2
      ;;
    --strict)
      STRICTNESS="strict"
      shift
      ;;
    --standard)
      STRICTNESS="standard"
      shift
      ;;
    --legacy)
      STRICTNESS="legacy"
      ADOPTION_MODE="legacy"
      shift
      ;;
    --upgrade)
      ADOPTION_MODE="upgrade"
      shift
      ;;
    --no-mirrors)
      INSTALL_MIRRORS="no"
      shift
      ;;
    --adopt-report)
      ADOPT_REPORT="yes"
      shift
      ;;
    --ratchet-clean-code)
      RATCHET_CLEAN_CODE="yes"
      shift
      ;;
    --migrate-frontmatter)
      MIGRATE_FRONTMATTER="yes"
      shift
      ;;
    --coverage)
      COVERAGE_OVERRIDE="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="yes"
      shift
      ;;
    --backup)
      BACKUP="yes"
      shift
      ;;
    --force)
      FORCE="yes"
      shift
      ;;
    --no-skills)
      INSTALL_SKILLS="no"
      shift
      ;;
    --non-interactive)
      NON_INTERACTIVE="yes"
      shift
      ;;
    -h|--help)
      echo "OAEF Installer - Open Agentic Engineering Framework"
      echo "Usage: ./install.sh [options]"
      echo ""
      echo "Options:"
      echo "  --target <path>      Target directory to initialize (default: current directory)"
      echo "  --stack <name>       Explicit stack: dart-flutter, react-native, expo, typescript-web, kotlin-multiplatform, kotlin, python, go, rust, swift, dotnet, universal, auto"
      echo "  --strict             Enforce strict Quality Gates (95% lines / 90% branches)"
      echo "  --standard           Enforce standard Quality Gates (80% lines / 75% branches)"
      echo "  --legacy             Adopt OAEF into an existing repository: advisory barriers, adoption ledger,"
      echo "                       measured coverage locked as the Monotonic Ratchet floor"
      echo "  --upgrade            Upgrade an earlier OAEF installation in place (user-owned content preserved)"
      echo "  --no-mirrors         Do not create the harness skill mirrors (.claude/skills, .cursor/rules, ...)"
      echo "  --adopt-report       (Re)generate the Adoption Debt Ledger even outside adoption mode"
      echo "  --ratchet-clean-code Lock the measured clean-code counts as the new baseline floors (adoption only)"
      echo "  --migrate-frontmatter Rewrite framework-owned skill frontmatter to the v1.1.0 format in place"
      echo "  --coverage <pct>     Explicit measured line coverage for --legacy (overrides detection)"
      echo "  --dry-run            Report every action without writing anything"
      echo "  --backup             Back up existing files to .oaef/backup/<timestamp>/ before overwriting"
      echo "  --force              Overwrite conflicting files (default: keep existing, propose <file>.oaef-new)"
      echo "  --no-skills          Skip copying .agents/skills/"
      echo "  --non-interactive    Run without interactive prompts"
      exit 0
      ;;
    *)
      echo "Unknown flag: $1"
      exit 1
      ;;
  esac
done

# Ensure absolute target path
if [ -d "$TARGET_DIR" ]; then
  TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
elif [ "$DRY_RUN" = "no" ]; then
  mkdir -p "$TARGET_DIR"
  TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
fi

# Detect stack if set to auto
auto_detect_stack() {
  if [ -f "$TARGET_DIR/pubspec.yaml" ]; then
    echo "dart-flutter"
  elif [ -f "$TARGET_DIR/app.json" ] && grep -q '"expo"' "$TARGET_DIR/app.json" 2>/dev/null; then
    echo "expo"
  elif [ -f "$TARGET_DIR/package.json" ]; then
    if grep -q '"expo"' "$TARGET_DIR/package.json" 2>/dev/null; then
      echo "expo"
    elif grep -q '"react-native"' "$TARGET_DIR/package.json" 2>/dev/null; then
      echo "react-native"
    else
      echo "typescript-web"
    fi
  elif [ -f "$TARGET_DIR/pyproject.toml" ] || [ -f "$TARGET_DIR/requirements.txt" ]; then
    echo "python"
  elif [ -f "$TARGET_DIR/go.mod" ]; then
    echo "go"
  elif [ -f "$TARGET_DIR/Cargo.toml" ]; then
    echo "rust"
  elif [ -f "$TARGET_DIR/build.gradle.kts" ] && grep -q -E '(kotlin\("multiplatform"\)|id\("org\.jetbrains\.kotlin\.multiplatform"\))' "$TARGET_DIR/build.gradle.kts" 2>/dev/null; then
    echo "kotlin-multiplatform"
  elif [ -d "$TARGET_DIR/composeApp" ] || [ -d "$TARGET_DIR/shared/src/commonMain" ]; then
    echo "kotlin-multiplatform"
  elif [ -f "$TARGET_DIR/build.gradle" ] || [ -f "$TARGET_DIR/build.gradle.kts" ] || [ -f "$TARGET_DIR/pom.xml" ]; then
    echo "kotlin"
  elif [ -f "$TARGET_DIR/Package.swift" ] || compgen -G "$TARGET_DIR/*.xcodeproj" > /dev/null 2>&1; then
    echo "swift"
  elif compgen -G "$TARGET_DIR/*.csproj" > /dev/null 2>&1 || compgen -G "$TARGET_DIR/*.sln" > /dev/null 2>&1; then
    echo "dotnet"
  else
    echo "universal"
  fi
}

DETECTED_STACK=$(auto_detect_stack)

# Interactive Mode
if [ "$NON_INTERACTIVE" != "yes" ] && [ -t 0 ]; then
  echo ""
  echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${BLUE}║        Open Agentic Engineering Framework (OAEF) - Setup Wizard         ║${RESET}"
  echo -e "${BOLD}${BLUE}║                  Created & Authored by Felipe Carvalho                   ║${RESET}"
  echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  # 1. Target Directory confirmation
  echo -e "${CYAN}[Step 1/5] Target Repository:${RESET} $TARGET_DIR"
  read -r -p "Install OAEF here? [Y/n]: " CONFIRM_DIR
  if [[ "$CONFIRM_DIR" =~ ^[Nn] ]]; then
    read -r -p "Enter target directory path: " NEW_TARGET
    mkdir -p "$NEW_TARGET"
    TARGET_DIR="$(cd "$NEW_TARGET" && pwd)"
  fi

  # 2. Project Identity
  AUTO_NAME="$(basename "$TARGET_DIR")"
  echo ""
  echo -e "${CYAN}[Step 2/5] Project Identity:${RESET}"
  read -r -p "Project Name [$AUTO_NAME]: " INPUT_NAME
  PROJECT_NAME="${INPUT_NAME:-$AUTO_NAME}"
  read -r -p "Brief Description / Purpose: " PROJECT_DESC

  # 3. Stack Selection
  echo ""
  echo -e "${CYAN}[Step 3/5] Technology Stack & Ecosystem:${RESET}"
  echo -e "Auto-detected stack: ${BOLD}${GREEN}$DETECTED_STACK${RESET}"
  echo "  1) Dart / Flutter"
  echo "  2) React Native (Fabric, TurboModules)"
  echo "  3) Expo (Expo Router, Managed Workflow)"
  echo "  4) TypeScript / JavaScript (Node, React, Next.js, Vue)"
  echo "  5) Kotlin Multiplatform (KMP & Compose Multiplatform)"
  echo "  6) Kotlin / Java (Android, Spring Boot)"
  echo "  7) Python (FastAPI, Django, AI/ML)"
  echo "  8) Go (Golang)"
  echo "  9) Rust"
  echo "  10) Swift (iOS, macOS)"
  echo "  11) C# / .NET"
  echo "  12) Universal / Polyglot / Custom"
  read -r -p "Select stack [1-12, Enter to keep auto-detected]: " STACK_CHOICE

  case $STACK_CHOICE in
    1) STACK="dart-flutter" ;;
    2) STACK="react-native" ;;
    3) STACK="expo" ;;
    4) STACK="typescript-web" ;;
    5) STACK="kotlin-multiplatform" ;;
    6) STACK="kotlin" ;;
    7) STACK="python" ;;
    8) STACK="go" ;;
    9) STACK="rust" ;;
    10) STACK="swift" ;;
    11) STACK="dotnet" ;;
    12) STACK="universal" ;;
    *) STACK="$DETECTED_STACK" ;;
  esac

  # 4. Strictness Level
  echo ""
  echo -e "${CYAN}[Step 4/5] Quality Gate Rigor Profile:${RESET}"
  echo "  1) Strict (Recommended) — 95% Lines, 90% Branches, Clean Sizing (<=300L arq / <=50L met), 0 Ignores"
  echo "  2) Standard — 80% Lines, 75% Branches, Clean Sizing (<=400L arq)"
  echo "  3) Legacy Onboarding — Ratchet rule (measures current coverage as floor, can only move up)"
  read -r -p "Select profile [1-3, Default: 1]: " RIGOR_CHOICE
  case $RIGOR_CHOICE in
    2) STRICTNESS="standard" ;;
    3) STRICTNESS="legacy" ;;
    *) STRICTNESS="strict" ;;
  esac

  # 5. Skills Installation
  echo ""
  echo -e "${CYAN}[Step 5/5] Stack-Adaptive Agent Skills:${RESET}"
  read -r -p "Install the 13 stack-tailored skills into .agents/skills/ (plus harness mirrors)? [Y/n]: " SKILLS_CHOICE
  if [[ "$SKILLS_CHOICE" =~ ^[Nn] ]]; then
    INSTALL_SKILLS="no"
  fi
else
  # Non-interactive fallback
  if [ "$STACK" = "auto" ]; then
    STACK="$DETECTED_STACK"
  fi
  if [ -z "$PROJECT_NAME" ]; then
    PROJECT_NAME="$(basename "$TARGET_DIR")"
  fi
fi

echo ""
echo -e "${BOLD}🚀 Applying OAEF with zero-pollution isolation for stack:${RESET} ${GREEN}$STACK${RESET}"

REPLACE_NAME="${PROJECT_NAME:-TargetProject}"

# ------------------------------------------------------------------------------
# Legacy-safe placement engine
# ------------------------------------------------------------------------------

hydrate_file() {
  local file="$1"
  sed -i '' "s/{{PROJECT_NAME}}/$REPLACE_NAME/g" "$file" 2>/dev/null || sed -i "s/{{PROJECT_NAME}}/$REPLACE_NAME/g" "$file" 2>/dev/null || true
  sed -i '' "s/{{TECH_STACK}}/$STACK/g" "$file" 2>/dev/null || sed -i "s/{{TECH_STACK}}/$STACK/g" "$file" 2>/dev/null || true
}

RULES_SOURCE="$SCRIPT_DIR/templates/rules/$STACK/rules.md"
if [ ! -f "$RULES_SOURCE" ]; then
  RULES_SOURCE="$SCRIPT_DIR/templates/rules/universal/rules.md"
fi

inject_stack_rules() {
  local file="$1"
  [ -f "$file" ] || return 0
  grep -q "{{STACK_SPECIFIC_RULES}}" "$file" || return 0
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
with open('$RULES_SOURCE', 'r', encoding='utf-8') as rules_file:
    rules = rules_file.read()
with open('$file', 'r', encoding='utf-8') as agents_file:
    agents = agents_file.read()
agents = agents.replace('{{STACK_SPECIFIC_RULES}}', rules)
with open('$file', 'w', encoding='utf-8') as agents_file:
    agents_file.write(agents)
"
  else
    awk -v r="$(cat "$RULES_SOURCE")" '{gsub(/\{\{STACK_SPECIFIC_RULES\}\}/, r)}1' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  fi
}

source_matches_existing() {
  local source_path="$1"
  local destination_path="$2"
  if cmp -s "$source_path" "$destination_path"; then
    return 0
  fi
  if grep -q "{{PROJECT_NAME}}\|{{TECH_STACK}}\|{{STACK_SPECIFIC_RULES}}" "$source_path" 2>/dev/null; then
    local hydrated_source
    hydrated_source="$(mktemp)"
    cp -p "$source_path" "$hydrated_source"
    hydrate_file "$hydrated_source"
    inject_stack_rules "$hydrated_source"
    if cmp -s "$hydrated_source" "$destination_path"; then
      rm -f "$hydrated_source"
      return 0
    fi
    rm -f "$hydrated_source"
  fi
  return 1
}

# ------------------------------------------------------------------------------
# Section-aware merge engine (see scripts/merge_markdown.py)
# ------------------------------------------------------------------------------

MERGE_TOOL="$SCRIPT_DIR/scripts/merge_markdown.py"
MERGE_AVAILABLE="no"
if command -v python3 >/dev/null 2>&1 && [ -f "$MERGE_TOOL" ]; then
  MERGE_AVAILABLE="yes"
fi

LAST_MERGE_CLASS=""

plan_record() { # plan_record <class> <relative-path>
  PLAN_LINES+=("$1|$2")
  if [ "$DRY_RUN" = "yes" ]; then
    echo -e "   ${CYAN}[dry-run]${RESET} $(printf '%-17s' "$1") $2"
  fi
}

hydrated_template() { # hydrated_template <source> -> hydrated temp path on stdout
  local source_path="$1"
  local temp_path
  temp_path="$(mktemp)"
  cp -p "$source_path" "$temp_path"
  hydrate_file "$temp_path"
  if grep -q "{{STACK_SPECIFIC_RULES}}" "$temp_path" 2>/dev/null; then
    inject_stack_rules "$temp_path"
  fi
  printf '%s\n' "$temp_path"
}

is_framework_owned_engine() {
  [ -f "$1" ] || return 1
  grep -q "OAEF Governance" "$1" 2>/dev/null
}

is_framework_owned_skill() {
  [ -f "$1" ] || return 1
  grep -q "^  framework: OAEF" "$1" 2>/dev/null && grep -q "OAEF" "$1" 2>/dev/null
}

is_framework_generated_markdown() {
  [ -f "$1" ] || return 1
  if grep -q "oaef:section:" "$1" 2>/dev/null; then return 0; fi
  if grep -q "Inviolable Trust Hierarchy" "$1" 2>/dev/null && grep -q "oaef " "$1" 2>/dev/null; then return 0; fi
  if grep -q "Open Agentic Engineering Framework (OAEF)" "$1" 2>/dev/null; then return 0; fi
  return 1
}

merge_markdown_file() { # merge_markdown_file <source> <destination> <relative> <apply yes|no>
  local source_path="$1" destination_path="$2" relative_path="$3" apply="$4"
  local hydrated merge_output merge_status classification conflicts
  LAST_MERGE_CLASS=""
  hydrated="$(hydrated_template "$source_path")"
  if [ "$apply" = "yes" ]; then
    merge_output="$(python3 "$MERGE_TOOL" --template "$hydrated" --destination "$destination_path" --apply 2>/dev/null)"
  else
    merge_output="$(python3 "$MERGE_TOOL" --template "$hydrated" --destination "$destination_path" --plan-only 2>/dev/null)"
  fi
  merge_status=$?
  rm -f "$hydrated"
  classification="$(printf '%s\n' "$merge_output" | sed -n 's/^CLASS //p' | head -1)"
  if [ "$merge_status" -eq 20 ] || [ -z "$classification" ]; then
    LAST_MERGE_CLASS="propose-oaef-new"
    return 20
  fi
  conflicts="$(printf '%s\n' "$merge_output" | sed -n 's/^CONFLICT //p' | tr '\n' ' ')"
  [ -n "$conflicts" ] && CONFLICT_SECTIONS+=("$relative_path: $conflicts")
  LAST_MERGE_CLASS="$classification"
  return 0
}

place_file() {
  local source_path="$1"
  local destination_path="$2"
  local relative_path="${destination_path#$TARGET_DIR/}"

  if [ ! -e "$destination_path" ]; then
    plan_record install "$relative_path"
    if [ "$DRY_RUN" = "no" ]; then
      mkdir -p "$(dirname "$destination_path")"
      cp -p "$source_path" "$destination_path"
      INSTALLED_PATHS+=("$destination_path")
    fi
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    return 0
  fi

  if source_matches_existing "$source_path" "$destination_path"; then
    UNCHANGED_COUNT=$((UNCHANGED_COUNT + 1))
    plan_record preserve "$relative_path"
    return 0
  fi

  if [ "$FORCE" = "yes" ]; then
    plan_record install "$relative_path (forced)"
    if [ "$DRY_RUN" = "no" ]; then
      backup_existing "$destination_path"
      cp -p "$source_path" "$destination_path"
      INSTALLED_PATHS+=("$destination_path")
    fi
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    return 0
  fi

  case "$relative_path" in
    tool/*)
      if is_framework_owned_engine "$destination_path"; then
        plan_record merge-additive "$relative_path"
        if [ "$DRY_RUN" = "no" ]; then
          backup_existing "$destination_path"
          cp -p "$source_path" "$destination_path"
          INSTALLED_PATHS+=("$destination_path")
          MERGED_FILES+=("$relative_path (framework runtime upgraded)")
        fi
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        return 0
      fi
      ;;
    .agents/skills/*)
      if is_framework_owned_skill "$destination_path"; then
        plan_record merge-additive "$relative_path"
        if [ "$DRY_RUN" = "no" ]; then
          backup_existing "$destination_path"
          cp -p "$source_path" "$destination_path"
          INSTALLED_PATHS+=("$destination_path")
        fi
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        MIGRATED_SKILLS+=("$relative_path")
        return 0
      fi
      plan_record propose-oaef-new "$relative_path"
      if [ "$DRY_RUN" = "no" ]; then
        cp -p "$source_path" "$destination_path.oaef-new"
        PROPOSAL_PATHS+=("$destination_path.oaef-new")
      fi
      USER_SKILLS+=("$relative_path")
      CONFLICT_FILES+=("$relative_path (user-owned skill preserved)")
      return 0
      ;;
  esac

  case "$relative_path" in
    *.md|llms.txt)
      if [ "$ADOPTION_MODE" = "upgrade" ] \
        && is_framework_generated_markdown "$destination_path" \
        && ! grep -q "oaef:section:" "$destination_path" 2>/dev/null; then
        plan_record merge-additive "$relative_path"
        if [ "$DRY_RUN" = "no" ]; then
          backup_existing "$destination_path"
          cp -p "$source_path" "$destination_path"
          INSTALLED_PATHS+=("$destination_path")
          MERGED_FILES+=("$relative_path (framework-generated file upgraded)")
        fi
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        return 0
      fi
      if [ "$MERGE_AVAILABLE" = "yes" ]; then
        if [ "$DRY_RUN" = "yes" ]; then
          merge_markdown_file "$source_path" "$destination_path" "$relative_path" "no" || true
        else
          merge_markdown_file "$source_path" "$destination_path" "$relative_path" "yes" || true
        fi
        case "$LAST_MERGE_CLASS" in
          unchanged)
            UNCHANGED_COUNT=$((UNCHANGED_COUNT + 1))
            plan_record preserve "$relative_path"
            return 0
            ;;
          merge-additive|merge-conflict)
            plan_record "$LAST_MERGE_CLASS" "$relative_path"
            if [ "$DRY_RUN" = "no" ]; then
              INSTALLED_PATHS+=("$destination_path")
              MERGED_FILES+=("$relative_path")
            fi
            INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
            [ "$LAST_MERGE_CLASS" = "merge-conflict" ] && CONFLICT_FILES+=("$relative_path (section merge: user content preserved)")
            return 0
            ;;
        esac
      fi
      ;;
  esac

  plan_record propose-oaef-new "$relative_path"
  if [ "$DRY_RUN" = "no" ]; then
    cp -p "$source_path" "$destination_path.oaef-new"
    PROPOSAL_PATHS+=("$destination_path.oaef-new")
    PRESERVED_FILES+=("$relative_path (preserved; canonical proposal written)")
  fi
  CONFLICT_FILES+=("$relative_path")
}

place_tree() {
  local source_root="$1"
  local destination_root="$2"
  local exclusions="${3:-}"
  [ -d "$source_root" ] || return 0
  while IFS= read -r -d '' source_file; do
    local relative_path="${source_file#$source_root/}"
    case " $exclusions " in
      *" $relative_path "*) continue ;;
    esac
    place_file "$source_file" "$destination_root/$relative_path"
  done < <(find "$source_root" -type f -print0)
}

backup_existing() {
  local path="$1"
  [ "$BACKUP" = "yes" ] || return 0
  local relative_path="${path#$TARGET_DIR/}"
  mkdir -p "$BACKUP_ROOT/$(dirname "$relative_path")"
  cp -p "$path" "$BACKUP_ROOT/$relative_path"
}

write_generated_file() {
  local destination_path="$1"
  local content="$2"
  local relative_path="${destination_path#$TARGET_DIR/}"

  if [ "$DRY_RUN" = "yes" ]; then
    echo -e "   ${CYAN}[dry-run]${RESET} would generate $relative_path"
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    return 0
  fi
  mkdir -p "$(dirname "$destination_path")"
  printf '%s\n' "$content" > "$destination_path"
  INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
  INSTALLED_PATHS+=("$destination_path")
  GENERATED_FILES+=("$relative_path")
}

# ------------------------------------------------------------------------------
# Harness skill mirrors (docs/HARNESSES.md) — keeps triggers alive in every harness
# ------------------------------------------------------------------------------

HARNESS_MIRROR_DIRS=".claude/skills .cursor/rules .windsurf/skills .cline/skills .grok/agents"

install_skill_mirrors() {
  [ "$INSTALL_MIRRORS" = "yes" ] || return 0
  [ "$INSTALL_SKILLS" = "yes" ] || return 0
  [ "$DRY_RUN" = "no" ] || return 0

  local mirror_relative mirror_dir skill target
  for mirror_relative in $HARNESS_MIRROR_DIRS; do
    mirror_dir="$TARGET_DIR/$mirror_relative"
    if [ -L "$mirror_dir" ]; then
      if [ "$(readlink "$mirror_dir")" = "../.agents/skills" ] && [ -d "$mirror_dir" ]; then
        MIRROR_DIRS_CREATED+=("$mirror_relative (symlink verified)")
      else
        MIRROR_DIRS_CREATED+=("$mirror_relative (existing entry preserved — verify with: oaef skills sync-mirrors --check)")
      fi
      continue
    fi
    if [ ! -e "$mirror_dir" ]; then
      mkdir -p "$(dirname "$mirror_dir")"
      if ln -s "../.agents/skills" "$mirror_dir" 2>/dev/null && [ -d "$mirror_dir" ]; then
        MIRROR_DIRS_CREATED+=("$mirror_relative (symlink)")
        continue
      fi
      rm -f "$mirror_dir" 2>/dev/null || true
      MIRROR_STRATEGY="copy"
      mkdir -p "$mirror_dir"
    fi
    [ -d "$mirror_dir" ] || continue
    for skill in $(list_catalog_skills); do
      target="$mirror_dir/$skill"
      [ -e "$target" ] || [ -L "$target" ] && continue
      if [ -d "$TARGET_DIR/.agents/skills/$skill" ]; then
        ln -s "../.agents/skills/$skill" "$target" 2>/dev/null && [ -e "$target" ] \
          || cp -R "$TARGET_DIR/.agents/skills/$skill" "$target"
      fi
    done
    MIRROR_DIRS_CREATED+=("$mirror_relative (per-skill entries)")
  done
}

note_gitignore() {
  local gitignore_path="$TARGET_DIR/.gitignore"
  [ -f "$gitignore_path" ] || return 0
  grep -q "OAEF agent skill mirrors" "$gitignore_path" 2>/dev/null && return 0
  [ "$DRY_RUN" = "no" ] || return 0
  {
    printf '\n'
    printf '# OAEF agent skill mirrors — the canonical catalog lives in .agents/skills/ (versioned once).\n'
    if [ "$MIRROR_STRATEGY" = "copy" ]; then
      for mirror_dir in $HARNESS_MIRROR_DIRS; do
        printf '%s/\n' "$mirror_dir"
      done
    fi
  } >> "$gitignore_path"
  PRESERVED_FILES+=(".gitignore (OAEF mirror section appended)")
}

list_catalog_skills() {
  printf '%s\n' "ponytail nullable-types architecture-audit screen-builder component-author responsive-layout ui-preview fix-layout-issues test-generator collect-coverage run-static-analysis code-review conformance-audit"
}

# ------------------------------------------------------------------------------
# JSON surgery (baseline & context) — python3 preferred, skipped when unavailable
# ------------------------------------------------------------------------------

json_merge_baseline() { # add the v1.1.0 keys without ever lowering an existing floor
  local baseline_path="$1"
  command -v python3 >/dev/null 2>&1 || return 0
  [ -f "$baseline_path" ] || return 0
  python3 - "$baseline_path" "$FRAMEWORK_VERSION" <<'PYEOF'
import json, sys
path, version = sys.argv[1], sys.argv[2]
with open(path, "r", encoding="utf-8") as handle:
    try:
        document = json.load(handle)
    except json.JSONDecodeError:
        sys.exit(0)
baseline = document.setdefault("baseline", {})
document["version"] = version
clean_code = baseline.setdefault("clean_code", {})
for key in (
    "max_single_letter_identifiers", "max_cryptic_abbreviations", "max_mutable_lazy_initializations",
    "max_dummy_keys", "max_raw_prints", "max_silent_catches", "max_service_locator_leaks",
    "max_nullable_collections", "max_unimplemented_placeholders", "max_concrete_client_instantiations",
    "max_trigger_matrix_mismatches", "max_harness_mirror_mismatches",
):
    clean_code.setdefault(key, 0)
simplicity = baseline.setdefault("simplicity", {})
simplicity.setdefault("ponytail_debt_markers", "report-only")
simplicity.setdefault("max_speculative_single_caller_abstractions", "advisory")
exclusions = baseline.setdefault("exclusions", {})
exclusions.setdefault("clean_code", [
    ".git/", ".github/", ".agents/", ".oaef/", "node_modules/", "vendor/", "build/", "dist/",
    "target/", "obj/", "tool/", "docs/", "templates/", "examples/", "coverage/", "generated/",
    "__pycache__/", ".venv/", "venv/",
])
with open(path, "w", encoding="utf-8") as handle:
    json.dump(document, handle, indent=2)
    handle.write("\n")
PYEOF
}

json_merge_context() { # keep user fields, refresh framework fields
  local context_path="$1"
  command -v python3 >/dev/null 2>&1 || return 0
  [ -f "$context_path" ] || return 0
  python3 - "$context_path" "$FRAMEWORK_VERSION" "$ADOPTION_MODE" <<'PYEOF'
import json, sys
path, version, adoption = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, "r", encoding="utf-8") as handle:
    try:
        document = json.load(handle)
    except json.JSONDecodeError:
        sys.exit(0)
document.setdefault("framework", "Open Agentic Engineering Framework (OAEF)")
document["version"] = version
document["skills_count"] = 13
document["governance_checks"] = [f"CC-{index:02d}" for index in range(1, 12)] + [f"SK-{index:02d}" for index in range(1, 7)] + ["PT-01"]
document["adoption_mode"] = adoption
document.setdefault("upgraded_at", "")
with open(path, "w", encoding="utf-8") as handle:
    json.dump(document, handle, indent=2)
    handle.write("\n")
PYEOF
}

json_set_key() { # json_set_key <file> <key> <json-value-literal>
  local file="$1" key="$2" value="$3"
  command -v python3 >/dev/null 2>&1 || return 0
  [ -f "$file" ] || return 0
  python3 - "$file" "$key" "$value" <<'PYEOF'
import json, sys
path, key, raw = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, "r", encoding="utf-8") as handle:
    document = json.load(handle)
document[key] = json.loads(raw)
with open(path, "w", encoding="utf-8") as handle:
    json.dump(document, handle, indent=2)
    handle.write("\n")
PYEOF
}

ratchet_clean_code() {
  local baseline_path="$1" inventory="$2"
  [ "$RATCHET_CLEAN_CODE" = "yes" ] || return 0
  [ -n "$inventory" ] || return 0
  command -v python3 >/dev/null 2>&1 || return 0
  python3 - "$baseline_path" "$inventory" <<'PYEOF'
import json, sys
baseline_path, inventory_path = sys.argv[1], sys.argv[2]
with open(baseline_path, "r", encoding="utf-8") as handle:
    document = json.load(handle)
with open(inventory_path, "r", encoding="utf-8") as handle:
    inventory = json.load(handle)
mapping = {
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
}
counts = {}
for entry in inventory.get("violations", []):
    counts[entry["check"]] = counts.get(entry["check"], 0) + 1
clean_code = document.setdefault("baseline", {}).setdefault("clean_code", {})
for check, key in mapping.items():
    measured = counts.get(check, 0)
    current = clean_code.get(key, 0)
    if isinstance(current, int):
        clean_code[key] = max(current, measured)
with open(baseline_path, "w", encoding="utf-8") as handle:
    json.dump(document, handle, indent=2)
    handle.write("\n")
PYEOF
}

collect_clean_code_inventory() { # runs the installed engine and records every finding
  local output_path="$1"
  : > "$output_path"
  [ -x "$TARGET_DIR/bin/oaef" ] || return 0
  local raw engine_status
  raw="$(cd "$TARGET_DIR" && ./bin/oaef clean-code 2>&1)"
  engine_status=$?
  printf '%s\n' "$raw" > "$TARGET_DIR/.oaef/clean-code.log" 2>/dev/null || true
  ENGINE_EXECUTED="yes"
  case "$engine_status" in
    0|1) ;;
    *) ENGINE_EXECUTED="no" ;;
  esac
  case "$raw" in
    *"command not found"*|*"No runtime governance script"*|*"Unhandled exception"*|*"error:"*|*"not recognized"*) ENGINE_EXECUTED="no" ;;
  esac
  printf '%s\n' "$ENGINE_EXECUTED" > "$TARGET_DIR/.oaef/engine-status" 2>/dev/null || true
  command -v python3 >/dev/null 2>&1 || return 0
  printf '%s\n' "$raw" | python3 - "$output_path" <<'PYEOF'
import json, re, sys
output_path = sys.argv[1]
pattern = re.compile(r"^(CC-\d{2}|SK-\d{2}|PT-\d{2}) ([^:]+):(\d+) — (.*)$")
violations = []
for line in sys.stdin.read().splitlines():
    match = pattern.match(line.strip())
    if not match:
        continue
    violations.append({
        "check": match.group(1),
        "path": match.group(2),
        "line": int(match.group(3)),
        "message": match.group(4),
    })
with open(output_path, "w", encoding="utf-8") as handle:
    json.dump({"violations": violations}, handle, indent=2)
    handle.write("\n")
PYEOF
}

write_adoption_ledger() {
  local inventory_path="$1"
  command -v python3 >/dev/null 2>&1 || return 0
  [ "$DRY_RUN" = "no" ] || return 0
  mkdir -p "$TARGET_DIR/docs/wiki/metrics" "$TARGET_DIR/docs/wiki/memory"
  python3 - "$TARGET_DIR" "$inventory_path" "$ADOPTION_MODE" "$STACK" "$STRICTNESS" "$FRAMEWORK_VERSION" "${ENGINE_EXECUTED:-no}" \
    "$(printf '%s\n' "${MERGED_FILES[@]:-}" | sed '/^$/d')" \
    "$(printf '%s\n' "${USER_SKILLS[@]:-}" | sed '/^$/d')" \
    "$(printf '%s\n' "${CONFLICT_FILES[@]:-}" | sed '/^$/d')" \
    "$(printf '%s\n' "${CONFLICT_SECTIONS[@]:-}" | sed '/^$/d')" \
    "$(printf '%s\n' "${PROPOSAL_PATHS[@]:-}" | sed '/^$/d')" <<'PYEOF'
import json, os, sys
from pathlib import Path

target = Path(sys.argv[1])
inventory_path = Path(sys.argv[2])
mode, stack, profile, version = sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6]
engine_executed = sys.argv[7]
merged = [line for line in sys.argv[8].splitlines() if line]
raw_user_skills = [line for line in sys.argv[9].splitlines() if line]
user_skills = []
for entry in raw_user_skills:
    parts = entry.split("/")
    if len(parts) >= 4 and parts[0] == ".agents" and parts[1] == "skills":
        user_skills.append(parts[2])
    else:
        user_skills.append(entry)
conflicts = [line for line in sys.argv[10].splitlines() if line]
conflict_sections = [line for line in sys.argv[11].splitlines() if line]
proposals = [line for line in sys.argv[12].splitlines() if line]

violations = []
if inventory_path.is_file():
    try:
        violations = json.loads(inventory_path.read_text(encoding="utf-8")).get("violations", [])
    except json.JSONDecodeError:
        violations = []

oversized_files = []
oversized_methods = []
excluded = {".git", "node_modules", "vendor", "build", "dist", "target", "obj", ".oaef", "docs", "tool", ".agents"}
for root, directories, files in os.walk(target):
    directories[:] = [name for name in directories if name not in excluded and not name.startswith(".")]
    for name in files:
        if not name.endswith((".dart", ".ts", ".tsx", ".js", ".mjs", ".py", ".go", ".rs", ".kt", ".kts", ".swift", ".cs")):
            continue
        path = Path(root) / name
        try:
            lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
        except OSError:
            continue
        if len(lines) > 300:
            oversized_files.append({"path": str(path.relative_to(target)), "lines": len(lines)})

per_check = {}
for entry in violations:
    per_check.setdefault(entry["check"], []).append(entry)

missing_skills = [
    skill for skill in (
        "ponytail", "nullable-types", "architecture-audit", "screen-builder", "component-author",
        "responsive-layout", "ui-preview", "fix-layout-issues", "test-generator", "collect-coverage",
        "run-static-analysis", "code-review", "conformance-audit",
    ) if not (target / ".agents/skills" / skill / "SKILL.md").is_file()
]

document = {
    "version": version,
    "mode": mode,
    "engine_executed": engine_executed == "yes",
    "stack": stack,
    "profile": profile,
    "framework_version": version,
    "user_skills": user_skills,
    "merged_files": merged,
    "conflict_sections": conflict_sections,
    "proposals": proposals,
    "conflicts": conflicts,
    "violations_total": len(violations),
    "violations_by_check": {check: len(entries) for check, entries in sorted(per_check.items())},
    "violations": violations,
    "sizing": {"oversized_files": oversized_files, "oversized_methods": oversized_methods},
    "missing_skills": missing_skills,
}

(target / "docs/wiki/metrics/adoption.json").write_text(
    json.dumps(document, indent=2) + "\n", encoding="utf-8"
)

lines = [
    "# Adoption Debt Ledger",
    "",
    f"> Generated by the OAEF installer in `{mode}` mode. This ledger inventories the debt that enters advisory state",
    "> during adoption. Nothing in this file is blocking: it is the ratchet backlog.",
    "",
    "## 1. Adoption Summary",
    "",
    "| Field | Value |",
    "| :--- | :--- |",
    f"| Mode | `{mode}` |",
    f"| Stack | `{stack}` |",
    f"| Profile | `{profile}` |",
    f"| Framework version | `{version}` |",
    f"| Merged files | {len(merged)} |",
    f"| User-owned skills preserved | {len(user_skills)} |",
    f"| Canonical proposals written (`*.oaef-new`) | {len(proposals)} |",
    f"| Governance engine executed | {'yes' if engine_executed == 'yes' else 'no (interpreter unavailable — inventory is empty, not clean)'} |",
    f"| Governed violations inventoried | {len(violations)} |",
    "",
    "## 2. Violations by Check",
    "",
    "| Check | Count |",
    "| :--- | :--- |",
]
if per_check:
    for check, entries in sorted(per_check.items()):
        lines.append(f"| `{check}` | {len(entries)} |")
else:
    lines.append("| (none) | 0 |")

lines += ["", "## 3. Violations", ""]
if violations:
    lines += ["| Check | Location | Message |", "| :--- | :--- | :--- |"]
    for entry in violations[:500]:
        lines.append(f"| `{entry['check']}` | `{entry['path']}:{entry['line']}` | {entry['message']} |")
    if len(violations) > 500:
        lines.append(f"| … | … | {len(violations) - 500} further findings in `adoption.json` |")
elif engine_executed == "yes":
    lines.append("No governance violation was detected by the installed engine.")
else:
    lines.append("The governance engine could not be executed in this environment (interpreter unavailable), so the inventory is empty rather than clean. Run `oaef clean-code` once the toolchain is present.")

lines += ["", "## 4. Sizing Inventory", ""]
if oversized_files:
    lines += ["| File | Lines |", "| :--- | :--- |"]
    for entry in oversized_files:
        lines.append(f"| `{entry['path']}` | {entry['lines']} |")
else:
    lines.append("No file exceeds the 300-line Clean Sizing bound.")

lines += ["", "## 5. Skills", ""]
if missing_skills:
    lines.append("Missing canonical skills: " + ", ".join(f"`{skill}`" for skill in missing_skills) + ".")
else:
    lines.append("All 13 canonical skills are present.")
if user_skills:
    lines += ["", "User-owned skills preserved (frontmatter and body are never rewritten):"]
    for entry in user_skills:
        lines.append(f"- `{entry}`")
lines += [
    "",
    "## 6. Conflicts and Merges",
    "",
]
if conflict_sections:
    for entry in conflict_sections:
        lines.append(f"- Section merge: `{entry}`")
elif conflicts:
    for entry in conflicts:
        lines.append(f"- `{entry}`")
else:
    lines.append("No section conflict was recorded: every canonical section merged cleanly.")

lines += [
    "",
    "## 7. Next Steps",
    "",
    "1. Review every `*.oaef-new` proposal and merge the parts you want.",
    "2. Resolve the inventoried violations highest-count first; each fix raises the ratchet.",
    "3. Lock the measured counts as floors with `oaef init --legacy --ratchet-clean-code` (or `oaef upgrade --ratchet-clean-code`).",
    "4. Once the inventory reaches zero, switch the repository to `--strict` so the barriers become blocking.",
    "",
    f"> Ledger data: `docs/wiki/metrics/adoption.json` · engine log: `.oaef/clean-code.log`",
    "",
]
(target / "docs/wiki/memory/adoption.md").write_text("\n".join(lines), encoding="utf-8")
PYEOF
}

append_adoption_log() {
  local log_path="$TARGET_DIR/docs/wiki/log.md"
  [ "$DRY_RUN" = "no" ] || return 0
  [ -f "$log_path" ] || return 0
  cat >> "$log_path" <<EOF

### [$TIMESTAMP] Adoption ($ADOPTION_MODE)
- Stack: $STACK · Quality Gate profile: $STRICTNESS · Framework: OAEF v$FRAMEWORK_VERSION
- Merged files: ${#MERGED_FILES[@]} · User-owned skills preserved: ${#USER_SKILLS[@]} · Canonical proposals: ${#PROPOSAL_PATHS[@]}
- Adoption Debt Ledger written to \`docs/wiki/memory/adoption.md\` (advisory barriers).
EOF
}

# ------------------------------------------------------------------------------
# Legacy coverage measurement (Monotonic Ratchet initialization)
# ------------------------------------------------------------------------------

measure_coverage() {
  local measured_lines=""
  local measured_branches=""

  # LCOV (Dart/Flutter, TypeScript, Rust tarpaulin, etc.)
  local lcov_path=""
  for candidate in "$TARGET_DIR/lcov.info" "$TARGET_DIR/coverage/lcov.info"; do
    [ -f "$candidate" ] && lcov_path="$candidate" && break
  done
  if [ -n "$lcov_path" ]; then
    measured_lines=$(awk -F: '/^LF:/{lines_found+=$2} /^LH:/{lines_hit+=$2} END{if(lines_found>0) printf "%.1f", lines_hit*100/lines_found}' "$lcov_path")
    measured_branches=$(awk -F: '/^BRF:/{branches_found+=$2} /^BRH:/{branches_hit+=$2} END{if(branches_found>0) printf "%.1f", branches_hit*100/branches_found}' "$lcov_path")
  fi

  # Istanbul coverage-summary.json (Jest/Vitest)
  if [ -z "$measured_lines" ] && command -v python3 >/dev/null 2>&1; then
    for candidate in "$TARGET_DIR/coverage/coverage-summary.json" "$TARGET_DIR/coverage-summary.json"; do
      if [ -f "$candidate" ]; then
        measured_lines=$(python3 -c "import json;d=json.load(open('$candidate'));t=d.get('total',{}).get('lines',{}).get('pct');print('%.1f'%t if isinstance(t,(int,float)) else '')" 2>/dev/null || true)
        measured_branches=$(python3 -c "import json;d=json.load(open('$candidate'));t=d.get('total',{}).get('branches',{}).get('pct');print('%.1f'%t if isinstance(t,(int,float)) else '')" 2>/dev/null || true)
        [ -n "$measured_lines" ] && break
      fi
    done
  fi

  # Cobertura XML (Python coverage.xml, .NET coverlet)
  if [ -z "$measured_lines" ]; then
    for candidate in "$TARGET_DIR/coverage.xml" "$TARGET_DIR/coverage/coverage.xml" "$TARGET_DIR/TestResults/coverage.cobertura.xml"; do
      if [ -f "$candidate" ]; then
        measured_lines=$(grep -o 'line-rate="[0-9.]*"' "$candidate" | head -1 | sed 's/[^0-9.]//g' | awk '{printf "%.1f", $1*100}')
        measured_branches=$(grep -o 'branch-rate="[0-9.]*"' "$candidate" | head -1 | sed 's/[^0-9.]//g' | awk '{printf "%.1f", $1*100}')
        [ -n "$measured_lines" ] && break
      fi
    done
  fi

  # JaCoCo / Kover XML (Kotlin, Kotlin Multiplatform)
  if [ -z "$measured_lines" ]; then
    for candidate in "$TARGET_DIR/build/reports/jacoco/test/jacocoTestReport.xml" "$TARGET_DIR/build/reports/kover/report.xml"; do
      if [ -f "$candidate" ]; then
        measured_lines=$(awk -F'"' '/<counter type="LINE"/{missed=$4; covered=$6; total=missed+covered; if(total>0) printf "%.1f", covered*100/total; exit}' "$candidate")
        measured_branches=$(awk -F'"' '/<counter type="BRANCH"/{missed=$4; covered=$6; total=missed+covered; if(total>0) printf "%.1f", covered*100/total; exit}' "$candidate")
        [ -n "$measured_lines" ] && break
      fi
    done
  fi

  echo "${measured_lines:-} ${measured_branches:-}"
}

# Determine quality thresholds
case $STRICTNESS in
  standard)
    LINE_COV=80.0
    BRANCH_COV=75.0
    MAX_FILE_LINES=400
    MAX_METHOD_LINES=60
    ;;
  legacy)
    LINE_COV=50.0
    BRANCH_COV=40.0
    MAX_FILE_LINES=500
    MAX_METHOD_LINES=80
    ;;
  *)
    LINE_COV=95.0
    BRANCH_COV=90.0
    MAX_FILE_LINES=300
    MAX_METHOD_LINES=50
    ;;
esac

MEASURED_LINES=""
MEASURED_BRANCHES=""
if [ "$STRICTNESS" = "legacy" ]; then
  if [ -n "$COVERAGE_OVERRIDE" ]; then
    MEASURED_LINES="$COVERAGE_OVERRIDE"
  else
    read -r MEASURED_LINES MEASURED_BRANCHES < <(measure_coverage)
  fi
  if [ -n "$MEASURED_LINES" ]; then
    LINE_COV="$MEASURED_LINES"
    [ -n "$MEASURED_BRANCHES" ] && BRANCH_COV="$MEASURED_BRANCHES"
    echo -e "   ${GREEN}📏 Legacy onboarding:${RESET} measured coverage locked as ratchet floor — lines ${BOLD}${LINE_COV}%${RESET}, branches ${BOLD}${BRANCH_COV}%${RESET}"
  else
    echo -e "   ${YELLOW}📏 Legacy onboarding:${RESET} no coverage artifact found — initializing conservative floors (50%/40%). Provide --coverage <pct> to lock a measured value."
  fi
fi

# ------------------------------------------------------------------------------
# Conflict discovery (legacy-safe preview before any destructive decision)
# ------------------------------------------------------------------------------

if [ "$DRY_RUN" = "no" ] && [ "$FORCE" = "no" ] && [ "$NON_INTERACTIVE" != "yes" ] && [ -t 0 ]; then
  CONFLICT_PREVIEW=0
  for preview_candidate in "$TARGET_DIR/AGENTS.md" "$TARGET_DIR/CLAUDE.md" "$TARGET_DIR/llms.txt" "$TARGET_DIR/CONTRIBUTING.md" "$TARGET_DIR/SECURITY.md" "$TARGET_DIR/docs" "$TARGET_DIR/.github" "$TARGET_DIR/.agents" "$TARGET_DIR/tool"; do
    [ -e "$preview_candidate" ] && CONFLICT_PREVIEW=$((CONFLICT_PREVIEW + 1))
  done
  if [ "$CONFLICT_PREVIEW" -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Existing repository artifacts detected.${RESET} By default OAEF preserves every existing file and writes proposals as <file>.oaef-new."
    read -r -p "Strategy [K]eep (default) / [B]ackup & overwrite / [A]bort: " CONFLICT_STRATEGY
    case $CONFLICT_STRATEGY in
      [Bb]*)
        FORCE="yes"
        BACKUP="yes"
        echo -e "   ${CYAN}→ Backup & overwrite selected. Existing files will be copied to .oaef/backup/<timestamp>/ first.${RESET}"
        ;;
      [Aa]*)
        echo "Aborted. No changes were made."
        exit 0
        ;;
      *)
        echo -e "   ${GREEN}→ Keep selected. Existing files are preserved; proposals will be written as <file>.oaef-new.${RESET}"
        ;;
    esac
  fi
fi

if [ "$BACKUP" = "yes" ] && [ "$DRY_RUN" = "no" ]; then
  BACKUP_ROOT="$TARGET_DIR/.oaef/backup/$(date -u +"%Y%m%dT%H%M%SZ")"
fi

# ------------------------------------------------------------------------------
# Base directory scaffolding
# ------------------------------------------------------------------------------

if [ "$DRY_RUN" = "no" ]; then
  mkdir -p "$TARGET_DIR/docs/adr"
  mkdir -p "$TARGET_DIR/docs/bdd"
  mkdir -p "$TARGET_DIR/docs/standards"
  mkdir -p "$TARGET_DIR/docs/wiki/memory"
  mkdir -p "$TARGET_DIR/docs/wiki/metrics"
  mkdir -p "$TARGET_DIR/.github/workflows"
  mkdir -p "$TARGET_DIR/tool"
fi

# ------------------------------------------------------------------------------
# Copy base templates (universal docs & community standards) - legacy-safe
# ------------------------------------------------------------------------------

place_tree "$SCRIPT_DIR/templates/base/docs" "$TARGET_DIR/docs" "wiki/metrics/baseline.json wiki/metrics/history.json wiki/log.md wiki/memory/handoff.md"
if [ ! -f "$TARGET_DIR/docs/wiki/metrics/history.json" ]; then
  place_file "$SCRIPT_DIR/templates/base/docs/wiki/metrics/history.json" "$TARGET_DIR/docs/wiki/metrics/history.json"
else
  PRESERVED_FILES+=("docs/wiki/metrics/history.json (existing metrics history preserved)")
fi
place_file "$SCRIPT_DIR/templates/base/AGENTS.md" "$TARGET_DIR/AGENTS.md"
place_file "$SCRIPT_DIR/templates/base/llms.txt" "$TARGET_DIR/llms.txt"
place_file "$SCRIPT_DIR/templates/base/CONTRIBUTING.md" "$TARGET_DIR/CONTRIBUTING.md"
place_file "$SCRIPT_DIR/templates/base/SECURITY.md" "$TARGET_DIR/SECURITY.md"

if [ -d "$SCRIPT_DIR/templates/base/.github" ]; then
  place_tree "$SCRIPT_DIR/templates/base/.github" "$TARGET_DIR/.github"
fi

# Copy stack-tailored CI workflow (Zero-Pollution Guarantee)
CI_SOURCE="$SCRIPT_DIR/templates/ci/$STACK/ci.yml"
if [ -f "$CI_SOURCE" ]; then
  place_file "$CI_SOURCE" "$TARGET_DIR/.github/workflows/ci.yml"
else
  place_file "$SCRIPT_DIR/templates/ci/universal/ci.yml" "$TARGET_DIR/.github/workflows/ci.yml"
fi

# Copy ONLY selected stack skills (Zero-Pollution Guarantee)
if [ "$INSTALL_SKILLS" = "yes" ]; then
  SKILLS_SOURCE="$SCRIPT_DIR/templates/skills/$STACK"
  if [ -d "$SKILLS_SOURCE" ]; then
    place_tree "$SKILLS_SOURCE" "$TARGET_DIR/.agents/skills"
  else
    place_tree "$SCRIPT_DIR/templates/skills/universal" "$TARGET_DIR/.agents/skills"
  fi
fi

install_skill_mirrors
note_gitignore

# Copy ONLY selected stack runtime governance engine
case $STACK in
  dart-flutter) RUNTIME_STACK="dart" ;;
  typescript-web) RUNTIME_STACK="typescript" ;;
  universal) RUNTIME_STACK="shell" ;;
  *) RUNTIME_STACK="$STACK" ;;
esac
RUNTIME_SOURCE="$SCRIPT_DIR/templates/runtimes/$RUNTIME_STACK"
if [ -d "$RUNTIME_SOURCE" ]; then
  place_tree "$RUNTIME_SOURCE" "$TARGET_DIR/tool"
else
  place_tree "$SCRIPT_DIR/templates/runtimes/shell" "$TARGET_DIR/tool"
fi

# Install the portable OAEF CLI (doctor/lint/audit/sync/metrics)
place_file "$SCRIPT_DIR/bin/oaef" "$TARGET_DIR/bin/oaef"

# .gitignore is only installed when absent (existing ignore rules are never touched)
if [ ! -f "$TARGET_DIR/.gitignore" ]; then
  if [ "$DRY_RUN" = "yes" ]; then
    echo -e "   ${CYAN}[dry-run]${RESET} would install  .gitignore"
  else
    cp -p "$SCRIPT_DIR/templates/base/.gitignore" "$TARGET_DIR/.gitignore"
  fi
  INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
else
  PRESERVED_FILES+=(".gitignore")
fi

# ------------------------------------------------------------------------------
# Hydrate placeholders ONLY in files written by this installer
# ------------------------------------------------------------------------------

if [ "$DRY_RUN" = "no" ] && { [ "${#INSTALLED_PATHS[@]}" -gt 0 ] || [ "${#PROPOSAL_PATHS[@]}" -gt 0 ]; }; then
  for written_file in "${INSTALLED_PATHS[@]}" "${PROPOSAL_PATHS[@]}"; do
    [ -f "$written_file" ] || continue
    case "$written_file" in
      "$TARGET_DIR/tool/"*|"$TARGET_DIR/.agents/"*|"$TARGET_DIR/.github/"*) continue ;;
    esac
    hydrate_file "$written_file"
  done
fi

# ------------------------------------------------------------------------------
# Inject stack-specific architectural rules into AGENTS.md (Zero-Pollution)
# Only files written by this installer are touched; preserved contracts are kept.
# (inject_stack_rules is defined with the placement engine)
# ------------------------------------------------------------------------------

if [ "$DRY_RUN" = "no" ]; then
  if printf '%s\n' "${INSTALLED_PATHS[@]:-}" | grep -qx "$TARGET_DIR/AGENTS.md"; then
    inject_stack_rules "$TARGET_DIR/AGENTS.md"
  fi
  if [ -f "$TARGET_DIR/AGENTS.md.oaef-new" ]; then
    inject_stack_rules "$TARGET_DIR/AGENTS.md.oaef-new"
  fi
fi

# ------------------------------------------------------------------------------
# Mirror AGENTS.md to CLAUDE.md (protected: user-owned CLAUDE.md is never clobbered)
# ------------------------------------------------------------------------------

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

generate_claude_mirror() {
  local output_path="${1:-$TARGET_DIR/CLAUDE.md}"
  local agents_content
  agents_content="$(cat "$TARGET_DIR/AGENTS.md")"
  printf '%s\n' "<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->" \
    "<!-- To modify rules, edit AGENTS.md and run \"oaef sync\". -->" \
    "" \
    "$agents_content" > "$output_path"
}

if [ "$DRY_RUN" = "yes" ]; then
  echo -e "   ${CYAN}[dry-run]${RESET} would synchronize CLAUDE.md mirror"
elif [ ! -f "$TARGET_DIR/CLAUDE.md" ]; then
  if [ -f "$TARGET_DIR/AGENTS.md" ]; then
    generate_claude_mirror
    GENERATED_FILES+=("CLAUDE.md")
    INSTALLED_PATHS+=("$TARGET_DIR/CLAUDE.md")
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
  fi
elif grep -q "AUTO-GENERATED MIRROR FROM AGENTS.md" "$TARGET_DIR/CLAUDE.md" 2>/dev/null; then
  if [ -f "$TARGET_DIR/AGENTS.md" ]; then
    MIRROR_TEMP="$(mktemp)"
    generate_claude_mirror "$MIRROR_TEMP"
    if cmp -s "$MIRROR_TEMP" "$TARGET_DIR/CLAUDE.md"; then
      UNCHANGED_COUNT=$((UNCHANGED_COUNT + 1))
    else
      backup_existing "$TARGET_DIR/CLAUDE.md"
      cp -p "$MIRROR_TEMP" "$TARGET_DIR/CLAUDE.md"
      INSTALLED_PATHS+=("$TARGET_DIR/CLAUDE.md")
      INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    fi
    rm -f "$MIRROR_TEMP"
  fi
elif [ "$ADOPTION_MODE" != "install" ]; then
  if [ -f "$TARGET_DIR/AGENTS.md" ]; then
    if [ "$DRY_RUN" = "no" ]; then
      backup_existing "$TARGET_DIR/CLAUDE.md"
      cp -p "$TARGET_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md.oaef-new"
      PROPOSAL_PATHS+=("$TARGET_DIR/CLAUDE.md.oaef-new")
      generate_claude_mirror
      GENERATED_FILES+=("CLAUDE.md")
      INSTALLED_PATHS+=("$TARGET_DIR/CLAUDE.md")
      INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
      PRESERVED_FILES+=("CLAUDE.md.oaef-new (your previous CLAUDE.md, preserved verbatim)")
    fi
  fi
else
  PRESERVED_FILES+=("CLAUDE.md (user-owned, not an OAEF mirror)")
fi

# ------------------------------------------------------------------------------
# Baseline, context manifest, log and handoff (generated artifacts)
# ------------------------------------------------------------------------------

BASELINE_PATH="$TARGET_DIR/docs/wiki/metrics/baseline.json"
if [ -f "$BASELINE_PATH" ] && [ "$FORCE" != "yes" ]; then
  PRESERVED_FILES+=("docs/wiki/metrics/baseline.json (Monotonic Ratchet protected)")
  json_merge_baseline "$BASELINE_PATH"
  echo -e "   ${CYAN}🔒 Baseline:${RESET} existing floors preserved; v$FRAMEWORK_VERSION keys added (clean_code, simplicity)"
else
  [ -f "$BASELINE_PATH" ] && backup_existing "$BASELINE_PATH"
  write_generated_file "$BASELINE_PATH" "$(cat <<EOF
{
  "version": "$FRAMEWORK_VERSION",
  "framework": "OAEF",
  "profile": "$STRICTNESS",
  "stack": "$STACK",
  "baseline": {
    "coverage": {
      "lines_min_percentage": $LINE_COV,
      "statements_min_percentage": $LINE_COV,
      "functions_min_percentage": $LINE_COV,
      "branches_min_percentage": $BRANCH_COV
    },
    "duplication": {
      "max_percentage": 3.0,
      "max_fragments": 0,
      "fragment_min_lines": 15
    },
    "violations": {
      "max_analysis_violations": 0,
      "max_unallowed_ignores": 0
    },
    "clean_sizing": {
      "max_oversized_files": 0,
      "file_max_lines": $MAX_FILE_LINES,
      "max_oversized_methods": 0,
      "method_max_lines": $MAX_METHOD_LINES
    },
    "clean_code": {
      "max_single_letter_identifiers": 0,
      "max_cryptic_abbreviations": 0,
      "max_mutable_lazy_initializations": 0,
      "max_dummy_keys": 0,
      "max_raw_prints": 0,
      "max_silent_catches": 0,
      "max_service_locator_leaks": 0,
      "max_nullable_collections": 0,
      "max_unimplemented_placeholders": 0,
      "max_concrete_client_instantiations": 0,
      "max_trigger_matrix_mismatches": 0,
      "max_harness_mirror_mismatches": 0
    },
    "simplicity": {
      "ponytail_debt_markers": "report-only",
      "max_speculative_single_caller_abstractions": "advisory"
    },
    "secret_scanning": {
      "max_detected_secrets": 0
    },
    "exclusions": {
      "coverage": [
        ".g.",
        "/generated/",
        ".min.js",
        "_test.",
        "test/"
      ],
      "clean_sizing": [
        ".g.",
        "/generated/",
        "dist/",
        "build/"
      ],
      "clean_code": [
        ".git/",
        ".github/",
        ".agents/",
        ".oaef/",
        "node_modules/",
        "vendor/",
        "build/",
        "dist/",
        "target/",
        "obj/",
        "tool/",
        "docs/",
        "templates/",
        "examples/",
        "coverage/",
        "generated/",
        "__pycache__/",
        ".venv/",
        "venv/"
      ]
    }
  }
}
EOF
)"
fi

CONTEXT_PATH="$TARGET_DIR/oaef.context.json"
if [ -f "$CONTEXT_PATH" ] && [ "$FORCE" != "yes" ]; then
  if [ "$ADOPTION_MODE" = "upgrade" ]; then
    json_merge_context "$CONTEXT_PATH"
    PRESERVED_FILES+=("oaef.context.json (existing manifest preserved; framework fields refreshed)")
    if command -v python3 >/dev/null 2>&1; then
      json_set_key "$CONTEXT_PATH" upgraded_at "\"$TIMESTAMP\""
    fi
  else
    PRESERVED_FILES+=("oaef.context.json (existing project manifest preserved)")
  fi
else
  [ -f "$CONTEXT_PATH" ] && backup_existing "$CONTEXT_PATH"
  LEGACY_MEASURED_JSON=""
  if [ "$STRICTNESS" = "legacy" ] && [ -n "$MEASURED_LINES" ]; then
    LEGACY_MEASURED_JSON=",
  \"legacy_measured_coverage\": {
    \"lines_min_percentage\": $MEASURED_LINES,
    \"branches_min_percentage\": $BRANCH_COV
  }"
  fi
  write_generated_file "$CONTEXT_PATH" "$(cat <<EOF
{
  "framework": "Open Agentic Engineering Framework (OAEF)",
  "version": "$FRAMEWORK_VERSION",
  "author": "Felipe Carvalho",
  "project_name": "$PROJECT_NAME",
  "description": "$PROJECT_DESC",
  "stack": "$STACK",
  "strictness": "$STRICTNESS",
  "adoption_mode": "$ADOPTION_MODE",
  "skills_count": 13,
  "governance_checks": ["CC-01", "CC-02", "CC-03", "CC-04", "CC-05", "CC-06", "CC-07", "CC-08", "CC-09", "CC-10", "CC-11", "SK-01", "SK-02", "SK-03", "SK-04", "SK-05", "SK-06", "PT-01"],
  "installed_at": "$TIMESTAMP",
  "inviolable_trust_hierarchy": "Compiler > Automated Tests > Source Code > Wiki/Docs > Ephemeral Memory > LLM Hallucination"$LEGACY_MEASURED_JSON
}
EOF
)"
fi

# Initialize handoff.md and log.md only when empty (existing memory is preserved)
if [ ! -s "$TARGET_DIR/docs/wiki/log.md" ]; then
  write_generated_file "$TARGET_DIR/docs/wiki/log.md" "$(cat <<EOF
# Project Historical Logbook (Append-Only)
> Initialized via Open Agentic Engineering Framework (OAEF) by Felipe Carvalho.

---

### [$TIMESTAMP] OAEF v$FRAMEWORK_VERSION Activated
- Stack: $STACK
- Quality Gate Profile: $STRICTNESS
- Initial living repository structure established.
EOF
)"
else
  PRESERVED_FILES+=("docs/wiki/log.md (existing history preserved)")
fi

if [ ! -s "$TARGET_DIR/docs/wiki/memory/handoff.md" ]; then
  write_generated_file "$TARGET_DIR/docs/wiki/memory/handoff.md" "$(cat <<EOF
---
active_agent: "none"
session_id: "genesis"
locked_at: "$TIMESTAMP"
status: "idle"
---

# Session Handoff Ledger
> **Last Updated:** $TIMESTAMP  
> **Active Stack:** $STACK  
> **Quality Gate Status:** Initialized ($STRICTNESS)

---

## 1. Accomplished in this Session
- Initialized Living Repository with OAEF standard.
- Established Inviolable Trust Hierarchy and living docs tree.
- Configured stack-tailored agent skills in \`.agents/skills/\`.

## 2. Immediate Next Tasks
- [ ] Implement initial business domain features under test-driven development.
- [ ] Execute initial Quality Gate audit: run \`oaef doctor\` and \`oaef audit\`.

## 3. Active Blockers & Contradiction Triage
*(None)*
EOF
)"
else
  PRESERVED_FILES+=("docs/wiki/memory/handoff.md (existing session memory preserved)")
fi

# Set executable permissions on tools
if [ "$DRY_RUN" = "no" ]; then
  chmod +x "$TARGET_DIR/tool"/* 2>/dev/null || true
  chmod +x "$TARGET_DIR/bin/oaef" 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# Adoption Debt Ledger (adoption modes) + optional clean-code ratchet
# ------------------------------------------------------------------------------

if [ "$DRY_RUN" = "no" ] && { [ "$ADOPTION_MODE" != "install" ] || [ "$ADOPT_REPORT" = "yes" ]; }; then
  if [ "$INSTALL_SKILLS" = "yes" ] || [ "$ADOPT_REPORT" = "yes" ]; then
    INVENTORY_PATH="$TARGET_DIR/.oaef/clean-code-inventory.json"
    mkdir -p "$TARGET_DIR/.oaef"
    collect_clean_code_inventory "$INVENTORY_PATH"
    CLEAN_CODE_INVENTORY="$INVENTORY_PATH"
    write_adoption_ledger "$INVENTORY_PATH"
    ratchet_clean_code "$BASELINE_PATH" "$INVENTORY_PATH"
    append_adoption_log
    GENERATED_FILES+=("docs/wiki/memory/adoption.md" "docs/wiki/metrics/adoption.json")
    echo -e "   ${GREEN}📒 Adoption Debt Ledger:${RESET} docs/wiki/memory/adoption.md (advisory barriers, counts inventoried)"
    if [ "$RATCHET_CLEAN_CODE" = "yes" ]; then
      echo -e "   ${GREEN}🔒 Clean-code ratchet:${RESET} measured counts locked as the new baseline floors"
    fi
  fi
fi

# ------------------------------------------------------------------------------
# Installation report
# ------------------------------------------------------------------------------

echo ""
if [ "$DRY_RUN" = "yes" ]; then
  echo -e "${BOLD}${CYAN}🧪 Dry-run complete — no changes were written to disk.${RESET}"
else
  echo -e "${BOLD}${GREEN}✅ OAEF successfully installed in:${RESET} $TARGET_DIR"
fi
echo -e "   • Framework: ${BOLD}OAEF v$FRAMEWORK_VERSION${RESET}"
echo -e "   • Stack: ${BOLD}$STACK${RESET}"
echo -e "   • Quality Gates: ${BOLD}$STRICTNESS${RESET} (lines ${LINE_COV}% / branches ${BRANCH_COV}%)"
echo -e "   • Zero-Pollution Isolation: ${BOLD}Active (Zero foreign files)${RESET}"
echo -e "   • Adoption mode: ${BOLD}$ADOPTION_MODE${RESET}$([ "$ADOPTION_MODE" = "install" ] || echo " (governance barriers advisory + ledger)")"
echo -e "   • Manifest: ${BOLD}oaef.context.json${RESET}"
echo ""
echo -e "${BOLD}📊 Installation report${RESET}"
echo -e "   • Installed/generated: ${GREEN}${INSTALLED_COUNT}${RESET} files"
echo -e "   • Unchanged:           ${UNCHANGED_COUNT} files"
echo -e "   • Preserved (existing): ${YELLOW}${#PRESERVED_FILES[@]}${RESET} files"

if [ "${#PRESERVED_FILES[@]}" -gt 0 ]; then
  for preserved_entry in "${PRESERVED_FILES[@]}"; do
    echo -e "       - $preserved_entry"
  done
fi

if [ "${#MERGED_FILES[@]}" -gt 0 ]; then
  echo -e "   • Merged (user content preserved): ${GREEN}${#MERGED_FILES[@]}${RESET} files"
  for merged_entry in "${MERGED_FILES[@]}"; do
    echo -e "       - $merged_entry"
  done
fi

if [ "${#MIRROR_DIRS_CREATED[@]}" -gt 0 ]; then
  echo -e "   • Harness skill mirrors: ${GREEN}${#MIRROR_DIRS_CREATED[@]}${RESET} directories"
  for mirror_entry in "${MIRROR_DIRS_CREATED[@]}"; do
    echo -e "       - $mirror_entry"
  done
fi

if [ "${#USER_SKILLS[@]}" -gt 0 ]; then
  echo -e "   • User-owned skills preserved: ${YELLOW}${#USER_SKILLS[@]}${RESET} (canonical proposals written)"
  for skill_entry in "${USER_SKILLS[@]}"; do
    echo -e "       - $skill_entry → $skill_entry.oaef-new"
  done
fi

if [ "${#CONFLICT_FILES[@]}" -gt 0 ]; then
  echo -e "   • Conflicts: ${YELLOW}${#CONFLICT_FILES[@]}${RESET} entries (nothing was deleted or overwritten)"
  for conflict_entry in "${CONFLICT_FILES[@]}"; do
    echo -e "       - $conflict_entry"
  done
  echo -e "     Section merges keep user text outside the OAEF sentinels untouched."
  echo -e "     Files proposed as ${CYAN}<file>.oaef-new${RESET} require a human decision; apply them with ${CYAN}--backup --force${RESET}."
fi

if [ -n "$CLEAN_CODE_INVENTORY" ]; then
  echo -e "   • Adoption Debt Ledger: ${CYAN}docs/wiki/memory/adoption.md${RESET} (data: docs/wiki/metrics/adoption.json)"
fi

if [ "$BACKUP" = "yes" ] && [ "$DRY_RUN" = "no" ]; then
  echo -e "   • Backup root:         ${CYAN}${BACKUP_ROOT#$TARGET_DIR/}${RESET}"
fi

echo ""
echo -e "Next steps:"
echo -e "  1. Review ${CYAN}AGENTS.md${RESET} and ${CYAN}docs/INDEX.md${RESET}"
echo -e "  2. Run the conformance audit: ${CYAN}oaef doctor${RESET}, then ${CYAN}oaef clean-code${RESET} and ${CYAN}oaef skills audit --selftest${RESET}"
echo -e "  3. Ready for autonomous AI coding agents (Claude Code, Codex, OpenCode, Antigravity, Cursor, etc.)"
echo ""
