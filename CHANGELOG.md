# Changelog

All notable changes to the **Open Agentic Engineering Framework (OAEF)** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- **Agent Harness Compatibility Matrix (August 2026)**: new `docs/HARNESSES.md` with the verified Tier 1–3 harness landscape (Claude Code, Codex, OpenCode, Antigravity, Cursor, Pi, and 20+ more), instruction-file and skills support, and OAEF integration status.
- **OpenCode native support**: OpenCode consumes `AGENTS.md` directly and auto-discovers `.agents/skills/`, requiring no mirror file.
- Harness highlights added to `README.md`, `SPECIFICATION.md`, `INSTALL.md`, `ADOPTION_PROMPT.md`, `MANIFESTO.md`, and the installer output.

### Changed
- Mirror synchronization documentation aligned with current behavior: `oaef sync` generates the `CLAUDE.md` mirror; `AGENTS.md`-native harnesses require no mirror.
- Gemini CLI references replaced by its successor, Antigravity CLI (`agy`), retired for personal accounts on 18 June 2026.

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
