# Changelog

All notable changes to the **Open Agentic Engineering Framework (OAEF)** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.1] - 2026-10-07

### Fixed
- **Kotlin dispatch-matrix parsing (`SK-04`)**: `matrixRows()` read the wrong columns because Kotlin's
  `String.split` drops trailing empty strings, so a five-column row yields six cells and the Meta-Skill
  column was parsed as the primary skill. Twelve of the thirteen skills were reported as having no matrix
  row. Indices corrected (`cells[3]` triggers, `cells[4]` primary) with a defensive separator-row skip and
  per-keyword trigger reporting.
- **`kotlinc -script` flag handling**: the Kotlin compiler consumes leading-dash arguments before the
  script, so `skills-audit --selftest` and `clean-code --standard` failed with
  `error: invalid argument: --selftest`. The command line now travels through `OAEF_GOVERNANCE_ARGS` from
  `bin/oaef` and `scripts/self-audit.sh`, while direct invocation keeps working through the script `args`.

### Changed
- **Attribution**: the Simplicity Ladder is credited to **Dietrich Gebert — Ponytail minimalism** not only in
  `README.md` but also in `NOTICE` (which every distribution must retain), in both `MANIFESTO.md` files and in
  the twelve `ponytail` skills, so the credit travels into every installed repository. `NOTICE` also moved
  from "4 Pillars" to "5 Pillars" and names SOLID explicitly.

> Verification: the framework self-audit passes for all 12 stacks, and the GitHub Actions matrix — which runs
> `doctor`, `lint`, `clean-code`, `skills audit --selftest` and `clean-code --standard` on every stack, Kotlin
> and .NET included — is green.

## [1.1.0] - 2026-10-06

### Added
- **Cross-language governance barriers (`CC-01`–`CC-11`)**: every one of the 12 native runtimes now implements the same clean-code check catalog — identifier discipline, mutable lazy initialization, hardcoded placeholders, raw debug output, silent exception swallowing, service-locator leakage, nullable collections, unimplemented placeholders, concrete network-client instantiation and avoidable allocation — with the identical output contract `<CHECK-ID> <path>:<line> — <message>` and the identical canonical messages.
- **`docs/standards/governance_checks.md`**: the normative catalog of every mechanical barrier, its scope, exclusion set, per-stack realization and canonical messages.
- **13-skill catalog**: `ponytail` (Simplicity Ladder, anti-AI-slop, debt markers) and `responsive-layout` (adaptive surfaces, reinterpreted per stack) join the 11 existing skills in every stack; all 156 `SKILL.md` files carry the saturated frontmatter (`Use when` / `Triggers on:` / `Chains into:`).
- **Skill activation is now verifiable**: harness mirrors (`.claude/skills/`, `.cursor/rules/`, `.windsurf/skills/`, `.cline/skills/`, `.grok/agents/`), dispatch-matrix coherence (`SK-04`), harness mirror parity (`SK-05`) and a routing self-test with 12 prompt fixtures (`SK-06`), plus `oaef skills route "<prompt>"` and `oaef skills sync-mirrors [--check]`.
- **Non-destructive adoption and in-place upgrade**: section sentinels (`<!-- oaef:section:* -->`) make merges surgical; `oaef adopt` (`--legacy`) and `oaef upgrade` reuse existing content, add new skills and standards, and record every advisory barrier in the Adoption Debt Ledger (`docs/wiki/memory/adoption.md`, `docs/wiki/metrics/adoption.json`).
- **New canonical standards**: `clean_code.md`, `solid.md`, `review.md`, `analytics_and_telemetry.md`, and a fifth pillar — Minimalism & Design Integrity (Simplicity Ladder + SOLID).
- **New commands**: `oaef clean-code`, `oaef ponytail debt`, `oaef ponytail audit`, `oaef skills audit [--selftest]`, `oaef skills route`, `oaef skills sync-mirrors`, `oaef adopt`, `oaef upgrade`.
- **Installer flags**: `--upgrade`, `--no-mirrors`, `--adopt-report`, `--ratchet-clean-code`, `--migrate-frontmatter`; `--dry-run` now classifies every destination as `install`, `merge-additive`, `merge-conflict`, `propose-oaef-new` or `preserve`.
- **`examples/legacy-sample/`**: a pre-framework fixture proving non-destructive adoption, upgrade idempotence and ledger generation.

### Changed
- `AGENTS.md`/`CLAUDE.md` contract: `§3` now documents the 13 skills, the five chaining recipes, the dispatch matrix and the territorial scopes; `§4.7`–`§4.19` add the Simplicity Ladder, SOLID and substitutability, DI confinement, non-nullable collections, two-layer resilience, DRY test factories, Rule of Two elevation, native dependency audit, allocation discipline, privacy by design, the Phase-0 dispatch gate and pre-review ingestion.
- Every `templates/rules/<stack>/rules.md` and `templates/ci/<stack>/ci.yml` gained the new governance steps; `baseline.json` gained the `clean_code` and `simplicity` blocks and moved to `1.1.0`.
- `docs/HARNESSES.md`, `docs/INDEX.md`, `llms.txt`, the pull-request template and the manifestos now describe 13 skills, the mirrors and the governance checks.

### Fixed
- Skill mirrors are created with the correct relative target (`../.agents/skills`) and dangling or diverged mirrors are now detected instead of silently passing parity.
- The committed `__pycache__` artifact was removed from the Python runtime template.
- Profile handling: `--standard` and adoption modes degrade the new barriers to advisory instead of failing the gate; `CC-04` and `SK-05` remain blocking under every profile.

