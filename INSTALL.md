# OAEF Installation & Adoption Guide
> **Open Agentic Engineering Framework (OAEF)**
> **Author & Creator:** Felipe Carvalho
> **License:** Apache License 2.0 (Permits commercial use with attribution)
> **Target Audience:** Software Engineers, Tech Leads, and Autonomous AI Coding Agents

---

## Choose Your Installation Path

OAEF provides five zero-friction installation paths depending on your workflow:

| If you are... | Use this path | Command / Method |
| :--- | :--- | :--- |
| **A human developer at the terminal** | **Path 1: Interactive Discovery Wizard** | Run `./install.sh` or `oaef init` |
| **An autonomous AI agent in a CLI** | **Path 2: Non-Interactive Agent Flag** | Run `install.sh --target . --stack auto --strict` |
| **An AI agent in a chat IDE** (Claude Code, Codex, Cursor, Windsurf, OpenCode) | **Path 3: 1-Prompt Adoption Recipe** | Copy-paste `ADOPTION_PROMPT.md` into the chat |
| **An existing (legacy/brownfield) repository** | **Path 4: Legacy-Safe Adoption** | Run `install.sh --legacy --dry-run`, review, then apply |
| **An existing OAEF installation being upgraded** | **Path 5: Adoption & Upgrade** | Run `install.sh --legacy` or `install.sh --upgrade` |

---

## Path 1: The Interactive Discovery Wizard (For Humans)

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
   - `Install the 13 stack-tailored skills into .agents/skills/? [Y/n] (Default: Y)`

### What Happens Behind the Scenes:
- **Zero-Pollution Guarantee**: ONLY files for your selected language are copied. No stray templates or foreign language files are added.
- **Dynamic Context Pre-Population**: `AGENTS.md`, `CLAUDE.md`, `docs/INDEX.md`, `docs/MANIFESTO.md`, and `baseline.json` are generated with your project's real names and commands.
- **Context Manifest Emitted**: An `oaef.context.json` is generated, summarizing your technical DNA for instant AI ingestion.
- **Genesis Record**: The adoption is timestamped in `docs/wiki/log.md` and the initial state recorded in `docs/wiki/memory/handoff.md`.
- **Harness Skill Mirrors**: The 13 canonical skills installed in `.agents/skills/` are mirrored into `.claude/skills/`, `.cursor/rules/`, `.windsurf/skills/`, `.cline/skills/` and `.grok/agents/` so that every harness discovers them; rebuild them at any time with `oaef skills sync-mirrors` (disable with `--no-mirrors`).

---

## Path 2: Autonomous Agent One-Liner (Non-Interactive)

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
| `--legacy` | Adopt OAEF into an existing repository: advisory barriers, adoption ledger, measured coverage locked as the Monotonic Ratchet floor | Disabled |
| `--upgrade` | Upgrade an earlier OAEF installation in place (framework-owned files refreshed, user-owned content preserved) | Disabled |
| `--no-mirrors` | Do not create the harness skill mirrors (`.claude/skills`, `.cursor/rules`, ...) | Mirrors created |
| `--adopt-report` | (Re)generate the Adoption Debt Ledger even outside adoption mode | Disabled |
| `--ratchet-clean-code` | Lock the measured clean-code counts as the new baseline floors (adoption mode only) | Disabled |
| `--migrate-frontmatter` | Rewrite framework-owned skill frontmatter to the v1.1.0 format in place | Disabled |
| `--coverage <pct>` | Explicit measured line coverage for `--legacy` (overrides detection) | Auto-detected |
| `--dry-run` | Report every action without writing anything to disk | Disabled |
| `--backup` | Back up existing files to `.oaef/backup/<timestamp>/` before overwriting | Disabled |
| `--force` | Overwrite conflicting files (default: keep existing and propose `<file>.oaef-new`) | Disabled |
| `--no-skills` | Skip installing `.agents/skills/` | Skills installed by default |
| `--non-interactive` | Disable interactive prompts; use auto-detected defaults | Interactive if TTY |

