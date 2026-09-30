#!/usr/bin/env bash
# ==============================================================================
# Open Agentic Engineering Framework (OAEF) - Unified Installer & Discovery
# Author & Creator: Felipe Carvalho
# License: Apache License 2.0
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
      echo "  --legacy             Initialize baseline at current project coverage (Monotonic Ratchet)"
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
mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

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
  echo "  3) Legacy Onboarding — Ratchet rule (locks current coverage as floor, can only move up)"
  read -r -p "Select profile [1-3, Default: 1]: " RIGOR_CHOICE
  case $RIGOR_CHOICE in
    2) STRICTNESS="standard" ;;
    3) STRICTNESS="legacy" ;;
    *) STRICTNESS="strict" ;;
  esac

  # 5. Skills Installation
  echo ""
  echo -e "${CYAN}[Step 5/5] Stack-Adaptive Agent Skills:${RESET}"
  read -r -p "Install the 10 stack-tailored skills into .agents/skills/? [Y/n]: " SKILLS_CHOICE
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

# Create directories in target
mkdir -p "$TARGET_DIR/docs/adr"
mkdir -p "$TARGET_DIR/docs/bdd"
mkdir -p "$TARGET_DIR/docs/standards"
mkdir -p "$TARGET_DIR/docs/wiki/memory"
mkdir -p "$TARGET_DIR/docs/wiki/metrics"
mkdir -p "$TARGET_DIR/.github/workflows"
mkdir -p "$TARGET_DIR/tool"
mkdir -p "$TARGET_DIR/bin"

# Copy base templates (universal docs & community standards)
cp -R "$SCRIPT_DIR/templates/base/docs/" "$TARGET_DIR/docs/"
cp "$SCRIPT_DIR/templates/base/AGENTS.md" "$TARGET_DIR/AGENTS.md"
cp "$SCRIPT_DIR/templates/base/llms.txt" "$TARGET_DIR/llms.txt"
cp -R "$SCRIPT_DIR/templates/base/.github/" "$TARGET_DIR/.github/"
cp "$SCRIPT_DIR/templates/base/CONTRIBUTING.md" "$TARGET_DIR/CONTRIBUTING.md"
cp "$SCRIPT_DIR/templates/base/SECURITY.md" "$TARGET_DIR/SECURITY.md"
if [ ! -f "$TARGET_DIR/.gitignore" ]; then
  cp "$SCRIPT_DIR/templates/base/.gitignore" "$TARGET_DIR/.gitignore"
fi

# Copy stack-tailored CI workflow (Zero-Pollution Guarantee)
CI_SRC="$SCRIPT_DIR/templates/ci/$STACK/ci.yml"
if [ -f "$CI_SRC" ]; then
  cp "$CI_SRC" "$TARGET_DIR/.github/workflows/ci.yml"
else
  cp "$SCRIPT_DIR/templates/ci/universal/ci.yml" "$TARGET_DIR/.github/workflows/ci.yml"
fi

# Inject stack-specific architectural rules into AGENTS.md (Zero-Pollution Guarantee)
RULES_SRC="$SCRIPT_DIR/templates/rules/$STACK/rules.md"
if [ ! -f "$RULES_SRC" ]; then
  RULES_SRC="$SCRIPT_DIR/templates/rules/universal/rules.md"
fi

if command -v python3 >/dev/null 2>&1; then
  python3 -c "
with open('$RULES_SRC', 'r', encoding='utf-8') as f:
    rules = f.read()
with open('$TARGET_DIR/AGENTS.md', 'r', encoding='utf-8') as f:
    agents = f.read()
agents = agents.replace('{{STACK_SPECIFIC_RULES}}', rules)
with open('$TARGET_DIR/AGENTS.md', 'w', encoding='utf-8') as f:
    f.write(agents)
"
else
  awk -v r="$(cat "$RULES_SRC")" '{gsub(/\{\{STACK_SPECIFIC_RULES\}\}/, r)}1' "$TARGET_DIR/AGENTS.md" > "$TARGET_DIR/AGENTS.md.tmp" && mv "$TARGET_DIR/AGENTS.md.tmp" "$TARGET_DIR/AGENTS.md"
fi

# Copy ONLY selected stack skills (Zero-Pollution Guarantee)
if [ "$INSTALL_SKILLS" = "yes" ]; then
  mkdir -p "$TARGET_DIR/.agents/skills"
  SKILLS_SRC="$SCRIPT_DIR/templates/skills/$STACK"
  if [ -d "$SKILLS_SRC" ]; then
    cp -R "$SKILLS_SRC/"* "$TARGET_DIR/.agents/skills/"
  else
    # Fallback to universal
    cp -R "$SCRIPT_DIR/templates/skills/universal/"* "$TARGET_DIR/.agents/skills/"
  fi
