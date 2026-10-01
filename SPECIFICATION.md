# Open Agentic Engineering Framework (OAEF) Specification
> **Specification Version:** 1.0.0  
> **Status:** Canonical Standard  
> **Author & Creator:** Felipe Carvalho  
> **License:** Apache License 2.0  
> **Date:** September 2026

---

## Abstract

This document defines the formal specification for the **Open Agentic Engineering Framework (OAEF)**. OAEF specifies a standardized architecture, context engineering model, behavioral contracts, and automated quality gates enabling autonomous artificial intelligence (AI) coding agents and human software engineers to collaborate reliably within a living repository without architectural drift or ungrounded assumptions.

---

## 1. Terminology & Conformance Notation

The key words **"MUST"**, **"MUST NOT"**, **"REQUIRED"**, **"SHALL"**, **"SHALL NOT"**, **"SHOULD"**, **"SHOULD NOT"**, **"RECOMMENDED"**, **"MAY"**, and **"OPTIONAL"** in this document are to be interpreted as described in BCP 14 [RFC 2119] [RFC 8174].

- **Living Repository**: A software repository containing its own machine-readable architecture, operational guidelines, executable contracts, and persistent inter-session memory.
- **Autonomous Agent**: An LLM-driven coding agent (e.g. Claude Code, Codex, OpenCode, Google Antigravity, Cursor, Windsurf, Copilot) capable of executing file modifications, terminal commands, or git commits.
- **Harness**: The runtime system around a model — execution loop, tool registration, sandboxing, context management, and recovery — that turns it into a working agent (e.g. Claude Code, Codex, OpenCode, Antigravity, Cursor). The verified compatibility matrix is maintained in `docs/HARNESSES.md`.
- **Inviolable Trust Hierarchy**: The deterministic priority ordering governing decision-making in the presence of conflicting information.
- **Monotonic Ratchet**: An algorithmic rule ensuring that repository quality thresholds (test coverage, branch coverage, linting) can only increase and NEVER decrease over time.
- **Zero-Pollution**: The invariant requiring consuming projects to contain strictly the files, skills, and runtimes applicable to their selected programming stack.

---

## 2. The Inviolable Trust Hierarchy

When an agent or engineer encounters conflicting information, ambiguity, or contradiction, the resolution MUST follow the strict hierarchy:

$$\mathbf{Compiler / Typechecker} > \mathbf{Automated Tests} > \mathbf{Source Code} > \mathbf{Wiki / Docs} > \mathbf{Ephemeral Memory} > \mathbf{LLM Hallucination}$$

1. **Compiler / Static Analyzer**: If the compiler or static typechecker rejects code, the code is definitively erroneous. Suppressions via `// ignore:` or language-equivalent linter directives MUST NOT be used, except for officially deprecated third-party member usage.
2. **Automated Tests**: Executable tests validate business contracts and regression guarantees. A failing test MUST supersede human or agent assumptions.
3. **Committed Source Code**: Executable implementation in the primary branch supersedes outdated prose documentation.
4. **Living Documentation & ADRs**: Architecture Decision Records and specifications represent design intent and architectural boundaries.
5. **Ephemeral Memory (`handoff.md`)**: Notes recorded in the session handoff file provide short-term context across session transitions.
6. **LLM Hallucination / Intuition**: Any assumption or deduction by an AI model not anchored in levels 1 through 5 is defined as void and MUST be discarded.

---

## 3. The 4 Pillars of OAEF

### Pillar 1: Context Engineering (Google OKF & Karpathy LLM Wiki)
1. **Metadata Frontmatter**: Key documentation nodes in `docs/` MUST include YAML frontmatter compliant with the Google Open Knowledge Format (OKF):
   ```yaml
   ---
   type: routing | architecture | standard | spec
   title: <Document Title>
   description: <Concise 1-2 sentence description>
   tags: [tag1, tag2]
   timestamp: <ISO-8601 UTC>
   ---
   ```
2. **Context Router (`docs/INDEX.md`)**: Repositories MUST maintain a task-based routing matrix. Agents MUST consult `docs/INDEX.md` prior to loading files into context, loading strictly the documents required for the immediate task.
3. **Open AI Discovery (`/llms.txt`)**: Repositories MUST maintain an `/llms.txt` file at the root providing semantic navigation for web and agent crawlers.

### Pillar 2: Spec-Driven Development (SDD)
1. **Executable Specifications**: New vertical features or user-facing behaviors MUST be specified via Gherkin `.feature` files under `docs/bdd/` before implementation.
2. **Design Boundaries**: Visual components MUST adhere to tokens defined in `docs/DESIGN.md`.
3. **Architecture Records**: Non-trivial architectural decisions or structural changes MUST be recorded as numbered Architecture Decision Records under `docs/adr/`.

### Pillar 3: Multidimensional Quality Gates
A compliant OAEF repository MUST maintain a machine-readable `docs/wiki/metrics/baseline.json`. Verification scripts MUST audit the following dimensions:
1. **Line Coverage**: Target `>= 95.0%` (Baseline minimum configurable via interview).
2. **Branch Coverage**: Target `>= 90.0%` (Baseline minimum configurable via interview).
3. **Clean Sizing Bounds**:
   - File length: Maximum 300 physical lines of code (LOC).
   - Method/Function length: Maximum 50 physical lines of code (LOC).
4. **Code Duplication**: Maximum 3.0% total duplication and zero identical fragments `>= 15` lines.
5. **Static Analysis & Suppressions**: Zero errors, zero warnings, and zero unallowed ignores.
6. **The Monotonic Ratchet Rule**: When test coverage increases in a session, running the finish workflow with `--record` MUST update `baseline.json` to lock in the new threshold. Future runs MUST NOT allow metrics to degrade below this new floor.