---

## Path 3: The 1-Prompt Adoption Recipe (Chat & Agent IDEs)

If you are interacting with an AI coding assistant in a chat interface (Claude Code, Codex, OpenCode, Cursor Composer, Windsurf Cascade, Roo Code, ChatGPT, GitHub Copilot Chat):

1. Open a conversation with your agent inside your project workspace;
2. Copy the contents of [`ADOPTION_PROMPT.md`](ADOPTION_PROMPT.md);
3. Paste the prompt into the chat and press Enter.

The agent will execute an autonomous discovery phase, inspect your code, establish the OAEF directory structure, calibrate your baseline, and commit the initial living memory ledger.

---

## Path 4: Legacy-Safe Adoption (Existing / Brownfield Projects)

Applying OAEF to a repository that already has code, docs, or agent contracts is **non-destructive by default**. Framework-owned content is merged in place between section sentinels; user content outside the sentinels is never rewritten or deleted, and any file that cannot be merged deterministically is proposed as `<file>.oaef-new` for human review.

```bash
# 1. Preview every action without writing anything:
./install.sh --target /path/to/existing-project --stack auto --legacy --dry-run

# 2. Apply (framework sections merged; user content preserved; unresolved conflicts proposed as <file>.oaef-new):
./install.sh --target /path/to/existing-project --stack auto --legacy

# 3. Optional: review each proposal, merge what you want, then delete the .oaef-new files.
```

### Legacy Guarantees

- **Never overwrites by default**: `AGENTS.md`, `CLAUDE.md`, `docs/*`, `.github/*`, `CONTRIBUTING.md`, `SECURITY.md`, and `llms.txt` are preserved when they already exist; framework sections are merged between `<!-- oaef:section:* -->` sentinels and anything that cannot be merged is written as `<file>.oaef-new`.
- **Ratchet protected**: an existing `docs/wiki/metrics/baseline.json` is never reset; existing `handoff.md`/`log.md` memory is never wiped; an existing `oaef.context.json` is preserved.
- **User-owned `CLAUDE.md` respected**: the mirror is only regenerated when the file is absent or carries the OAEF `AUTO-GENERATED MIRROR` banner.
- **User-owned skills respected**: an existing skill whose name collides with a canonical skill is preserved; the proposed canonical version is written as `<skill>/SKILL.md.oaef-new`. Use `oaef skills audit --migrate-frontmatter` to upgrade only the frontmatter of an unmodified framework skill.
- **Interactive wizard** asks once when artifacts are detected: `[K]eep (default) / [B]ackup & overwrite / [A]bort`.
- **`--backup`** copies every overwritten file to `.oaef/backup/<timestamp>/`; **`--force`** opts into overwriting.
- **Measured legacy baseline**: with `--legacy`, OAEF measures the current coverage from existing artifacts — `lcov.info`, `coverage/coverage-summary.json`, `coverage.xml`, `TestResults/coverage.cobertura.xml`, or `build/reports/jacoco|kover/*.xml` — and locks lines/branches as the ratchet floor. If no artifact is found, conservative floors (50%/40%) apply and `--coverage <pct>` can supply the value explicitly. New `clean_code.*` floors are seeded with the counts measured at adoption time (an inventory, never a hard `0`), so legacy code is inventoried rather than blocked.
- **Adoption Debt Ledger**: in every adoption mode the `CC-*` barriers run advisory and their findings are inventoried in `docs/wiki/memory/adoption.md` and `docs/wiki/metrics/adoption.json`, together with missing skills, merge conflicts and a sizing table (files > 300 LOC, methods > 50 LOC).

---

## Path 5: Adopting in an Existing Repository & Upgrading an OAEF Installation

Paths 4 and 5 share the same non-destructive engine; Path 5 focuses on the two adoption modes and on the incremental upgrade of an earlier OAEF installation.

### 5.1 Section-Sentinel Merge Model

