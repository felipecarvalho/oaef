# OAEF 1-Prompt Universal Adoption Recipe

> Copy and paste the prompt below into any AI coding assistant (Claude Code, Codex, OpenCode, Google Antigravity, Cursor Composer, Windsurf Cascade, Roo Code, GitHub Copilot Chat) inside your project's root directory.

---

```markdown
You are an expert software engineer and autonomous agent instructed to adopt the **Open Agentic Engineering Framework (OAEF)** in this repository, authored by Felipe Carvalho.

Follow this systematic 5-phase procedure:

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
   - The 4 Pillars of OAEF (Context Engineering, Spec-Driven Development, Multidimensional Quality Gates, Zero-Docker Living Memory).
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
- `docs/standards/coding_patterns.md`: Idiomatic coding standards for the detected stack.
- `docs/standards/testing.md`: Testing guidelines (unit, widget/integration, mocks, branch coverage).
- `docs/standards/logging.md`: Structured logging standards (debug-only, no console pollution in production).
- `docs/adr/0001-record-architecture-decisions.md`: Initial ADR establishing OAEF adoption.
- `docs/bdd/`: Folder for Gherkin `.feature` specifications.
- `docs/wiki/metrics/baseline.json`: Mathematical thresholds (Line coverage, Branch coverage, Clean sizing limits, Duplication <=3%).
- `docs/wiki/memory/handoff.md`: Active session memory ledger with Concurrency Shield frontmatter.
- `docs/wiki/log.md`: Append-only historical log with the genesis entry timestamped.
- `.github/pull_request_template.md`: PR template with automation tags and zero empty checkboxes rule.
- `docs/HARNESSES.md`: Verified agent harness compatibility matrix (August 2026) and OAEF integration status.

CRITICAL ZERO-POLLUTION RULE: Install ONLY documentation and scripts relevant to this project's stack. Do NOT add files or skills from unrelated programming languages.

### Phase 4: Stack-Adaptive Agent Skills
Install the 10 canonical agent skills into `.agents/skills/` tailored strictly to the detected language:
1. `test-generator`: Instructions using the project's actual test framework (95% line, 90% branch coverage target).
2. `code-review`: Pre-PR self-audit checklist and Quality Gate verification.
3. `collect-coverage`: Native coverage collection and LCOV parsing instructions.
4. `component-author` / `module-author`: Idiomatic component/schema authoring rules.
5. `fix-layout-issues`: UI layout or API schema error debugging.
6. `nullable-types`: Idiomatic null-safety and defensive programming patterns for this language.
7. `run-static-analysis`: Strict static analysis (`--fatal-infos` or equivalent) and auto-fix rules.
8. `screen-builder` / `service-builder`: Vertical feature module implementation with Clean Sizing.
9. `ui-preview`: Isolated preview rules (or Swagger/OpenAPI for APIs).
10. `architecture-audit`: Architectural boundaries and cyclic dependency audit.

### Phase 5: Verification & Genesis Record
1. Run static analysis on the repository to verify zero warnings.
2. Execute the test suite and calculate the initial baseline coverage.
3. Record the initial session state in `docs/wiki/memory/handoff.md` and append the Genesis entry in `docs/wiki/log.md`.
4. Present a clear summary of the newly activated Living Repository to the user.
```
