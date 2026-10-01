# OAEF Installation & Adoption Guide
> **Open Agentic Engineering Framework (OAEF)**  
> **Author & Creator:** Felipe Carvalho  
> **License:** Apache License 2.0 (Permits commercial use with attribution)  
> **Target Audience:** Software Engineers, Tech Leads, and Autonomous AI Coding Agents

---

## 🧭 Choose Your Installation Path

OAEF provides four zero-friction installation paths depending on your workflow:

| If you are... | Use this path | Command / Method |
| :--- | :--- | :--- |
| **A human developer at the terminal** | **Path 1: Interactive Discovery Wizard** | Run `./install.sh` or `oaef init` |
| **An autonomous AI agent in a CLI** | **Path 2: Non-Interactive Agent Flag** | Run `install.sh --target . --stack auto --strict` |
| **An AI agent in a chat IDE** (Claude Code, Codex, Cursor, Windsurf, OpenCode) | **Path 3: 1-Prompt Adoption Recipe** | Copy-paste `ADOPTION_PROMPT.md` into the chat |
| **An existing (legacy/brownfield) repository** | **Path 4: Legacy-Safe Adoption** | Run `install.sh --legacy --dry-run`, review, then apply |

---

## 🚀 Path 1: The Interactive Discovery Wizard (For Humans)

The interactive wizard guides you through a 6-step architectural discovery interview. It auto-detects your existing project files and tailors all initial documentation, metrics, and agent contracts.

### Step 1: Run the Installer
From inside the cloned or unzipped OAEF directory:
```bash
./install.sh
```
*(Or specify an external target project: `./install.sh --target /path/to/my-project`)*

### Step 2: The 6-Step Discovery Interview
The wizard will prompt you with intelligent defaults:

1. **Target Directory**:
   - `Where should OAEF be installed? [Default: .]`
2. **Project Identity**:
   - `Project Name: [Auto-detected from folder name]`
   - `Short Description / Purpose: [e.g. High-throughput payments processing API]`
3. **Tech Stack & Ecosystem**:
   The installer inspects your root directory and automatically suggests your stack:
   - `[1] Dart / Flutter` (Triggered if `pubspec.yaml` exists)
   - `[2] React Native` (Triggered if `package.json` with `"react-native"` exists)
   - `[3] Expo` (Triggered if `app.json` or `package.json` with `"expo"` exists)
   - `[4] TypeScript / Web` (Triggered if `package.json` exists)
   - `[5] Kotlin Multiplatform (KMP)` (Triggered if `build.gradle.kts` with `multiplatform` plugin or `commonMain/` exists)
   - `[6] Kotlin / Android` (Triggered if `build.gradle*` exists)
   - `[7] Python` (Triggered if `pyproject.toml` or `requirements.txt` exists)
   - `[8] Go (Golang)` (Triggered if `go.mod` exists)
   - `[9] Rust` (Triggered if `Cargo.toml` exists)
   - `[10] Swift / iOS` (Triggered if `Package.swift` or `*.xcodeproj` exists)
   - `[11] C# / .NET` (Triggered if `*.csproj` or `*.sln` exists)
   - `[12] Universal / Polyglot` (Generic POSIX fallback)
4. **Project Archetype**:
   - `[1] Mobile App  [2] Web App  [3] Backend API  [4] CLI Tool  [5] Monorepo  [6] Library/SDK`
5. **Quality Gate Strictness Level**:
   - `[1] Strict (Recommended)`: 95% line coverage, 90% branches, clean sizing (<=300 LOC/file, <=50 LOC/method), zero lint warnings/unallowed ignores.
   - `[2] Standard`: 80% line coverage, 75% branches, clean sizing (<=400 LOC/file).
   - `[3] Legacy Onboarding`: Sets baseline thresholds equal to current project metrics, locking in a monotonic ratcheting rule (quality can only increase, never decrease).
6. **Install Stack-Adaptive Agent Skills**:
   - `Install the 11 stack-tailored skills into .agents/skills/? [Y/n] (Default: Y)`