Framework-owned files are wrapped in HTML comment sentinels:

```text
<!-- oaef:section:<id> -->   ... framework-owned content ...   <!-- /oaef:section:<id> -->
```

- Content **inside** the markers is framework-owned and is replaced in place on `--upgrade` (or when a newer template ships).
- Content **outside** the markers is user-owned and is **never rewritten or deleted**.
- When a target has no sentinels (a hand-written `AGENTS.md`, an older OAEF install), the installer falls back to a heading-based merge: matching sections are prepended with the canonical block between `<!-- oaef:conflict:<id> -->` markers **without removing** the user's version, and the file is registered as a conflict. Only a non-deterministic merge (duplicated headings, invalid encoding) falls back to `<file>.oaef-new`, leaving the original untouched.

### 5.2 The `--dry-run` Plan Classes

Every path is classified before any write, and `--dry-run` prints the plan without touching disk:

| Class | Meaning |
| :--- | :--- |
| `install` | Target file does not exist; it is created. |
| `merge-additive` | Framework sections are added or updated in place; user content is preserved. |
| `merge-conflict` | A canonical section collides with user content; both are kept and the file is registered as a conflict. |
| `propose-oaef-new` | The merge is not deterministic; the new version is proposed as `<file>.oaef-new` and the original is preserved. |
| `preserve` | User-owned file; nothing is written. |

No plan class ever deletes a user file.

### 5.3 `--legacy` — Adopting an Existing Repository

```bash
# Preview the plan:
./install.sh --target . --stack auto --legacy --dry-run
# Apply:
./install.sh --target . --stack auto --legacy
# Or via the CLI:
oaef adopt --target . --stack auto
```

- **Advisory barriers**: every `CC-*` check enters advisory mode and its findings are inventoried in the Adoption Debt Ledger (`docs/wiki/memory/adoption.md`, `docs/wiki/metrics/adoption.json`). `CC-04` (hardcoded secrets) and `SK-05` (harness mirror divergence) stay blocking under every profile.
- **Coverage ratchet floor**: coverage measured from existing artifacts becomes the Monotonic Ratchet floor; quality may only increase.
- **Adoption Debt Ledger**: a generated report listing violations per check, file and line, plus a sizing table, the missing skills and the merge conflicts, and the recommended next steps.
- **User-owned skills preserved**: a colliding user skill is never overwritten; the canonical version is proposed as `<skill>/SKILL.md.oaef-new` and recorded. `oaef skills audit --migrate-frontmatter` upgrades the frontmatter of unmodified framework skills in place.
- **`--ratchet-clean-code`** optionally locks the measured clean-code counts as the new baseline floors once you accept the inventory.

### 5.4 `--upgrade` — Upgrading an Earlier OAEF Installation

Detected automatically when `oaef.context.json` exists with a `version` lower than `1.1.0`:

```bash
./install.sh --target . --stack auto --upgrade --dry-run
./install.sh --target . --stack auto --upgrade
# Or via the CLI:
oaef upgrade --target . --stack auto
```

- **Framework-owned files refreshed in place**: `AGENTS.md`, `CLAUDE.md`, `llms.txt`, `docs/standards/*`, `docs/INDEX.md` and the community files are updated inside their sentinels; user content outside the sentinels is preserved.
- **New skills added**: `ponytail` and `responsive-layout` are installed, alongside harness mirrors for every present harness directory.
- **New baseline keys merged without lowering existing floors**: new `clean_code.*` keys are added; a user floor that is already higher than the canonical value is kept.
- **Frontmatter migrated**: canonical skills whose body is unmodified are migrated to the v1.1.0 frontmatter format (`Use when`, `Triggers on:`, `Chains into:`, `metadata.version: 1.1.0`); modified skills are proposed as `.oaef-new`.
- **`--migrate-frontmatter`** forces the frontmatter migration step; `--no-mirrors` skips mirror creation; `--adopt-report` regenerates the Adoption Debt Ledger after the upgrade.
- **Idempotent**: running `--upgrade` twice produces no further diff.
- The installation keeps `adoption_mode: "upgrade"` and reports new barriers as advisory, with `--ratchet-clean-code` available to lock the accepted inventory as floors.

