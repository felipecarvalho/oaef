<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->
<!-- To modify rules, edit AGENTS.md and run "oaef sync". -->

# Working Contract for Autonomous AI Agents and Engineers
> This document is the canonical contract for `expo-starter`. Every AI agent and harness (Claude Code, Codex, OpenCode, Antigravity, Cursor, Pi, Cline, Goose, and other AGENTS.md-native harnesses) and human software engineer MUST adhere to the standards defined herein.
>
> Content wrapped in `<!-- oaef:section:* -->` markers is framework-owned and is replaced in place by `oaef upgrade`. Everything outside the markers is user-owned and is never rewritten or deleted.

---

<!-- oaef:section:trust-hierarchy -->
## 1. The Inviolable Trust Hierarchy

$$\mathbf{Compiler / Typechecker} > \mathbf{Automated Tests} > \mathbf{Source Code} > \mathbf{Wiki / Docs} > \mathbf{Ephemeral Memory} > \mathbf{LLM Hallucination}$$

| Trust Level | Source of Truth | Required Behavior |
| :--- | :--- | :--- |
| **1. Inviolable** | Compiler & Typechecker | If static analysis or compilation fails, the code is incorrect. Zero suppressions (except scoped external deprecation migration & code-gen linter meta). |
| **2. Deterministic** | Automated Tests | Tests validate behavior and contracts. Failing tests supersede assumptions. |
| **3. Factual** | Committed Source Code | What is committed and executing supersedes outdated prose. |
| **4. Referential** | Living Docs & ADRs | Specifications and ADRs document architectural intent. |
| **5. Volatile** | Ephemeral Memory (`handoff.md`) | Inter-session notes provide short-term context across transitions. |
| **6. Void** | LLM Hallucination | Assumptions without grounding in code, compiler, or tests must be discarded. |

* Never rely on model intuition when the compiler or automated test suite can deterministically verify.
* Never circumvent static analysis by adding linter ignore directives (except scoped third-party deprecations during active migration).
* Upon finishing any task, run the Quality Gate audit (`oaef audit` or native script) and prove all thresholds are satisfied.
* **Simplicity Ladder (the Ponytail Ladder)** — before writing code climb: YAGNI > Reuse in codebase > Language/stdlib primitives > Platform-native capability > Already-installed dependency > One-line idiomatic expression > Smallest correct diff. The best code is the code you did not have to write. Zero tolerance for AI slop and speculative abstraction.
* **SOLID Principles** — classes, modules, services and components operate under single responsibility, segregated contracts, inverted dependencies and strict substitutability (see [`docs/standards/solid.md`](docs/standards/solid.md)).
<!-- /oaef:section:trust-hierarchy -->

---

<!-- oaef:section:quality-gates -->
## 2. Multidimensional Quality Gate Matrix

All contributions are audited against the mathematical thresholds defined in [`docs/wiki/metrics/baseline.json`](docs/wiki/metrics/baseline.json):

| Category | Metric | Mandatory Floor (Baseline) | Clean Code Target |
| :--- | :--- | :--- | :--- |
| **Coverage** | **Lines** | `>= 95.0%` (or baseline ratchet) | `100.0%` |
| | **Statements** | `>= 95.0%` | `100.0%` |
| | **Functions** | `>= 95.0%` | `100.0%` |
| | **Branches** | `>= 90.0%` | `95.0%` |
| **Duplication** | **Percentage** | `<= 3.0%` | `<= 1.0%` |
| | **Fragments** | `0` fragments | `0` fragments (>= 15 lines) |
| **Violations** | **Rule Violations** | `0` (Zero Tolerance) | `0` |
| | **Unallowed Ignores** | `0` comments | `0` |
| **Clean Sizing** | **Oversized Files** | `0` files > 300 LOC | Files <= 200 LOC |
| | **Oversized Methods** | `0` methods > 50 LOC | Methods <= 30 LOC |
| **Clean Code** | **Governance Violations** | `0` (Zero Tolerance) | `0` (naming, swallowing, DI leaks, nullable collections, unimplemented placeholders) |
| **Simplicity** | **Ponytail Debt Markers** | reported (not blocking) | `0` |
| **Living Memory**| **Secret Leaks** | `0` detected credentials/PII | `0` |

Every `CC-*` threshold above is specified in [`docs/standards/governance_checks.md`](docs/standards/governance_checks.md); violations are printed as `<CHECK-ID> <path>:<line> — <message>` by `oaef clean-code`.
<!-- /oaef:section:quality-gates -->

---

<!-- oaef:section:skills-catalog -->
## 3. Canonical Agent Skills Catalog

When performing tasks, consult and execute the specialized skills located in [`.agents/skills/`](.agents/skills/). The catalog is fixed at 13 skills; every skill is present in this repository and mirrored into each supported harness directory (see [`docs/HARNESSES.md`](docs/HARNESSES.md)).

### 3.1 Unified Pipeline (13 skills)