### What Happens Behind the Scenes:
- **Zero-Pollution Guarantee**: ONLY files for your selected language are copied. No stray templates or foreign language files are added.
- **Dynamic Context Pre-Population**: `AGENTS.md`, `CLAUDE.md`, `docs/INDEX.md`, `docs/MANIFESTO.md`, and `baseline.json` are generated with your project's real names and commands.
- **Context Manifest Emitted**: An `oaef.context.json` is generated, summarizing your technical DNA for instant AI ingestion.
- **Genesis Record**: The adoption is timestamped in `docs/wiki/log.md` and the initial state recorded in `docs/wiki/memory/handoff.md`.

---

## 🤖 Path 2: Autonomous Agent One-Liner (Non-Interactive)

Autonomous agents (e.g. Claude Code, Codex, OpenCode, Google Antigravity, Cursor Background Agents) can bootstrap any repository in under 2 seconds without user input:

```bash
# From within the OAEF directory (or specify /path/to/oaef/install.sh):
./install.sh --target /path/to/my-project --stack auto --strict --non-interactive

# Or using the oaef CLI directly:
oaef init --target /path/to/my-project --stack auto --strict --non-interactive
```

### Supported CLI Flags:
| Flag | Description | Default |
| :--- | :--- | :--- |
| `--target <path>` | Target directory to initialize | Current working directory (`.`) |
| `--stack <name>` | Explicit stack: `dart-flutter`, `react-native`, `expo`, `typescript-web`, `kotlin-multiplatform`, `kotlin`, `python`, `go`, `rust`, `swift`, `dotnet`, `universal`, or `auto` | `auto` |
| `--strict` | Apply strict 95%/90% mathematical Quality Gates | Enabled |
| `--standard` | Apply standard 80%/75% Quality Gates | Disabled |
| `--legacy` | Measure current coverage and lock it as the Monotonic Ratchet floor | Disabled |
| `--coverage <pct>` | Explicit measured line coverage for `--legacy` (overrides detection) | Auto-detected |
| `--dry-run` | Report every action without writing anything to disk | Disabled |
| `--backup` | Back up existing files to `.oaef/backup/<timestamp>/` before overwriting | Disabled |
| `--force` | Overwrite conflicting files (default: keep existing and propose `<file>.oaef-new`) | Disabled |
| `--no-skills` | Skip installing `.agents/skills/` | Skills installed by default |
| `--non-interactive` | Disable interactive prompts; use auto-detected defaults | Interactive if TTY |

---

## 💬 Path 3: The 1-Prompt Adoption Recipe (Chat & Agent IDEs)

If you are interacting with an AI coding assistant in a chat interface (Claude Code, Codex, OpenCode, Cursor Composer, Windsurf Cascade, Roo Code, ChatGPT, GitHub Copilot Chat):

1. Open a conversation with your agent inside your project workspace;
2. Copy the contents of [`ADOPTION_PROMPT.md`](ADOPTION_PROMPT.md);
3. Paste the prompt into the chat and press Enter.

The agent will execute an autonomous discovery phase, inspect your code, establish the OAEF directory structure, calibrate your baseline, and commit the initial living memory ledger.

---

## 🏗️ Path 4: Legacy-Safe Adoption (Existing / Brownfield Projects)

Applying OAEF to a repository that already has code, docs, or agent contracts is **non-destructive by default**. Existing files are never overwritten; conflicts are preserved and proposed for human review.

```bash
# 1. Preview every action without writing anything:
./install.sh --target /path/to/existing-project --stack auto --legacy --dry-run

# 2. Apply (existing files preserved; conflicts proposed as <file>.oaef-new):
./install.sh --target /path/to/existing-project --stack auto --legacy

# 3. Optional: review each proposal, merge what you want, then delete the .oaef-new files.
```

### Legacy Guarantees

- **Never overwrites by default**: `AGENTS.md`, `CLAUDE.md`, `docs/*`, `.github/*`, `CONTRIBUTING.md`, `SECURITY.md`, and `llms.txt` are preserved when they already exist; differing versions are written as `<file>.oaef-new`.
- **Ratchet protected**: an existing `docs/wiki/metrics/baseline.json` is never reset; existing `handoff.md`/`log.md` memory is never wiped; an existing `oaef.context.json` is preserved.
- **User-owned `CLAUDE.md` respected**: the mirror is only regenerated when the file is absent or carries the OAEF `AUTO-GENERATED MIRROR` banner.
- **Interactive wizard** asks once when artifacts are detected: `[K]eep (default) / [B]ackup & overwrite / [A]bort`.
- **`--backup`** copies every overwritten file to `.oaef/backup/<timestamp>/`; **`--force`** opts into overwriting.
- **Measured legacy baseline**: with `--legacy`, OAEF measures the current coverage from existing artifacts — `lcov.info`, `coverage/coverage-summary.json`, `coverage.xml`, `TestResults/coverage.cobertura.xml`, or `build/reports/jacoco|kover/*.xml` — and locks lines/branches as the ratchet floor. If no artifact is found, conservative floors (50%/40%) apply and `--coverage <pct>` can supply the value explicitly.