### 5.5 Adoption & Upgrade Flags

| Flag | Description |
| :--- | :--- |
| `--legacy` | Adopt into an existing repository: advisory barriers, measured coverage floor, Adoption Debt Ledger. |
| `--upgrade` | Upgrade an earlier OAEF installation in place, preserving user-owned content. |
| `--no-mirrors` | Do not create the harness skill mirrors. |
| `--adopt-report` | (Re)generate the Adoption Debt Ledger even outside adoption mode. |
| `--ratchet-clean-code` | Lock the measured clean-code counts as the new baseline floors (adoption mode only). |
| `--migrate-frontmatter` | Rewrite framework-owned skill frontmatter to the v1.1.0 format in place. |
| `--dry-run` | Print the plan (`install`, `merge-additive`, `merge-conflict`, `propose-oaef-new`, `preserve`) without writing. |

---

## The Zero-Pollution Guarantee (Target Isolation)

A common flaw in project templates is repository clutter. OAEF enforces strict isolation:

```text
Consuming Project (e.g. Dart/Flutter)
|-- .agents/skills/             <-- ONLY Dart/Flutter skills (13, no Go, Python, or Rust)
|-- tool/governance.dart         <-- ONLY Dart governance engine (no Node, Python, or shell)
|-- docs/wiki/metrics/baseline.json <-- Calibrated for Flutter test coverage
|-- AGENTS.md & CLAUDE.md       <-- Injected with ONLY Dart/Flutter rules & anti-suppressions
|-- .github/workflows/ci.yml    <-- Stack-tailored CI workflow
|-- .github/pull_request_template.md <-- Clean open-source PR template
|-- .github/ISSUE_TEMPLATE/     <-- Standard Bug, Feature, and ADR templates
|-- CONTRIBUTING.md & SECURITY.md <-- Project contribution standards
`-- oaef.context.json           <-- Declares stack: 'dart-flutter'
```

Zero template files (`.template`), zero unselected language runtimes, and zero unrelated examples ever enter your codebase. Every target project is 100% clean and native.

---

## Post-Installation Verification

Once installed, verify that your living repository is active and compliant:

```bash
# 1. Run the conformance audit (structure, mirror parity, skills, community files):
oaef doctor  # or: bash tool/governance.sh doctor / node tool/governance.mjs doctor

# 2. Run the unified agent sync (ensures AGENTS.md and CLAUDE.md match and rebuilds skill mirrors):
oaef sync    # or: dart run tool/governance.dart sync / python3 tool/governance.py sync

# 3. Audit link integrity, cascade references, secret scanning, clean code and skills:
oaef lint    # or: dart run tool/governance.dart lint / python3 tool/governance.py lint

# 4. Run the cross-language governance barriers:
oaef clean-code

# 5. Validate skill activation (parity, frontmatter, trigger coherence, mirrors, routing):
oaef skills audit --selftest

