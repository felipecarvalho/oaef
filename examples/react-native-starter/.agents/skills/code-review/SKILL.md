---
name: code-review
description: Specialized code-review skill for React Native under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: react-native
  version: 1.0.0
---

# Code Review (React Native)

> **Stack Profile:** React Native  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Execute pre-PR code review against OAEF Quality Gates, Clean Code naming, and React Native best practices.

## Guidelines & Invariants
- Verify zero unallowed ESLint suppressions (only @typescript-eslint/no-deprecated permitted for third-party libs).
- Enforce StyleSheet.create usage and ban inline style objects in render loops.
- Verify automated Jest tests meet baseline coverage floors (>= 95% lines, >= 90% branches).

---

## Repository Conformance Gate
Before approving this review, run `oaef doctor` (native: `tool/governance.* doctor`) and `oaef lint`. A failing conformance or lint check blocks approval; unresolved findings MUST be recorded in `docs/wiki/memory/handoff.md` per the Inviolable Trust Hierarchy.