---

## 🧹 The Zero-Pollution Guarantee (Target Isolation)

A common flaw in project templates is repository clutter. OAEF enforces strict isolation:

```text
Consuming Project (e.g. Dart/Flutter)
├── .agents/skills/             <-- ONLY Dart/Flutter skills (no Go, Python, or Rust)
├── tool/governance.dart         <-- ONLY Dart governance engine (no Node, Python, or shell)
├── docs/wiki/metrics/baseline.json <-- Calibrated for Flutter test coverage
├── AGENTS.md & CLAUDE.md       <-- Injected with ONLY Dart/Flutter rules & anti-suppressions
├── .github/workflows/ci.yml    <-- Stack-tailored CI workflow
├── .github/pull_request_template.md <-- Clean open-source PR template
├── .github/ISSUE_TEMPLATE/     <-- Standard Bug, Feature, and ADR templates
├── CONTRIBUTING.md & SECURITY.md <-- Project contribution standards
└── oaef.context.json           <-- Declares stack: 'dart-flutter'
```

Zero template files (`.template`), zero unselected language runtimes, and zero unrelated examples ever enter your codebase. Every target project is 100% clean and native.

---

## ✅ Post-Installation Verification

Once installed, verify that your living repository is active and compliant:

```bash
# 1. Run the conformance audit (structure, mirror parity, skills, community files):
oaef doctor  # or: bash tool/governance.sh doctor / node tool/governance.mjs doctor

# 2. Run the unified agent sync (ensures AGENTS.md and CLAUDE.md match):
oaef sync    # or: dart run tool/governance.dart sync / python3 tool/governance.py sync

# 3. Audit link integrity, cascade references, and secret scanning:
oaef lint    # or: dart run tool/governance.dart lint / python3 tool/governance.py lint

# 4. Execute the full Quality Gate audit:
oaef audit   # or: dart run tool/governance.dart quality-gate
```

---

## ❓ Frequently Asked Questions (FAQ)

### Q: What if my project currently has low or zero test coverage?
**A:** Choose `[3] Legacy Onboarding` during the wizard (or use `--legacy`). OAEF reads your existing coverage artifacts (`lcov.info`, `coverage-summary.json`, `coverage.xml`, cobertura/jacoco reports), measures the current coverage (e.g. 23.4% lines / 18.1% branches) and locks it as your initial baseline floor. The **Monotonic Ratcheting Rule** ensures coverage can only go up, never down. If no coverage artifact exists, conservative floors (50%/40%) apply — pass `--coverage <pct>` to lock a known value explicitly.

### Q: Will OAEF overwrite my existing files?
**A:** **No.** The installer is legacy-safe by default: existing files are never modified, and any differing OAEF artifact is proposed as `<file>.oaef-new` for human review. `docs/wiki/metrics/baseline.json` (Monotonic Ratchet), `handoff.md`/`log.md` memory, and `oaef.context.json` are preserved. Use `--backup` to snapshot overwrites or `--force` to opt into replacing conflicts; `--dry-run` previews everything without writing.

### Q: Does OAEF require Docker or background services?
**A:** **No.** OAEF operates under the **Zero-Docker / Zero-Daemon** philosophy. All governance scripts run natively in the project's own programming language in milliseconds.

### Q: Can my team use multiple AI agents simultaneously?
**A:** **Yes.** `AGENTS.md` is the canonical root contract, consumed natively by Codex, OpenCode, Antigravity, Cursor, Pi, and 20+ harnesses. `oaef sync` keeps the `CLAUDE.md` mirror (Claude Code) in exact parity, and the portable `.agents/skills/` catalog is auto-discovered by Codex, OpenCode, Antigravity, Cursor, Windsurf, Goose, and OpenHands. See [`docs/HARNESSES.md`](templates/base/docs/HARNESSES.md).
