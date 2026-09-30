<!-- AUTO-GENERATED MIRROR FROM AGENTS.md. DO NOT EDIT DIRECTLY. -->
<!-- To modify rules, edit AGENTS.md and run 'oaef sync'. -->

# Working Contract for Autonomous AI Agents and Engineers
> This document is the canonical contract for `go-starter`. Every AI agent (Claude Code, Antigravity, Gemini CLI, Cursor, Windsurf, Copilot, Roo Code) and human software engineer MUST adhere to the standards defined herein.

---

## 1. The Inviolable Trust Hierarchy

$$\mathbf{Compiler / Typechecker} > \mathbf{Automated Tests} > \mathbf{Source Code} > \mathbf{Wiki / Docs} > \mathbf{Ephemeral Memory} > \mathbf{LLM Hallucination}$$

| Trust Level | Source of Truth | Required Behavior |
| :--- | :--- | :--- |
| **1. Inviolable** | Compiler & Typechecker | If static analysis or compilation fails, the code is incorrect. Zero suppressions (`// ignore`). |
| **2. Deterministic** | Automated Tests | Tests validate behavior and contracts. Failing tests supersede assumptions. |
| **3. Factual** | Committed Source Code | What is committed and executing supersedes outdated prose. |
| **4. Referential** | Living Docs & ADRs | Specifications and ADRs document architectural intent. |
| **5. Volatile** | Ephemeral Memory (`handoff.md`) | Inter-session notes provide short-term context across transitions. |
| **6. Void** | LLM Hallucination | Assumptions without grounding in code, compiler, or tests must be discarded. |

* Never rely on model intuition when the compiler or automated test suite can deterministically verify.
* Never circumvent static analysis by adding linter ignore directives (except for deprecated third-party member usage).
* Upon finishing any task, run the Quality Gate audit (`oaef audit` or native script) and prove all thresholds are satisfied.

---

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
| **Living Memory**| **Secret Leaks** | `0` detected credentials/PII | `0` |

---

## 3. Canonical Agent Skills Catalog

When performing tasks, consult and execute the specialized skills located in [`.agents/skills/`](.agents/skills/):
* [`architecture-audit`](.agents/skills/architecture-audit/SKILL.md): Verify module decoupling, boundaries, and sizing bounds.
* [`code-review`](.agents/skills/code-review/SKILL.md): Pre-PR self-audit checklist and Quality Gate verification.
* [`collect-coverage`](.agents/skills/collect-coverage/SKILL.md): Native coverage extraction and LCOV auditing.
* [`component-author`](.agents/skills/component-author/SKILL.md): Modular component authoring following Design System tokens.
* [`fix-layout-issues`](.agents/skills/fix-layout-issues/SKILL.md): Structural layout and UI rendering debugging.
* [`nullable-types`](.agents/skills/nullable-types/SKILL.md): Strict, defensive null-safety and guard clause patterns.
* [`run-static-analysis`](.agents/skills/run-static-analysis/SKILL.md): Strict static analysis with zero warnings and auto-fix.
* [`screen-builder`](.agents/skills/screen-builder/SKILL.md): Vertical feature construction respecting Clean Sizing.
* [`test-generator`](.agents/skills/test-generator/SKILL.md): High-coverage unit, integration, and branch testing.
* [`ui-preview`](.agents/skills/ui-preview/SKILL.md): Isolated component previews and rapid feedback.

---

## 4. Non-Negotiable Architectural Rules

1. **Clean Sizing Discipline**:
   - Files MUST NOT exceed 300 physical lines of code.
   - Methods/Functions MUST NOT exceed 50 physical lines of code.
   - Extract helper widgets and sub-routines into dedicated, single-responsibility files.
2. **Protection of Mirror Instruction Files**:
   - Autonomous agents MUST NOT edit `CLAUDE.md`, `.cursorrules`, or `.windsurfrules` directly.
   - All rule changes MUST be committed to `AGENTS.md`. Mirrors are updated automatically via `oaef sync`.
3. **Strict Living Documentation Parity**:
   - Adding, renaming, or removing an agent skill requires simultaneously updating `AGENTS.md` (§3), `docs/INDEX.md`, and `llms.txt`.
   - **Cascade Reference Updates**: When a file is moved, renamed, or deleted, all cross-references across markdown documentation MUST be updated in the same commit. Broken links are audited by `oaef lint`.
4. **Pull Request Protocol**:
   - Every PR description MUST use the automated sections: `<!-- why:init:required -->` and `<!-- how:init:required -->`.
   - **Zero Empty Checkboxes**: Empty checkboxes (`- [ ]`) in PR descriptions are strictly forbidden to ensure all automated checks pass.

---

## 5. Continuous Session Handoff & Living Memory

At the conclusion of every work session:
1. Update current progress, architectural decisions, and next steps in [`docs/wiki/memory/handoff.md`](docs/wiki/memory/handoff.md).
2. Append a timestamped milestone entry to [`docs/wiki/log.md`](docs/wiki/log.md).
3. **Security & Privacy**: It is strictly forbidden to persist secrets, tokens, API keys, credentials, or personally identifiable information (PII) in markdown documents.

---

## 6. Contradiction Resolution Protocol

The most critical failure mode in autonomous software development is silent assumption. When two documents conflict or when legacy code diverges from documentation:

1. **Adhere to the Trust Hierarchy**:
   $$\mathbf{Compiler} > \mathbf{Tests} > \mathbf{Source Code} > \mathbf{Wiki} > \mathbf{Memory} > \mathbf{Hallucination}$$
2. **Zero Silent Resolution**: The agent **MUST NEVER** silently choose an interpretation based on guesswork.
3. **Mandatory Reporting**: The contradiction MUST be recorded in [`docs/wiki/memory/handoff.md`](docs/wiki/memory/handoff.md) under `## ⚠️ Active Contradictions` and surfaced to the human engineer for arbitration.

---

## 7. Agent Autonomy Matrix

| Action in Repository | Autonomy Level | Requirement |
| :--- | :--- | :--- |
| **Feature & Business Logic** | **Autonomous** | Must be covered by tests and pass Quality Gates. |
| **Test Creation & Refactoring**| **Autonomous** | Must follow TDD and branch coverage standards. |
| **Session Handoff & Log Append**| **Autonomous** | Must keep state fresh without secret leaks. |
| **Architecture Decision Records**| **Restricted** | Requires explicit human review and approval. |
| **Baseline Threshold Modification**| **Restricted** | Allowed only to raise quality floors, never to loosen. |
| **Rule Suppressions (`// ignore`)**| **Prohibited** | Zero tolerance. |
| **Deletion of Canonical Docs** | **Prohibited** | Requires human confirmation. |

---

## 8. Event-to-Documentation Matrix

| Change Event | Canonical Document to Update | Verification Mechanism |
| :--- | :--- | :--- |
| **Architectural Trade-Off / Decision** | [`docs/adr/NNNN-*.md`](docs/adr/) | Numbered ADR in PR. |
| **New Agent Skill Added/Modified** | [`.agents/skills/`](.agents/skills/), `AGENTS.md` §3, `docs/INDEX.md` | Audited via `oaef lint`. |
| **Renamed or Deleted Document** | All cross-referenced links in `docs/`, `AGENTS.md`, `llms.txt` | Audited via `oaef lint`. |
| **Session Completion / Handoff** | [`docs/wiki/memory/handoff.md`](docs/wiki/memory/handoff.md) | Verified before task finish. |
| **Milestone Achieved** | [`docs/wiki/log.md`](docs/wiki/log.md) | Append-only record. |
