---
type: routing
title: Context Router & Knowledge Index
description: Canonical index for engineers and AI agents to locate task documentation without saturating the context window.
tags: [index, routing, wiki, okf, architecture]
timestamp: 2026-09-30T00:00:00Z
---

# Canonical Context Router
> *«For this specific task, which file do I open?»*

To optimize token efficiency and avoid context window pollution, **do not load all files**. Consult the routing table below and load strictly the documents required for your current task.

---

## 🎯 Task-Based Context Routing

| If your task is... | Open First | Open If Needed | Recommended Skill |
| :--- | :--- | :--- | :--- |
| **Check autonomy or resolve contradictions** | [`AGENTS.md`](../AGENTS.md) | [`docs/wiki/memory/handoff.md`](wiki/memory/handoff.md) | [`.agents/skills/code-review/`](../.agents/skills/code-review/SKILL.md) |
| **AI discovery / Understand project model** | [`llms.txt`](../llms.txt) | [`docs/MANIFESTO.md`](MANIFESTO.md) | — |
| **Configure or switch agent harness** | [`docs/HARNESSES.md`](HARNESSES.md) | [`AGENTS.md`](../AGENTS.md) | — |
| **Implement or modify a feature** | Main source directory | [`docs/standards/coding_patterns.md`](standards/coding_patterns.md) | [`.agents/skills/screen-builder/`](../.agents/skills/screen-builder/SKILL.md) |
| **Create or update a UI component** | [`docs/DESIGN.md`](DESIGN.md) | Component source files | [`.agents/skills/component-author/`](../.agents/skills/component-author/SKILL.md) |
| **Write or expand automated tests** | [`docs/standards/testing.md`](standards/testing.md) | [`docs/wiki/metrics/baseline.json`](wiki/metrics/baseline.json) | [`.agents/skills/test-generator/`](../.agents/skills/test-generator/SKILL.md) |
| **Resolve layout or rendering bugs** | UI source files | [`docs/DESIGN.md`](DESIGN.md) | [`.agents/skills/fix-layout-issues/`](../.agents/skills/fix-layout-issues/SKILL.md) |
| **Check or collect test coverage** | [`docs/standards/testing.md`](standards/testing.md) | [`docs/wiki/metrics/baseline.json`](wiki/metrics/baseline.json) | [`.agents/skills/collect-coverage/`](../.agents/skills/collect-coverage/SKILL.md) |
| **Handle nullable types & defensive code** | [`docs/standards/coding_patterns.md`](standards/coding_patterns.md) | [`AGENTS.md`](../AGENTS.md) | [`.agents/skills/nullable-types/`](../.agents/skills/nullable-types/SKILL.md) |
| **Instrument logging and diagnostics** | [`docs/standards/logging.md`](standards/logging.md) | Core logging source | [`.agents/skills/code-review/`](../.agents/skills/code-review/SKILL.md) |
| **Pre-PR self-audit & Quality Gates** | [`docs/wiki/metrics/baseline.json`](wiki/metrics/baseline.json) | [`.github/pull_request_template.md`](../.github/pull_request_template.md) | [`.agents/skills/code-review/`](../.agents/skills/code-review/SKILL.md) |
| **Review session memory or handoff** | [`docs/wiki/memory/handoff.md`](wiki/memory/handoff.md) | [`docs/wiki/log.md`](wiki/log.md) | — |

---

## 🗺️ Architectural Domain Map

### 1. Core Infrastructure
- **Dependency Injection & Routing**: Foundational wiring and navigation contracts.
- **Storage & State**: Persistence mechanisms and centralized application state.
- **Logging**: Production-safe, debug-only structured logging utility.

### 2. Feature Modules
- Independent, decoupled business vertical modules respecting Clean Sizing bounds (<=300 LOC/file).

### 3. Shared Design System & Components
- Tokens, shared visual surfaces, typography, and reusable primitives adhering to [`docs/DESIGN.md`](DESIGN.md).

### 4. Recorded Architectural Decisions ([`docs/adr/`](adr/))
- Numbered immutable records documenting technical trade-offs.
