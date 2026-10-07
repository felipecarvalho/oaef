# OAEF 1-Prompt Universal Adoption Recipe

> Copy and paste the prompt below into any AI coding assistant (Claude Code, Codex, OpenCode, Google Antigravity, Cursor Composer, Windsurf Cascade, Roo Code, GitHub Copilot Chat) inside your project's root directory.

---

```markdown
You are an expert software engineer and autonomous agent instructed to adopt the **Open Agentic Engineering Framework (OAEF)** in this repository, authored by Felipe Carvalho.

Follow this systematic 5-phase procedure:

### Phase 0: Existing (Legacy) Repository Discovery
If the repository already contains code, docs, or agent contracts:
1. Run the legacy-safe discovery first: `./install.sh --target . --stack auto --legacy --dry-run` (or `oaef init --legacy --dry-run`).
2. Review the plan: every path is classified as `install`, `merge-additive`, `merge-conflict`, `propose-oaef-new` or `preserve`. Framework-owned content between `<!-- oaef:section:* -->` sentinels is merged in place; content outside the sentinels is never rewritten or deleted. Unresolved conflicts are proposed as `<file>.oaef-new`. NEVER overwrite a human-authored contract without explicit approval; prefer `--backup` over `--force`.
3. With `--legacy`, coverage measured from existing artifacts (lcov/cobertura/jacoco/coverlet) is locked as the Monotonic Ratchet floor — quality may only increase. The `CC-*` barriers run advisory and their findings are inventoried in the Adoption Debt Ledger (`docs/wiki/memory/adoption.md`).

### Phase 1: Architectural Discovery & Stack Inspection
1. Inspect the repository root to detect the primary technology stack, package manager, and test runner:
   - Dart/Flutter (`pubspec.yaml`)
   - TypeScript/JavaScript (`package.json`, `tsconfig.json`)
   - Python (`pyproject.toml`, `requirements.txt`)
   - Go (`go.mod`)
   - Rust (`Cargo.toml`)
   - Kotlin/Java (`build.gradle*`, `pom.xml`)
   - Swift (`Package.swift`, `*.xcodeproj`)
   - C# / .NET (`*.csproj`, `*.sln`)
   - Universal (Other)
2. Detect the existing test coverage and linting configuration. If test coverage currently exists, measure it; if not, note that the baseline will initialize in Legacy Onboarding mode.
3. Emit a concise JSON context summary to `oaef.context.json` containing: `version`, `project_name`, `stack`, `archetype`, and `test_runner`.

### Phase 2: Establish the Canonical Rules & Trust Hierarchy
Create the root governance files:
1. `AGENTS.md`: The canonical contract incorporating:
   - The Inviolable Trust Hierarchy: Compiler/Typechecker > Automated Tests > Source Code > Wiki/Docs > Ephemeral Memory > LLM Hallucination.
   - The 5 Pillars of OAEF (Context Engineering, Spec-Driven Development, Multidimensional Quality Gates, Zero-Docker Living Memory, Minimalism & Design Integrity).
   - The **Simplicity Ladder (the Ponytail Ladder)**: YAGNI > Reuse in codebase > Language/stdlib primitives > Platform-native capability > Already-installed dependency > One-line idiomatic expression > Smallest correct diff. Zero tolerance for AI slop and speculative abstraction.
   - The **SOLID Principles**: single responsibility, segregated contracts, dependency inversion and strict substitutability, with the mechanical barriers that enforce them.
   - Agent Autonomy Matrix and Contradiction Triage Protocol.
   - Strict Clean Sizing bounds (<=300 LOC per file, <=50 LOC per method/function).
   - Ban on `// ignore:` and unallowed linter suppressions.
   - The project's actual build, test, and lint commands.
2. `CLAUDE.md`: Exact synchronized mirror of `AGENTS.md` with protection banner.
3. `llms.txt`: Canonical machine-readable entry point documenting the project structure.