### Pillar 4: Zero-Docker Living Memory
1. **Session Handoff Ledger (`docs/wiki/memory/handoff.md`)**: At the end of every work session, the active agent or developer MUST update `handoff.md` with:
   - Accomplished tasks;
   - Architectural decisions made;
   - Remaining pending tasks;
   - Open contradictions or blockers.
2. **Append-Only History Log (`docs/wiki/log.md`)**: Major milestones MUST be appended to `docs/wiki/log.md` with ISO-8601 UTC timestamps.
3. **Secret & PII Guard**: Agents MUST NOT write API keys, access tokens, credentials, or personally identifiable information into living memory files. Governance tools MUST scan and block secret leaks.
4. **Zero-Daemon Tooling**: Governance audits and index synchronization MUST execute natively in the host language without requiring background containers or daemons.

---

## 4. Agent Autonomy & Contradiction Triage Protocol

### Autonomy Matrix
| Repository Area | Autonomy Level | Execution Requirement |
| :--- | :--- | :--- |
| **Feature & Business Code** | **Autonomous** | Must pass automated tests and Quality Gates. |
| **Test Creation & Refactoring**| **Autonomous** | Must adhere to TDD and branch coverage standards. |
| **Handoff & Log Append** | **Autonomous** | Must update after session completion; zero secret leaks. |
| **Architecture Decision Records**| **Restricted** | Requires explicit human review and approval. |
| **Baseline Threshold Lowering**| **Prohibited** | Baseline can only be raised, never lowered. |
| **Rule Suppressions**| **Prohibited** | Zero tolerance (except scoped external deprecation migration & code-gen linter meta). |

### Contradiction Triage Protocol
If an agent detects a discrepancy between documentation and code, or between two specifications:
1. The agent **MUST NOT** silently choose an interpretation.
2. The agent **MUST** record the contradiction in `docs/wiki/memory/handoff.md` under `## ⚠️ Active Contradictions`.
3. The agent **MUST** surface the conflict to the human user for explicit arbitration.

---

## 5. Multi-Tool Synchronization Invariant

To ensure seamless collaboration across different AI agent harnesses:
1. `AGENTS.md` is the canonical root rulebook, consumed natively by `AGENTS.md`-native harnesses (Codex, OpenCode, Antigravity, Cursor, Pi, Cline, Goose, and others).
2. `.agents/skills/` is the portable Agent Skills catalog, auto-discovered natively by harnesses such as Codex, OpenCode, Antigravity, Cursor, Windsurf, Goose, OpenHands, Cline, and Factory.
3. `CLAUDE.md` MUST remain in exact functional parity with `AGENTS.md`. Running `oaef sync` MUST regenerate the `CLAUDE.md` mirror for Claude Code.
4. Harnesses without native `AGENTS.md` support (e.g. Aider) MAY be pointed at it through their own configuration. The verified per-harness compatibility matrix is maintained in `docs/HARNESSES.md`.

---

## 6. Zero-Pollution Target Isolation Invariant

When OAEF is instantiated into a consuming repository:
1. The target repository MUST receive strictly the skills, architectural rules, and governance scripts of its selected tech stack.
2. Template directories, unused runtime scripts, and skills for unselected languages MUST NOT be copied into the target project.
3. Language-specific rules MUST be dynamically injected into `AGENTS.md` and `CLAUDE.md` at setup time.

---

## 7. Cross-Language Anti-Suppression Equivalence Specification

To enforce compiler inviolability across heterogeneous tech stacks, OAEF defines exact syntax mappings for permitted exceptions:

| Stack / Ecosystem | Permitted Deprecation Exception | Permitted Generated Code Exception |
| :--- | :--- | :--- |
| **Dart / Flutter** | `// ignore: deprecated_member_use` | `// ignore: type=lint` |
| **React Native** | `// eslint-disable-next-line @typescript-eslint/no-deprecated` | `/* eslint-disable */` (`*.g.tsx`, `codegen/`) |
| **Expo** | `// eslint-disable-next-line @typescript-eslint/no-deprecated` | `/* eslint-disable */` (`.expo/`, `@generated`) |
| **TypeScript / Web** | `// eslint-disable-next-line @typescript-eslint/no-deprecated` | `/* eslint-disable */` (`*.g.ts` / `@generated`) |
| **Kotlin Multiplatform (KMP)** | `@Suppress("DEPRECATION")`, `DeprecatedCallableAddReplaceWith` | `@file:Suppress("UNCHECKED_CAST")` (`build/generated/`, `@Generated`) |
| **Kotlin / Android** | `@Suppress("DEPRECATION")`, `DeprecatedCallableAddReplaceWith` | `@file:Suppress("UNCHECKED_CAST")` (`@Generated`) |
| **Python** | `# noqa: W1505`, `# noqa: B005`, `# type: ignore[deprecated]` | `# type: ignore` (`*_pb2.py` / `# Generated by`) |
| **Go** | `//lint:ignore SA1019 <reason>` | `// Code generated by ... DO NOT EDIT.` |
| **Rust** | `#[allow(deprecated)]` | `#[allow(clippy::all)]` (macro/build outputs) |
| **Swift / iOS** | `// swiftlint:disable:next deprecated`, `deprecated_call` | `// swiftlint:disable all` (`*.generated.swift`) |
| **C# / .NET** | `#pragma warning disable CS0618`, `CS0612` | `<auto-generated />` / `[GeneratedCode]` |
| **Universal** | Scoped external API deprecation directive | Machine-generated code header |

Blanket suppressions without specific rule tokens or error codes MUST trigger an immediate Quality Gate failure.
