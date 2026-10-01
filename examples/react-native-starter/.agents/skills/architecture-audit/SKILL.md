---
name: architecture-audit
description: Specialized architecture-audit skill for React Native under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: react-native
  version: 1.0.0
---

# Architecture Audit (React Native)

> **Stack Profile:** React Native  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Audit module decoupling, New Architecture boundaries, and performance invariants in React Native.

## Guidelines & Invariants
- Ensure compatibility with the New Architecture (Fabric renderer, TurboModules, Bridgeless).
- Verify typed Native Module specifications using TypeScript Codegen specs.
- Ensure business logic is cleanly decoupled from React Native UI components.

---

## Repository Conformance Gate
Before approving this review, run `oaef doctor` (native: `tool/governance.* doctor`) and `oaef lint`. A failing conformance or lint check blocks approval; unresolved findings MUST be recorded in `docs/wiki/memory/handoff.md` per the Inviolable Trust Hierarchy.