* [`ponytail`](.agents/skills/ponytail/SKILL.md): Simplicity ladder, anti-AI-slop, root-cause fixes and debt markers.
* [`nullable-types`](.agents/skills/nullable-types/SKILL.md): Strict, defensive null-safety and guard clause patterns.
* [`architecture-audit`](.agents/skills/architecture-audit/SKILL.md): Verify module decoupling, boundaries, and sizing bounds.
* [`screen-builder`](.agents/skills/screen-builder/SKILL.md): Vertical feature construction respecting Clean Sizing.
* [`component-author`](.agents/skills/component-author/SKILL.md): Modular component authoring following Design System tokens.
* [`responsive-layout`](.agents/skills/responsive-layout/SKILL.md): Adaptive surfaces across breakpoints, form factors and payload shapes.
* [`ui-preview`](.agents/skills/ui-preview/SKILL.md): Isolated component previews and rapid feedback.
* [`fix-layout-issues`](.agents/skills/fix-layout-issues/SKILL.md): Structural layout and UI rendering debugging.
* [`test-generator`](.agents/skills/test-generator/SKILL.md): High-coverage unit, integration, and branch testing.
* [`collect-coverage`](.agents/skills/collect-coverage/SKILL.md): Native coverage extraction and LCOV auditing.
* [`run-static-analysis`](.agents/skills/run-static-analysis/SKILL.md): Strict static analysis with zero warnings and auto-fix.
* [`code-review`](.agents/skills/code-review/SKILL.md): Pre-PR self-audit checklist and Quality Gate verification.
* [`conformance-audit`](.agents/skills/conformance-audit/SKILL.md): Repository conformance audit (structure, skills, mirrors, community files).

### 3.2 Canonical Skill Chaining Recipes

```text
1. Feature / Screen Construction:
   ponytail -> screen-builder + responsive-layout -> ui-preview -> test-generator -> collect-coverage -> run-static-analysis -> code-review
2. Reusable Component / Module Authoring:
   ponytail -> component-author -> ui-preview -> responsive-layout -> test-generator -> run-static-analysis
3. Bug Fix / Root-Cause Remediation:
   ponytail (root-cause caller grep) -> fix-layout-issues (UI) / nullable-types (logic) -> test-generator -> run-static-analysis
4. Domain, Data & Infrastructure:
   ponytail -> nullable-types -> test-generator -> collect-coverage -> run-static-analysis
5. Pre-Submission / Pull Request Cycle:
   collect-coverage -> run-static-analysis -> code-review
```

### 3.3 Canonical Dispatch Matrix

| Intent | Territory (paths) | Triggers | Primary Skill | Meta-Skill |
| :--- | :--- | :--- | :--- | :--- |
| screen / feature / flow | `**/features/**`, `**/screens/**`, `**/pages/**` | "screen", "page", "feature", "flow", "view" | `screen-builder` | `ponytail` |
| reusable component | `**/components/**`, `**/shared/**`, `**/ui/**` | "component", "widget", "button", "card", "modal" | `component-author` | `ponytail` |
| preview | any UI source dir | "preview", "storybook", "isolated render" | `ui-preview` | `ponytail` |
| adaptive / responsive | any UI source dir | "responsive", "adaptive", "breakpoint", "tablet", "foldable", "viewport" | `responsive-layout` | `ponytail` |
| layout / render error | any UI source | "overflow", "unbounded", "layout", "layout broken", "render error" | `fix-layout-issues` | `ponytail` |
| tests | `**/test/**`, `**/tests/**`, `**/*_test.*`, `**/*.spec.*` | "test", "coverage", "mock", "fixture" | `test-generator` | `ponytail` |
| coverage | coverage artifacts dir | "coverage", "lcov", "jacoco", "cobertura", "branches" | `collect-coverage` | — |
| static analysis | workspace | "analyze", "lint", "typecheck", "warnings" | `run-static-analysis` | — |
| nullability / types | any source | "null", "optional", "nil", "guard clause", "defensive" | `nullable-types` | `ponytail` |
| architecture boundaries | `**/core/**`, `**/domain/**`, `**/data/**`, `**/infra/**` | "architecture", "boundary", "coupling", "cycle" | `architecture-audit` | `ponytail` |
| repository conformance | `docs/**`, root meta-files | "conformance", "doctor", "parity", "frontmatter" | `conformance-audit` | — |
| pre-PR self-review | whole PR | "review", "PR", "checklist", "pre-PR" | `code-review` | `ponytail` |
| anything new / refactor | workspace | "new", "refactor", "add", "simple", "minimal", "YAGNI", "dead code", "delete", "remove" | `ponytail` | — (itself) |

> **Mandatory coherence:** every keyword of the `Triggers` column MUST appear in the frontmatter `Triggers on:` list of the matching skill, and every catalog skill MUST have a row in this matrix. Audited by `SK-04` (`oaef skills audit`). This table is the bridge between in-repository dispatch (§4.18 Phase 0) and harness-side activation (the frontmatter `description`).

### 3.4 Territorial Scopes

* **Features directories** → `screen-builder` + `ui-preview` + `responsive-layout`.
* **Shared/component directories** → `component-author` + `ui-preview`.
* **Test directories** → `test-generator` + `collect-coverage`.
* **Any source directory** → `ponytail` + `nullable-types`.
* **Domain/data/infra directories** → `architecture-audit`.
* **Pre-commit / pull request** → `run-static-analysis` + `code-review`.
* **Docs / root meta-files** → `conformance-audit`.
<!-- /oaef:section:skills-catalog -->

---

<!-- oaef:section:invariants-intro -->
## 4. Mandatory Clean Code & Architectural Invariants

The invariants below hold in every stack. Machine-enforced ones reference the check identifiers of [`docs/standards/governance_checks.md`](docs/standards/governance_checks.md).
<!-- /oaef:section:invariants-intro -->