# 6. Execute the full Quality Gate audit:
oaef audit   # or: dart run tool/governance.dart quality-gate
```

### Command Reference (`oaef`)

| Command | Purpose |
| :--- | :--- |
| `oaef init` | Interactive discovery interview to bootstrap a repository. |
| `oaef adopt` | Adopt OAEF into an existing repository (`install.sh --legacy`). |
| `oaef upgrade` | Upgrade an earlier OAEF installation in place (`install.sh --upgrade`). |
| `oaef sync` | Synchronize `AGENTS.md` with `CLAUDE.md` and rebuild the harness skill mirrors. |
| `oaef lint` | Audit links, cascade references, secrets, suppressions, clean code and skills. |
| `oaef clean-code` | Run the `CC-*` governance barriers (`docs/standards/governance_checks.md`). |
| `oaef audit` | Execute the multidimensional Quality Gate audit. |
| `oaef doctor` | Audit OAEF conformance (structure, standards, skills, mirrors, self-test). |
| `oaef metrics` | Display the current baseline thresholds. |
| `oaef ponytail debt` | Report every `// ponytail:` debt marker (`PT-01`). |
| `oaef ponytail audit` | Advisory anti-slop audit (ceremonial layers, single-caller abstractions, narration comments). |
| `oaef skills audit [--selftest]` | Skill parity, frontmatter quality, entrypoint parity, trigger coherence, harness mirror parity; `--selftest` adds the routing fixture table (`SK-06`). |
| `oaef skills route "<prompt>"` | Resolve a prompt to its governing skill and chaining recipe. |
| `oaef skills sync-mirrors [--check]` | Rebuild (or validate without writing) the harness skill mirrors. |
| `oaef export` | Bundle OAEF into a clean release ZIP archive. |
| `oaef version` | Display the framework version. |

---

## Frequently Asked Questions (FAQ)

### Q: What if my project currently has low or zero test coverage?
**A:** Choose `[3] Legacy Onboarding` during the wizard (or use `--legacy`). OAEF reads your existing coverage artifacts (`lcov.info`, `coverage-summary.json`, `coverage.xml`, cobertura/jacoco reports), measures the current coverage (e.g. 23.4% lines / 18.1% branches) and locks it as your initial baseline floor. The **Monotonic Ratcheting Rule** ensures coverage can only go up, never down. If no coverage artifact exists, conservative floors (50%/40%) apply — pass `--coverage <pct>` to lock a known value explicitly.

### Q: Will OAEF overwrite my existing files?
**A:** **No.** The installer is legacy-safe by default: framework-owned sections are merged between `<!-- oaef:section:* -->` sentinels, and content outside the sentinels is never rewritten or deleted. Any file that cannot be merged deterministically is proposed as `<file>.oaef-new` for human review. `docs/wiki/metrics/baseline.json` (Monotonic Ratchet), `handoff.md`/`log.md` memory, and `oaef.context.json` are preserved. Use `--backup` to snapshot overwrites or `--force` to opt into replacing conflicts; `--dry-run` previews everything without writing.

### Q: How do I upgrade an earlier OAEF installation?
**A:** Run `oaef upgrade` (or `install.sh --upgrade`). Framework-owned files are refreshed in place, the new skills (`ponytail`, `responsive-layout`) and their harness mirrors are added, new `clean_code.*` baseline keys are merged without lowering existing floors, and unmodified framework skill frontmatter is migrated to v1.1.0. The upgrade is idempotent: running it twice produces no further diff.

### Q: Why do my skills not trigger in Claude Code, Cursor, Windsurf or Cline?
**A:** Those harnesses discover skills in their own directories. OAEF mirrors the canonical `.agents/skills/` catalog into `.claude/skills/`, `.cursor/rules/`, `.windsurf/skills/`, `.cline/skills/` and `.grok/agents/`. Rebuild them with `oaef skills sync-mirrors` and validate them with `oaef skills sync-mirrors --check` (audited as `SK-05`). Pass `--no-mirrors` to opt out.

### Q: Does OAEF require Docker or background services?
**A:** **No.** OAEF operates under the **Zero-Docker / Zero-Daemon** philosophy. All governance scripts run natively in the project's own programming language in milliseconds.

### Q: Can my team use multiple AI agents simultaneously?
**A:** **Yes.** `AGENTS.md` is the canonical root contract, consumed natively by Codex, OpenCode, Antigravity, Cursor, Pi, and 20+ harnesses. `oaef sync` keeps the `CLAUDE.md` mirror (Claude Code) in exact parity and rebuilds the harness skill mirrors, and the portable `.agents/skills/` catalog is auto-discovered by Codex, OpenCode, Antigravity, Cursor, Windsurf, Goose, and OpenHands. See [`docs/HARNESSES.md`](templates/base/docs/HARNESSES.md).
