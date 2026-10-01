---
name: code-review
description: Specialized code-review skill for TypeScript & React/Next.js under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: typescript-web
  version: 1.0.0
---

# Code Review (TypeScript & React/Next.js)

> **Stack Profile:** TypeScript & React/Next.js  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Perform comprehensive pre-PR self-audits on all TypeScript & React/Next.js contributions before declaring task completion.

## Audit Checklist
1. **Inviolable Trust Hierarchy**:
   - Compiler/Typechecker passes cleanly (`eslint --max-warnings 0`).
   - All tests pass (`vitest run --coverage`).
   - Zero linter suppressions or unallowed ignores.
2. **Clean Sizing Verification**:
   - Zero files exceeding 300 LOC.
   - Zero methods exceeding 50 LOC.
3. **Living Memory Updates**:
   - `docs/wiki/memory/handoff.md` updated with accomplishments and next tasks.
   - `docs/wiki/log.md` appended if a milestone was reached.
   - Zero secrets, tokens, or PII committed.
4. **PR Template Compliance**:
   - Why and How sections filled in.
   - Zero empty checkboxes (`- [ ]`).

---

## Repository Conformance Gate
Before approving this review, run `oaef doctor` (native: `tool/governance.* doctor`) and `oaef lint`. A failing conformance or lint check blocks approval; unresolved findings MUST be recorded in `docs/wiki/memory/handoff.md` per the Inviolable Trust Hierarchy.
