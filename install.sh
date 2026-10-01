#!/usr/bin/env bash
# ==============================================================================
# Open Agentic Engineering Framework (OAEF) - Unified Installer & Discovery
# Author & Creator: Felipe Carvalho
# License: Apache License 2.0
#
# Legacy-safe by default: existing files are NEVER overwritten. Conflicting
# artifacts are preserved and proposed as "<file>.oaef-new" for human review.
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

# Installation bookkeeping
INSTALLED_COUNT=0
UNCHANGED_COUNT=0
PRESERVED_FILES=()
CONFLICT_FILES=()
GENERATED_FILES=()
INSTALLED_PATHS=()
PROPOSAL_PATHS=()
BACKUP_ROOT=""

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
      echo "  --legacy             Measure current coverage and lock it as the Monotonic Ratchet floor"
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
  read -r -p "Install the 11 stack-tailored skills into .agents/skills/? [Y/n]: " SKILLS_CHOICE
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

place_file() {
  local source_path="$1"
  local destination_path="$2"
  local relative_path="${destination_path#$TARGET_DIR/}"

  if [ ! -e "$destination_path" ]; then
    if [ "$DRY_RUN" = "yes" ]; then
      echo -e "   ${CYAN}[dry-run]${RESET} would install  $relative_path"
    else
      mkdir -p "$(dirname "$destination_path")"
      cp -p "$source_path" "$destination_path"
      INSTALLED_PATHS+=("$destination_path")
    fi
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    return 0
  fi

  if source_matches_existing "$source_path" "$destination_path"; then
    UNCHANGED_COUNT=$((UNCHANGED_COUNT + 1))
    return 0
  fi

  if [ "$FORCE" = "yes" ]; then
    if [ "$DRY_RUN" = "yes" ]; then
      echo -e "   ${CYAN}[dry-run]${RESET} would overwrite $relative_path (forced)"
    else
      backup_existing "$destination_path"
      cp -p "$source_path" "$destination_path"
      INSTALLED_PATHS+=("$destination_path")
    fi
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    return 0
  fi

  if [ "$DRY_RUN" = "yes" ]; then
    echo -e "   ${YELLOW}[dry-run]${RESET} conflict with  $relative_path (would preserve + propose .oaef-new)"
  else
    cp -p "$source_path" "$destination_path.oaef-new"
    PROPOSAL_PATHS+=("$destination_path.oaef-new")
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

place_tree "$SCRIPT_DIR/templates/base/docs" "$TARGET_DIR/docs" "wiki/metrics/baseline.json wiki/log.md wiki/memory/handoff.md"
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
else
  PRESERVED_FILES+=("CLAUDE.md (user-owned, not an OAEF mirror)")
fi

# ------------------------------------------------------------------------------
# Baseline, context manifest, log and handoff (generated artifacts)
# ------------------------------------------------------------------------------

BASELINE_PATH="$TARGET_DIR/docs/wiki/metrics/baseline.json"
if [ -f "$BASELINE_PATH" ] && [ "$FORCE" != "yes" ]; then
  PRESERVED_FILES+=("docs/wiki/metrics/baseline.json (Monotonic Ratchet protected)")
else
  [ -f "$BASELINE_PATH" ] && backup_existing "$BASELINE_PATH"
  write_generated_file "$BASELINE_PATH" "$(cat <<EOF
{
  "version": "1.0.0",
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
      ]
    }
  }
}
EOF
)"
fi

CONTEXT_PATH="$TARGET_DIR/oaef.context.json"
if [ -f "$CONTEXT_PATH" ] && [ "$FORCE" != "yes" ]; then
  PRESERVED_FILES+=("oaef.context.json (existing project manifest preserved)")
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
  "version": "1.0.0",
  "author": "Felipe Carvalho",
  "project_name": "$PROJECT_NAME",
  "description": "$PROJECT_DESC",
  "stack": "$STACK",
  "strictness": "$STRICTNESS",
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

### [$TIMESTAMP] OAEF v1.0.0 Activated
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
echo -e "   • Stack: ${BOLD}$STACK${RESET}"
echo -e "   • Quality Gates: ${BOLD}$STRICTNESS${RESET} (lines ${LINE_COV}% / branches ${BRANCH_COV}%)"
echo -e "   • Zero-Pollution Isolation: ${BOLD}Active (Zero foreign files)${RESET}"
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

if [ "${#CONFLICT_FILES[@]}" -gt 0 ]; then
  echo -e "   • Conflicts proposed:  ${YELLOW}${#CONFLICT_FILES[@]}${RESET} files (existing files were NOT modified)"
  for conflict_entry in "${CONFLICT_FILES[@]}"; do
    echo -e "       - $conflict_entry → $conflict_entry.oaef-new"
  done
  echo -e "     Review each proposal, merge what you want, then delete the .oaef-new files."
  echo -e "     To apply proposals automatically on a future run: ${CYAN}--backup --force${RESET}"
fi

if [ "$BACKUP" = "yes" ] && [ "$DRY_RUN" = "no" ]; then
  echo -e "   • Backup root:         ${CYAN}${BACKUP_ROOT#$TARGET_DIR/}${RESET}"
fi

echo ""
echo -e "Next steps:"
echo -e "  1. Review ${CYAN}AGENTS.md${RESET} and ${CYAN}docs/INDEX.md${RESET}"
echo -e "  2. Run the conformance audit: ${CYAN}oaef doctor${RESET} (or your stack's tool/governance.*)"
echo -e "  3. Ready for autonomous AI coding agents (Claude Code, Codex, OpenCode, Antigravity, Cursor, etc.)"
echo ""