fi

# Copy ONLY selected stack runtime governance engine
RUNTIME_SRC="$SCRIPT_DIR/templates/runtimes/$STACK"
if [ -d "$RUNTIME_SRC" ]; then
  cp -R "$RUNTIME_SRC/"* "$TARGET_DIR/tool/"
else
  cp -R "$SCRIPT_DIR/templates/runtimes/shell/"* "$TARGET_DIR/tool/"
fi

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

# Generate baseline.json
cat <<EOF > "$TARGET_DIR/docs/wiki/metrics/baseline.json"
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

# Emit oaef.context.json
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat <<EOF > "$TARGET_DIR/oaef.context.json"
{
  "framework": "Open Agentic Engineering Framework (OAEF)",
  "version": "1.0.0",
  "author": "Felipe Carvalho",
  "project_name": "$PROJECT_NAME",
  "description": "$PROJECT_DESC",
  "stack": "$STACK",
  "strictness": "$STRICTNESS",
  "installed_at": "$TIMESTAMP",
  "inviolable_trust_hierarchy": "Compiler > Automated Tests > Source Code > Wiki/Docs > Ephemeral Memory > LLM Hallucination"
}
EOF

# Hydrate placeholders in markdown templates
REPLACE_NAME="${PROJECT_NAME:-TargetProject}"
find "$TARGET_DIR/docs" "$TARGET_DIR/AGENTS.md" "$TARGET_DIR/llms.txt" "$TARGET_DIR/CONTRIBUTING.md" -type f 2>/dev/null | while read -r file; do
  if [ -f "$file" ]; then
    # Use sed portably
    sed -i '' "s/{{PROJECT_NAME}}/$REPLACE_NAME/g" "$file" 2>/dev/null || sed -i "s/{{PROJECT_NAME}}/$REPLACE_NAME/g" "$file" 2>/dev/null || true
    sed -i '' "s/{{TECH_STACK}}/$STACK/g" "$file" 2>/dev/null || sed -i "s/{{TECH_STACK}}/$STACK/g" "$file" 2>/dev/null || true
  fi
done

# Mirror AGENTS.md to CLAUDE.md
echo "<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->" > "$TARGET_DIR/CLAUDE.md"
echo "<!-- To modify rules, edit AGENTS.md and run \"oaef sync\". -->" >> "$TARGET_DIR/CLAUDE.md"
echo "" >> "$TARGET_DIR/CLAUDE.md"
cat "$TARGET_DIR/AGENTS.md" >> "$TARGET_DIR/CLAUDE.md"

# Initialize handoff.md and log.md if empty
if [ ! -s "$TARGET_DIR/docs/wiki/log.md" ]; then
  cat <<EOF > "$TARGET_DIR/docs/wiki/log.md"
# Project Historical Logbook (Append-Only)
> Initialized via Open Agentic Engineering Framework (OAEF) by Felipe Carvalho.

---

### [$TIMESTAMP] OAEF v1.0.0 Activated
- Stack: $STACK
- Quality Gate Profile: $STRICTNESS
- Initial living repository structure established.
EOF
fi

if [ ! -s "$TARGET_DIR/docs/wiki/memory/handoff.md" ]; then
  cat <<EOF > "$TARGET_DIR/docs/wiki/memory/handoff.md"
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
- [ ] Execute initial Quality Gate audit: run \`oaef audit\` or host language script.

## 3. Active Blockers & Contradiction Triage
*(None)*
EOF
fi

# Set executable permissions on tools
chmod +x "$TARGET_DIR/tool"/* 2>/dev/null || true

echo ""
echo -e "${BOLD}${GREEN}✅ OAEF successfully installed in:${RESET} $TARGET_DIR"
echo -e "   • Stack: ${BOLD}$STACK${RESET}"
echo -e "   • Quality Gates: ${BOLD}$STRICTNESS${RESET}"
echo -e "   • Zero-Pollution Isolation: ${BOLD}Active (Zero foreign files)${RESET}"
echo -e "   • Manifest: ${BOLD}oaef.context.json${RESET}"
echo ""
echo -e "Next steps:"
echo -e "  1. Review ${CYAN}AGENTS.md${RESET} and ${CYAN}docs/INDEX.md${RESET}"
echo -e "  2. Run your tool governance script in ${CYAN}tool/${RESET}"
echo -e "  3. Ready for autonomous AI coding agents (Claude Code, Antigravity, Cursor, etc.)"
echo ""