## [Unreleased]

### Added
- **Agent Harness Compatibility Matrix (August 2026)**: new `docs/HARNESSES.md` with the verified Tier 1–3 harness landscape (Claude Code, Codex, OpenCode, Antigravity, Cursor, Pi, and 20+ more), instruction-file and skills support, and OAEF integration status.
- **OpenCode native support**: OpenCode consumes `AGENTS.md` directly and auto-discovers `.agents/skills/`, requiring no mirror file.
- **Legacy-safe adoption (Path 4)**: `install.sh` never overwrites existing files by default; conflicts are proposed as `<file>.oaef-new`, with `--dry-run`, `--backup`, `--force`, and `--coverage <pct>` flags, and a conflict strategy prompt in the wizard.
- **Measured legacy baseline**: `--legacy` reads existing coverage artifacts (lcov, coverage-summary.json, cobertura, jacoco/kover) and locks the measured lines/branches as the Monotonic Ratchet floor.
- **`oaef doctor` conformance audit**: new `conform|doctor` command in all 12 stack runtimes verifying structure, mirror parity, the 11 skills, the governance runtime, and community files; exposed as `bin/oaef doctor|conform` alongside `bin/oaef metrics`.
- **Framework self-audit**: `scripts/self-audit.sh` plus a 12-stack GitHub Actions matrix workflow that installs each stack in a sandbox and runs doctor + lint.
- **`conformance-audit` skill (11th)**: repository conformance instructions for every stack; `code-review` and `architecture-audit` now include a Repository Conformance Gate.
- **AI agent instructions (§9)**: AGENTS.md/CLAUDE.md contract section covering legacy adoption, `oaef doctor/audit/lint/metrics`, and the failure protocol; adoption guidance added to `ADOPTION_PROMPT.md` (Phase 0) and `docs/INDEX.md`.
- Harness highlights added to `README.md`, `SPECIFICATION.md`, `INSTALL.md`, `ADOPTION_PROMPT.md`, `MANIFESTO.md`, and the installer output.

### Changed
- Mirror synchronization documentation aligned with current behavior: `oaef sync` generates the `CLAUDE.md` mirror; `AGENTS.md`-native harnesses require no mirror.
- Gemini CLI references replaced by its successor, Antigravity CLI (`agy`), retired for personal accounts on 18 June 2026.
- The portable CLI (`bin/oaef`) is now installed into target projects so the documented `./bin/oaef doctor|lint|audit|sync|metrics` commands work out of the box.

### Fixed
- Stack runtime mapping: `dart-flutter` and `typescript-web` now install their native governance engines (`governance.dart`, `governance.mjs`) instead of silently falling back to the shell engine.
- Mirror parity checks in the Node, Python, Go, Rust, Dart, Kotlin, Swift, and C# runtimes now ignore the generated banner and detect real divergence.
- Installer hydration no longer rewrites literal `{{...}}` patterns inside governance runtimes, and preserved legacy files are never modified.

---

## [1.0.0] - 2026-09-30

### Initial Release — Created by Felipe Carvalho

#### Core Architecture & Standards
- **The Inviolable Trust Hierarchy**: Formal mathematical formulation ($\mathbf{Compiler} > \mathbf{Tests} > \mathbf{Source} > \mathbf{Docs} > \mathbf{Memory} > \mathbf{Hallucination}$).
- **The 4 Pillars of Agentic Software Engineering**:
  1. Context Engineering (Google OKF + Karpathy LLM Wiki + `/llms.txt`).
  2. Spec-Driven Development (BDD Gherkin + Design System specs + Typed contracts).
  3. Multidimensional Quality Gates (95% lines / 90% branches coverage, Clean Sizing <=300L/50L, 0 unallowed ignores).
  4. Zero-Docker / Zero-Daemon Living Memory (`handoff.md` + `log.md`).
- **Autonomous Agent Contract**: Formalized in `AGENTS.md` and mirrored to `CLAUDE.md`, `.cursorrules`, `.windsurfrules`, and `.github/copilot-instructions.md`.
- **Anti-Hallucination Contradiction Protocol**: Strictly forbids silent resolution of contradictions by AI agents.

#### Tooling & Developer Experience
- **Interactive Context Discovery Interview**: CLI wizard (`install.sh` / `bin/oaef`) with 6-step questionnaire and auto-detection.
- **Stack-Adaptive Agent Skills**: 10 specialized, idiomatic skills across 8 ecosystems:
  - Dart / Flutter
  - TypeScript / JavaScript (Node, React, Next.js)
  - Python (FastAPI, Pytest)
  - Go (Golang)
  - Rust
  - Kotlin / Java
  - Swift
  - C# / .NET
  - Universal POSIX
- **Zero-Pollution Target Isolation**: Consuming projects receive strictly the skills and tooling for their chosen stack, with zero clutter from unselected languages.
- **Standalone Governance Engines**: Native scripts for Dart, Node.js, Python, Go, Rust, Kotlin, Swift, C#, and POSIX Shell.
- **Secret & PII Guard**: Automated regex scanner blocking accidental token/credential leaks into living memory.
- **Monotonic Quality Ratchet**: Automatically ratchets coverage baseline upwards when new tests are added.
- **One-Click Bundler**: `bundle.sh` script generating clean `.zip` releases with SHA-256 checksums.