<!-- oaef:section:rule-4.1 -->
### 4.1 Meaningful & Intention-Revealing Names (Clean Code)
1. **Intention-Revealing Naming**:
   - Variables, functions, and classes MUST clearly state *why they exist*, *what they do*, and *how they are used*.
   - If an identifier requires a comment to explain its purpose, its name has failed.
2. **Strict Ban on Cryptic Abbreviations** (`CC-02`):
   - The following abbreviations are strictly prohibited in variable, parameter, property, and function names:
     `btn` (use `button`), `val` (use `value`), `res` (use `response` or `result`), `req` (use `request`), `usr` (use `user`), `cb` (use `callback`), `temp`/`tmp` (use `temporary...`), `data`/`info`/`obj` (use specific domain nouns), `mgr` (use `manager`), `param` (use `parameter`), `fn` (use `function`), `cnt` (use `count`), `idx` (use `index`), `buf` (use `buffer`), `str` (use `text` or `string` descriptor), `num` (use `number` or `amount`), `doc` (use `document`), `elem` (use `element`), `curr`/`prev` (use `current`/`previous`), `ctx` (use `context`, except the framework-mandated binding below), `el` (use `element`).
   - Exception: Framework-mandated parameter types (e.g. Flutter `BuildContext context` or Go `context.Context ctx`).
3. **Strict Ban on Single-Letter Identifiers** (`CC-01`):
   - Single-letter variable names (`a`, `b`, `c`, `d`, `e`, `k`, `m`, `n`, `s`, `t`, `v`, `x`, `y`, `z`) are strictly forbidden across all production and test code.
   - Loop counters (`i`, `j`) are permitted ONLY within tiny iteration blocks of `<= 5` lines. For nested or longer loops, use descriptive indices (`rowIndex`, `columnIndex`).
   - The discard name `_` is always permitted.
4. **Strict Ban on Noise Words & Hungarian Notation**:
   - Redundant noise words that add zero distinction are banned: `ProductData`, `ProductInfo`, `ProductObject`, `CustomerRecord` are redundant. Use `Product` and `Customer`.
   - Never encode data types in names (e.g., `nameString`, `accountList`, `userMap`).
5. **Grammar & Part of Speech**:
   - Classes and types MUST be nouns or noun phrases (`UserSession`, `PaymentProcessor`).
   - Methods and functions MUST be verbs or verb phrases (`calculateTotal`, `sendNotification`, `isValid`).
   - Booleans MUST read as predicates (`isActive`, `hasPermission`, `canSubmit`).
   - Pick one verb per concept across the entire codebase (never mix `fetch`, `retrieve`, and `get` for identical actions).
<!-- /oaef:section:rule-4.1 -->

<!-- oaef:section:rule-4.2 -->
### 4.2 Function Sizing & Craftsmanship
1. **Clean Sizing Bounds**:
   - Files MUST NOT exceed 300 physical lines of code (Clean Target: `<= 200 LOC`).
   - Methods/Functions MUST NOT exceed 50 physical lines of code (Clean Target: `<= 30 LOC`).
2. **Do One Thing (Single Responsibility Principle)**:
   - A function should do one thing, do it well, and do it only.
   - Statements within a function must operate at a Single Level of Abstraction (SLAP).
3. **Function Arguments**:
   - Target 0 to 2 arguments. When 3 or more arguments are needed, wrap them into a dedicated parameter object, record, or configuration struct.
4. **Strict Ban on Flag Arguments**:
   - Never pass boolean flags as arguments (e.g., `render(isModal: bool)` or `processOrder(isExpedited: bool)`).
   - A boolean argument is a direct signal that the function does more than one thing. Split it into two dedicated functions.
5. **Command-Query Separation (CQS)**:
   - Functions should either modify state (command) or return data (query), but never both.
6. **Extract Error Handling**:
   - Error handling (`try/catch` or error matching) is one thing. Functions that handle errors should do nothing else.
<!-- /oaef:section:rule-4.2 -->

<!-- oaef:section:rule-4.3 -->
### 4.3 Flow Control & Guard Clauses
1. **Early Return / Guard Clauses**:
   - Validate preconditions and handle error cases at the function entrypoint. Return immediately to keep the primary happy path unindented.
   - Cyclomatic nesting deeper than 2 levels is prohibited. Extract complex conditions into well-named predicate functions.
2. **Zero Dead / Commented-Out Code**:
   - Never leave commented-out code blocks in committed files. Version control preserves history. Deletion of dead weight is the first rung of the Simplicity Ladder (§4.7).
<!-- /oaef:section:rule-4.3 -->

<!-- oaef:section:rule-4.4 -->
### 4.4 Protection of Mirror Instruction Files
- Autonomous agents MUST NOT edit `CLAUDE.md` directly.
- All rule modifications MUST be committed to `AGENTS.md`. The mirror is synchronized automatically via `oaef sync`.
- `AGENTS.md`-native harnesses (Codex, OpenCode, Antigravity, Cursor, Pi, and others) consume the canonical file directly and require no mirror; see [`docs/HARNESSES.md`](docs/HARNESSES.md).
- Harness skill mirrors (`.claude/skills/`, `.cursor/rules/`, `.windsurf/skills/`, `.cline/skills/`, `.grok/agents/`) are generated artifacts: rebuild them with `oaef skills sync-mirrors` and never edit them in place.
<!-- /oaef:section:rule-4.4 -->