### Phase 3: Zero-Pollution Directory Scaffolding
Create the living repository documentation tree under `docs/`:
- `docs/INDEX.md`: OKF task-based context routing table mapping developer tasks to exact file paths.
- `docs/MANIFESTO.md`: Dual-audience charter (Business ROI & Technical Architecture).
- `docs/DESIGN.md`: Design System tokens and UI boundaries (if UI project) or API schema standards.
- `docs/standards/coding_patterns.md`: Idiomatic coding standards for the detected stack (non-nullable collections, service-locator confinement, DRY test factories, Solution Abstraction Elevation / Rule of Two, skill chaining recipes).
- `docs/standards/testing.md`: Testing guidelines (unit, widget/integration, mocks, branch coverage, DRY `make*` test factories).
- `docs/standards/logging.md`: Structured logging standards (severity mapping, debug-only, no console pollution, zero PII in production).
- `docs/standards/clean_code.md`: Zero-tolerance clean-code principles (meaningful names, immutability & injection, non-nullable collections, service-locator confinement, zero silent exception swallowing, memory/GC discipline, anti-AI-slop and the Ponytail Ladder).
- `docs/standards/solid.md`: SOLID fundamentals with pragmatic application and the SOLID x Ponytail balance (Rule of Two).
- `docs/standards/review.md`: Review standard (severity taxonomy, actionable suggestions, holistic pattern remediation, pre-review canonical truth ingestion).
- `docs/standards/analytics_and_telemetry.md`: Provider abstraction contract, dual event taxonomy, consent gate, PII sanitizer contract and logger injection.
- `docs/standards/governance_checks.md`: Normative cross-language governance catalog (`CC-*`, `SK-*`, `PT-01`), canonical messages and the routing self-test fixture table.
- `docs/adr/0001-record-architecture-decisions.md`: Initial ADR establishing OAEF adoption.
- `docs/bdd/`: Folder for Gherkin `.feature` specifications.
- `docs/wiki/metrics/baseline.json`: Mathematical thresholds (Line coverage, Branch coverage, Clean sizing limits, Duplication <=3%, and the `clean_code.*` barriers).
- `docs/wiki/memory/handoff.md`: Active session memory ledger with Concurrency Shield frontmatter.
- `docs/wiki/log.md`: Append-only historical log with the genesis entry timestamped.
- `.github/pull_request_template.md`: PR template with automation tags and zero empty checkboxes rule.
- `docs/HARNESSES.md`: Verified agent harness compatibility matrix (August 2026) and OAEF integration status.

CRITICAL ZERO-POLLUTION RULE: Install ONLY documentation and scripts relevant to this project's stack. Do NOT add files or skills from unrelated programming languages.

### Phase 4: Stack-Adaptive Agent Skills
Install the 13 canonical agent skills into `.agents/skills/`, tailored strictly to the detected language, and mirror them into every present harness directory (`.claude/skills/`, `.cursor/rules/`, `.windsurf/skills/`, `.cline/skills/`, `.grok/agents/`):
1. `ponytail`: Simplicity Ladder, anti-AI-slop and root-cause remediation (the meta-skill governing every task).
2. `screen-builder`: Vertical feature/screen/flow module implementation with Clean Sizing.
3. `component-author` / `module-author`: Idiomatic reusable component/schema authoring rules.
4. `responsive-layout`: Adaptive layouts, breakpoints and safe areas (or adaptive surface design for non-UI stacks).
5. `ui-preview`: Isolated preview rules (or Swagger/OpenAPI for APIs).
6. `fix-layout-issues`: UI layout or API schema error debugging.
7. `nullable-types`: Idiomatic null-safety and defensive programming patterns for this language.
8. `test-generator`: Instructions using the project's actual test framework (95% line, 90% branch coverage target).
9. `collect-coverage`: Native coverage collection and LCOV parsing instructions.
10. `run-static-analysis`: Strict static analysis (`--fatal-infos` or equivalent) and auto-fix rules.
11. `architecture-audit`: Architectural boundaries and cyclic dependency audit.
12. `code-review`: Pre-PR self-audit checklist, severity taxonomy and Quality Gate verification.
13. `conformance-audit`: Repository conformance audit (`oaef doctor`) — structure, standards, skills, mirrors, and community files.

### Phase 5: Verification & Genesis Record
1. Run static analysis on the repository to verify zero warnings.
2. Execute the test suite and calculate the initial baseline coverage.
3. Run the conformance and governance audits; resolve every failure before declaring success:
   - `oaef doctor`
   - `oaef lint`
   - `oaef clean-code`
   - `oaef skills audit --selftest`
   - `oaef skills sync-mirrors`
4. Record the initial session state in `docs/wiki/memory/handoff.md` and append the Genesis entry in `docs/wiki/log.md`.
5. Present a clear summary of the newly activated Living Repository to the user.
```