<!-- oaef:section:rule-4.5 -->
### 4.5 Strict Living Documentation Parity
- Adding, renaming, or removing an agent skill requires simultaneously updating `AGENTS.md` (§3), `docs/INDEX.md`, and `llms.txt`. Audited by `SK-01` and `SK-03`.
- **Cascade Reference Updates**: When any file is moved, renamed, or deleted, all cross-references across markdown documentation MUST be updated in the same commit. Broken links are audited by `oaef lint`.
<!-- /oaef:section:rule-4.5 -->

<!-- oaef:section:rule-4.6 -->
### 4.6 Open-Source Pull Request Protocol
- Every Pull Request MUST follow the standardized community template (`.github/pull_request_template.md`):
  - Conventional Commit title (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`).
  - Clear summary explaining the problem and architectural solution.
  - Linked issue reference (`Fixes #...`).
  - Evidence of automated tests and passing Quality Gates.
  - The `Governing Skills` declaration and the `Agent Skills Applied` checklist completed.
  - Completed Quality Gate checklist confirming zero static analysis warnings and zero unallowed suppressions.
<!-- /oaef:section:rule-4.6 -->

<!-- oaef:section:rule-4.7 -->
### 4.7 The Ponytail Simplicity Ladder & Anti-AI-Slop

Before writing code, climb the ladder and stop at the first rung that solves the real problem:

1. **YAGNI** — delete the requirement that does not exist yet.
2. **Reuse in the codebase** — the pattern already exists; use it instead of a twin.
3. **Language / standard-library primitive** — the platform already ships it.
4. **Platform-native capability** — the OS, browser, runtime or framework already does it.
5. **Already-installed dependency** — no new dependency for a solved problem.
6. **One-line idiomatic expression** — the smallest expression that is still readable.
7. **Smallest correct diff** — the change touches only what must change.

* **Modes**: `lite` (default, sensible simplifications), `full` (aggressive removal, every rung questioned), `ultra` (nothing is kept without a caller and a test).
* **Surgical changes**: no drive-by refactors, no renames of untouched code, no file reorganization inside an unrelated PR.
* **Root-cause bug fixing**: before patching a symptom, `grep` **every caller** of the failing function. Fix the shared root once (a single guard, a single invariant) instead of adding defensive branches at each call site.
* **Ceremonial layers are banned**: a one-line pass-through use case, a single-implementation interface with no mock need, a wrapper that only forwards arguments, and narration comments that restate the next line.
* **Debt markers**: a deliberate simplification is declared on the spot with `// ponytail: <ceiling + evolution trigger>`; audited by `PT-01` (`oaef ponytail debt`).
* **Remediation tags** used by `code-review` and `oaef ponytail audit`: `[DELETE]` dead weight, `[STDLIB]` replace custom code with a primitive, `[NATIVE]` platform capability, `[YAGNI]` speculative feature, `[SHRINK]` shrink a multi-line construct to one line.
* **Safety frontier — never pruned**: input validation, error routing, privacy/consent, accessibility, and every Quality Gate stay. Simplicity never licenses an unsafe shortcut.
<!-- /oaef:section:rule-4.7 -->

<!-- oaef:section:rule-4.8 -->
### 4.8 SOLID Principles & Substitutability

Production code satisfies the five principles in [`docs/standards/solid.md`](docs/standards/solid.md):

1. **Single Responsibility** — one reason to change per module, class, function.
2. **Open/Closed** — extend through composition and new implementations, not by editing every caller.
3. **Liskov Substitution** — an implementation fulfills the whole contract: no narrowed preconditions, no widened postconditions, no raising of unexpected errors, no `UnimplementedError`/`NotImplementedException`/`NotImplementedError`/`unimplemented!()`/`todo!()`/`panic("not implemented")` in a production implementation (`CC-09`).
4. **Interface Segregation** — many small role interfaces beat one fat interface; a consumer never depends on members it does not call.
5. **Dependency Inversion** — high-level policy depends on abstractions it owns; concrete I/O lives at the edge (see §4.9).
<!-- /oaef:section:rule-4.8 -->

<!-- oaef:section:rule-4.9 -->
### 4.9 Dependency Inversion & Service-Locator Confinement

1. Dependencies arrive through the constructor (`required`/final/immutable/`readonly`) or the function parameter list — never by ambient lookup inside business logic.
2. A service locator, global container or static registry is used **only** in the composition root and the presentation layer. Domain, data, and service layers resolve nothing (`CC-07`).
3. No concrete network client is instantiated outside the composition root: depend on the abstraction and let the root choose the implementation (`CC-10`).
4. Wiring is visible at the top of the process: one composition root per executable entry point, plus optional per-feature factories.
<!-- /oaef:section:rule-4.9 -->

<!-- oaef:section:rule-4.10 -->
### 4.10 Nullability Minimization & Non-Nullable Collections

1. `null` (or `nil`/`None`/`Option`) carries business meaning only. It is never used as "not yet decided" or "caller forgot".
2. A collection parameter or return value is non-nullable and defaults to a constant empty immutable collection (`CC-08`); an "optional list" is a design smell, not a type.
3. Service-locator registration takes no optional/nullable dependency parameters.
4. Where the type system cannot express a non-null collection default (Go, Rust), the collection parameter MUST be documented as nil-safe at its declaration.
5. Non-null assertion operators (`!`, `!!`, `.unwrap()`) stay banned in production business logic.
<!-- /oaef:section:rule-4.10 -->

<!-- oaef:section:rule-4.11 -->
### 4.11 Two-Layer Resilience & Zero Silent Exception Swallowing

1. **Infrastructure layer**: catch the failure, log it with structured context plus error and stack trace, then propagate it or wrap it into a domain error/result type.
2. **Coordination layer**: add the defensive barrier, retry policy, timeout, or circuit breaker that protects the caller.
3. An empty `catch`/`except`/`err` block (`CC-06`) is a defect, never a style choice. Recognized dispositions: log with severity, rethrow, or map to a documented error result.
4. Failure isolation per provider/dependency: one failing dependency never aborts the whole operation (see [`docs/standards/analytics_and_telemetry.md`](docs/standards/analytics_and_telemetry.md)).
<!-- /oaef:section:rule-4.11 -->

<!-- oaef:section:rule-4.12 -->
### 4.12 DRY Test Factories & Dead-Parameter Prohibition

1. Each suite declares one local factory per entity (`make<Entity>(...)`) instead of repeating literals in every test (see [`docs/standards/testing.md`](docs/standards/testing.md)).
2. A factory declares **only** the parameters that actually vary across its call sites.
3. Dead parameters (always `null`, always the default, never read) are deleted; an optional collection parameter defaults to a constant empty collection.
4. Test data is deterministic: no ambient clock, no random values, no network.
<!-- /oaef:section:rule-4.12 -->

<!-- oaef:section:rule-4.13 -->
### 4.13 Holistic Pattern Remediation (Cascade Review)

1. A finding is never fixed in one place: the same pattern is hunted across the whole pull request and its sibling pull requests.
2. Every equivalent file receives the correction in the same change set, or the exception is recorded in `docs/wiki/memory/handoff.md`.
3. Review comments name the pattern, not the single line, so the fix generalizes.
<!-- /oaef:section:rule-4.13 -->

<!-- oaef:section:rule-4.14 -->
### 4.14 Solution Abstraction Elevation (Rule of Two)

1. The same solution appearing in two or more places is elevated into one shared abstraction in the same change set.
2. The counter-blade: an abstraction with a single implementation and no mock need is prohibited — it is speculation, not design.
3. Elevation is recorded where it is created: the shared module documents the ceiling and the trigger that would make it wrong.
<!-- /oaef:section:rule-4.14 -->

<!-- oaef:section:rule-4.15 -->
### 4.15 Native / Multi-Platform Dependency Audit

1. Any dependency that ships native code is audited for transitive compatibility in every downstream host repository that consumes this one.
2. A multi-target build (Debug / Profile / Release, or the platform equivalent) MUST be proven for each host target, with no symbol, class or framework duplication.
3. The audit result is recorded in the pull request as evidence; unresolved host conflicts block the merge.
<!-- /oaef:section:rule-4.15 -->

<!-- oaef:section:rule-4.16 -->
### 4.16 Memory & Allocation Discipline (Lazy-Copy)

1. Hot paths allocate nothing that can be avoided: no defensive copy that no caller mutates, no intermediate collection that is immediately discarded.
2. Inspection never copies — iterate, filter and query the original structure.
3. When a transformation changes nothing, return the original reference instead of an equal copy.
4. Audited as advisory `CC-11`; the reviewer decides what "hot path" means for the stack.
<!-- /oaef:section:rule-4.16 -->

<!-- oaef:section:rule-4.17 -->
### 4.17 Privacy by Design (Consent Gate & PII Redaction)

1. No personal data leaves the process and nothing personal is persisted before the consent gate is satisfied.
2. Redaction is lazy and allocation-free on the clean path: when nothing is redactable, the original reference is returned untouched.
3. Third-party SDKs are not initialized before consent; withdrawal of consent stops collection immediately.
4. Keys blocked from logging/telemetry are declared as a keyword list in one place (see [`docs/standards/analytics_and_telemetry.md`](docs/standards/analytics_and_telemetry.md)).
<!-- /oaef:section:rule-4.17 -->

<!-- oaef:section:rule-4.18 -->
### 4.18 Cognitive Dispatch Gate (Phase 0 — Governing Skills Declaration)

Before planning, editing or reviewing anything:

1. Evaluate the demand against the dispatch matrix (§3.3) and the territorial scopes (§3.4).
2. Read each applicable `SKILL.md` **first** — skill first, work second.
3. Declare the decision in the response, on its own line, before any change:

```text
> Governing Skills: [.agents/skills/ponytail/SKILL.md, .agents/skills/screen-builder/SKILL.md]
```

4. The declaration is binding: a task executed without reading and declaring its governing skills is a level-1 contract failure.
5. When no skill matches, declare `> Governing Skills: []` and say why; `ponytail` remains the default meta-skill.
<!-- /oaef:section:rule-4.18 -->

<!-- oaef:section:rule-4.19 -->
### 4.19 Pre-Review Canonical Truth Ingestion

Before reviewing any change (self-review or peer review):

1. `git fetch origin main` and absorb the canonical baseline: `AGENTS.md`, the accepted ADRs under `docs/adr/`, every file in `docs/standards/`, and `docs/wiki/`.
2. Rebase-awareness: never report a finding that exists only because the branch is stale.
3. Record the ingestion in the review entry point; a review that skipped Step 0 is not a review.
<!-- /oaef:section:rule-4.19 -->

<!-- oaef:section:invariants-stack-rules -->
### Stack-Specific Architectural Rules (Expo)

1. **Strict Anti-Suppression Policy**:
   - Suppressing compiler, linter, or typechecker diagnostics via `/* eslint-disable */`, `// eslint-disable-next-line`, `// @ts-ignore`, or `// biome-ignore` is strictly forbidden.
   - **Permitted Scoped Deprecation Exception**: `// eslint-disable-next-line @typescript-eslint/no-deprecated` is permitted solely when calling deprecated APIs from external npm dependencies during active transitional migrations.
   - **Permitted Code-Gen Exception**: Generated files inside `.expo/`, auto-generated typed router definitions, or files with `@generated` markers are exempt from manual linter rules.
   - Blanket suppressions without specific rule tokens on domain code are strictly forbidden.

2. **Expo Router File-Based Routing Discipline**:
   - Route entrypoints in `app/` MUST act strictly as page coordinators, delegating complex UI and business logic to modular components in `src/features/` or `src/components/`.
   - Files in `app/` must respect Clean Sizing bounds (<= 200 LOC target).
   - Enforce typed routes with `expo-router` for safe deep-linking and web parity.

3. **Managed Workflow & Config Plugins Invariant**:
   - All native permissions, entitlements, and manifest configurations MUST be declared declaratively in `app.json` or `app.config.ts` using Expo Config Plugins.
   - Manual, direct edits to ephemeral `android/` and `ios/` folders generated by `npx expo prebuild` are strictly prohibited.

4. **Responsive Layout & Safe Areas**:
   - Always wrap application screens with `SafeAreaProvider` and consume `useSafeAreaInsets` to support edge-to-edge displays.
   - Use `useWindowDimensions` for adaptive breakpoints across phone, tablet, and web viewports.

5. **StyleSheet Discipline & Clean Code**:
   - All styles must be declared using `StyleSheet.create` outside component render cycles.
   - Identifiers must be intention-revealing, with strict prohibition of abbreviations (`btn`, `val`, `res`, `req`, `usr`, `cb`, `temp`).

---

### Simplicity Ladder & Anti-AI-Slop

1. Climb the seven rungs before writing code: (1) YAGNI — the feature is not needed; (2) reuse an existing
   `src/features/**` or `src/components/**` unit; (3) a TypeScript/JavaScript stdlib primitive
   (`Array.prototype` pipelines, `Object.groupBy`, `Intl`, optional chaining, nullish coalescing);
   (4) an Expo platform-native capability already in the project (`expo-router` typed routes, `expo-constants`,
   `expo-device`, `FlatList`/`FlashList` virtualization); (5) an already-installed npm dependency;
   (6) a one-line idiomatic expression; (7) the smallest correct diff.
2. Banned ceremonies: a one-line pass-through `app/` route that only re-exports a screen; a
   single-implementation React context/hook abstraction with no test double need; a forwarding wrapper
   component that adds no props or behavior; a narration comment restating the next line.
3. Declare deliberate ceilings with the debt marker `// ponytail: <ceiling + evolution trigger>`; mark
   remediation candidates with the tags `[DELETE] [STDLIB] [NATIVE] [YAGNI] [SHRINK]`.
4. Safety frontier — never pruned: payload validation, error routing, privacy/PII handling, accessibility
   props (`accessibilityRole`, `accessibilityLabel`) and the Quality Gates.

### SOLID & Substitutability

1. **S**: one reason to change per module/hook/component. **O**: extend through props, slots and new modules,
   not by editing shared branches. **L**: a subtype/mock must honor every contract a consumer relies on.
   **I**: narrow prop and hook return types over one broad bag. **D**: consume interfaces/callbacks, not concretions.
2. Concrete substitutability failure mode: a component or hook that assumes a shape its declared prop type
   does not promise (reading `item.foo` where the prop is `item?: Foo`), or a test double that silently
   returns `undefined` where production returns a value.
3. A production implementation never contains the stack placeholder `throw new Error('Not implemented'`
   (`CC-09`); a partial contract is implemented, not shipped as a stub.

### Dependency Inversion & Container Confinement

1. Inject through props, hooks and module function parameters; keep dependencies immutable and explicit.
2. The container/service-locator API (`container.get(`, `Container.get(`, `container.resolve(`, `getService(`)
   is confined to the composition root and the presentation layer; it is **banned** in `src/domain/**`,
   `src/data/**`, `src/services/**` and `src/repositories/**` (`CC-07`).
3. The concrete network client (`axios.create(`, `new XMLHttpRequest(`, `new HttpClient(`) is never
   instantiated outside the composition root; consumers depend on an abstraction or a single client module
   (`CC-10`). Allowed roots here: `app/_layout.tsx`-style composition entrypoints, `src/di/**` and a single
   `src/services/**/client.ts` factory.
4. `fetch` is called through the project's single client wrapper, never ad hoc inside a screen or hook.

### Non-Nullable Collections & Nullability Minimization

1. Absence carries business meaning only when modelled explicitly; a collection parameter or return defaults
   to a constant empty collection rather than `null`/`undefined`.
2. The stack idiom for the constant empty default is a module-level `const EMPTY_ITEMS: readonly Item[] = []`;
   a public parameter typed `Array`/`ReadonlyArray`/`Map`/`Set`/`[]` or unioned with `|undefined` without such
   a default is a violation (`CC-08`).
3. Non-null assertion operators (`!`) stay banned in production logic; narrow with optional chaining,
   nullish coalescing or an explicit guard instead.

### Two-Layer Resilience & Zero Silent Exception Swallowing

1. Layer 1 (infrastructure): catch, log through the project logging interface with structured context plus
   the error and its stack trace, then propagate or wrap into a domain error/result.
2. Layer 2 (coordination): a defensive barrier at the boundary — request timeout, retry with backoff, stale
   response guard, or an ErrorBoundary around route segments.
3. Prohibited empty-handler shapes (`CC-06`): an empty `catch (...) { }` and a discarded `.catch(() => {})`
   with neither a log call nor a rethrow. Error routing to a central handler counts as non-empty.

### DRY Test Factories

1. One local factory per entity, named `make<Entity>`, exported from the suite or a colocated `__fixtures__`
   module; only parameters that actually vary in the suite, no dead or always-default parameters.
2. Factories are deterministic: no ambient clock, random source or live network — inject fixed timestamps and
   ids so Jest snapshots stay stable.
3. Runner and facilities: Jest with the `jest-expo` preset, `@testing-library/react-native` render helpers and
   `jest.fn()` doubles; assert behavior through the rendered tree, not on implementation internals.

### Solution Abstraction Elevation (Rule of Two)

1. When the same solution appears in two or more places, extract one shared abstraction in the same change
   set — a `src/components/**` component, a `src/shared/**` hook, or a util — and migrate every caller.
2. The naval razor: a single-implementation abstraction with no mock need is prohibited; do not create a hook,
   context or interface that only exists to satisfy a pattern.
3. Each elevation records its ceiling and the trigger that invalidates it, using the `// ponytail:` grammar.

### Native / Multi-Platform Dependency Audit

1. Native dependencies are declared through Expo Config Plugins in `app.json`/`app.config.ts` and pinned in
   `package.json`; the lockfile and `npx expo-doctor` output are the acceptance evidence.
2. Before a dependency is accepted, prove it builds across the EAS targets — development, preview and
   production profiles — and that its config plugin resolves without conflicting with the existing plugin set.
3. Audit transitive native compatibility in each downstream host repository that consumes the module, checking
   for duplicate native symbols and Android/iOS autolinking collisions.

### Memory & Allocation Discipline

1. Avoidable-allocation shapes on hot render paths (`CC-11`, advisory): materializing a spread `[...items]`
   inside a loop body and running `.map(...)` that builds a fresh array on every render without memoization.
2. Inspect without copying: read from the existing array/reference; when nothing changes, return the original
   reference so React's memoization and `FlatList`/`FlashList` diffing stay effective.
3. No intermediate collections in list-render callbacks; hoist derived data out of the render path and key
   lists stably.

### Privacy by Design (Consent & PII Redaction)

1. Consent gate before any personal data leaves the process or is persisted; third-party SDKs and analytics
   providers are not initialized before consent is granted.
2. Redaction is lazy and allocation-free: return the original reference unchanged when no value is redactable,
   and only build a new object when a blocked key is actually present.
3. Keep one keyword list of blocked PII keys in a single module; sanitize at the boundary, never scatter the
   list across call sites. See `docs/standards/analytics_and_telemetry.md`.

### Applicable Governance Checks

- `CC-01`, `CC-02`, `CC-03`, `CC-04`, `CC-05`, `CC-06`, `CC-07`, `CC-08`, `CC-09`, `CC-10` are blocking under
  the strict profile and advisory under the standard profile; `CC-11` is advisory in every profile. No check is
  a no-op on this stack. `oaef clean-code` enforces these; see `docs/standards/governance_checks.md`.

<!-- /oaef:section:invariants-stack-rules -->

---

<!-- oaef:section:handoff -->
## 5. Continuous Session Handoff & Living Memory

At the conclusion of every work session:
1. Update current progress, architectural decisions, and next steps in [`docs/wiki/memory/handoff.md`](docs/wiki/memory/handoff.md).
2. Append a timestamped milestone entry to [`docs/wiki/log.md`](docs/wiki/log.md).
3. **Security & Privacy**: It is strictly forbidden to persist secrets, tokens, API keys, credentials, or personally identifiable information (PII) in markdown documents.
<!-- /oaef:section:handoff -->

---

<!-- oaef:section:contradictions -->
## 6. Contradiction Resolution Protocol

The most critical failure mode in autonomous software development is silent assumption. When two documents conflict or when legacy code diverges from documentation:

1. **Adhere to the Trust Hierarchy**:
   $$\mathbf{Compiler} > \mathbf{Tests} > \mathbf{Source Code} > \mathbf{Wiki} > \mathbf{Memory} > \mathbf{Hallucination}$$
2. **Zero Silent Resolution**: The agent **MUST NEVER** silently choose an interpretation based on guesswork.
3. **Mandatory Reporting**: The contradiction MUST be recorded in [`docs/wiki/memory/handoff.md`](docs/wiki/memory/handoff.md) under `## ⚠️ Active Contradictions` and surfaced to the human engineer for arbitration.
<!-- /oaef:section:contradictions -->

---

<!-- oaef:section:autonomy -->
## 7. Agent Autonomy Matrix

| Action in Repository | Autonomy Level | Requirement |
| :--- | :--- | :--- |
| **Feature & Business Logic** | **Autonomous** | Must be covered by tests and pass Quality Gates. |
| **Test Creation & Refactoring**| **Autonomous** | Must follow TDD and branch coverage standards. |
| **Session Handoff & Log Append**| **Autonomous** | Must keep state fresh without secret leaks. |
| **Architecture Decision Records**| **Restricted** | Requires explicit human review and approval. |
| **Baseline Threshold Modification**| **Restricted** | Allowed only to raise quality floors, never to loosen. |
| **Canonical Rule / Standard Elevation** | **Restricted** | Elevating a recurring review finding into a canonical rule/standard requires human approval. |
| **Rule Suppressions** | **Prohibited** | Zero tolerance. |
| **Deletion of Canonical Docs** | **Prohibited** | Requires human confirmation. |
<!-- /oaef:section:autonomy -->

---

<!-- oaef:section:event-doc-matrix -->
## 8. Event-to-Documentation Matrix

| Change Event | Canonical Document to Update | Verification Mechanism |
| :--- | :--- | :--- |
| **Architectural Trade-Off / Decision** | [`docs/adr/NNNN-*.md`](docs/adr/) | Numbered ADR in PR. |
| **New Agent Skill Added/Modified** | [`.agents/skills/`](.agents/skills/), `AGENTS.md` §3, `docs/INDEX.md`, `llms.txt` | Audited via `oaef lint` (`SK-01`, `SK-03`). |
| **Renamed or Deleted Document** | All cross-referenced links in `docs/`, `AGENTS.md`, `llms.txt` | Audited via `oaef lint`. |
| **New/Changed Agent Skill** | `.agents/skills/<name>/SKILL.md` + harness mirrors + §3 matrix | `SK-01`, `SK-02`, `SK-04`, `SK-05`. |
| **Recurring Review Finding** | Elevate to a canonical rule in `AGENTS.md` §4 and/or `docs/standards/*` | Documented in the PR that introduces it (see §4.14). |
| **New Canonical Standard Document** | `docs/standards/<name>.md` + `docs/INDEX.md` + `llms.txt` | `oaef lint` cascade/entrypoint parity. |
| **New Governance Check** | `docs/standards/governance_checks.md` + all 12 runtimes + `baseline.json` | `oaef doctor` + `scripts/self-audit.sh`. |
| **Session Completion / Handoff** | [`docs/wiki/memory/handoff.md`](docs/wiki/memory/handoff.md) | Verified before task finish. |
| **Milestone Achieved** | [`docs/wiki/log.md`](docs/wiki/log.md) | Append-only record. |
<!-- /oaef:section:event-doc-matrix -->

---

<!-- oaef:section:commands -->
## 9. Adoption, Auditing & Conformance Commands

### 9.1 Adopting an Existing (Legacy) Repository
1. Discover non-destructively: `oaef init --target . --stack auto --legacy --dry-run`.
2. Review the plan — every file is classified as `install`, `merge-additive`, `merge-conflict`, `propose-oaef-new` or `preserve`. Existing content outside OAEF sentinels is never modified or deleted.
3. Apply with `oaef adopt` (alias `oaef init --legacy`) or `oaef upgrade` for an existing OAEF installation.
4. With `--legacy`, the measured coverage (lcov/cobertura/jacoco/coverlet artifacts) becomes the Monotonic Ratchet floor; quality may only increase. New `CC-*` checks enter advisory and their findings are inventoried in the Adoption Debt Ledger (`docs/wiki/memory/adoption.md`).

### 9.2 Conformance Audit — `oaef doctor`
- `oaef doctor` (alias `conform`) verifies the repository contains every OAEF artifact: contract, `CLAUDE.md` mirror parity, docs tree, baseline, memory ledger, the 5 canonical standards, the 13 skills, the governance runtime, the routing self-test (`SK-06`) and community files.
- Every `❌` MUST be resolved before the task is considered complete; unresolved findings MUST be recorded in [`docs/wiki/memory/handoff.md`](docs/wiki/memory/handoff.md).

### 9.3 Quality Audits
- `oaef audit` — multidimensional Quality Gate (coverage, duplication, clean sizing, suppressions).
- `oaef clean-code` — the `CC-*` governance barriers (`docs/standards/governance_checks.md`).
- `oaef lint` — mirror parity, cascade references, secret scanning, anti-suppression, `CC-*` advisory and `SK-01`…`SK-06`.
- `oaef ponytail debt` — report every `// ponytail:` debt marker (`PT-01`).
- `oaef ponytail audit` — advisory anti-slop audit (ceremonial layers, single-caller abstractions, narration comments).
- `oaef skills audit` — skill parity, frontmatter quality, entrypoint parity, trigger coherence, harness mirror parity.
- `oaef skills audit --selftest` — adds the routing fixture table (`SK-06`).
- `oaef skills route "<prompt>"` — resolve a prompt to its governing skill and chaining recipe.
- `oaef skills sync-mirrors [--check]` — rebuild (or validate) the harness skill mirrors.
- `oaef adopt` — install into an existing repository (adoption mode, advisory barriers, ledger).
- `oaef upgrade` — upgrade an earlier OAEF installation in place, preserving user-owned content.
- `oaef metrics` — display the current baseline thresholds.

### 9.4 Failure Protocol
- Follow the Inviolable Trust Hierarchy: fix the code, never silence the gate (zero suppressions).
- Contradictions MUST be recorded in `handoff.md` and escalated to the human engineer for arbitration.
<!-- /oaef:section:commands -->
