---
name: run-static-analysis
description: Specialized run-static-analysis skill for Expo under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: expo
  version: 1.0.0
---

# Run Static Analysis (Expo)

> **Stack Profile:** Expo  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Run npx expo lint and tsc --noEmit with zero warnings tolerance.

## Guidelines & Invariants
- Execute npx expo lint and tsc --noEmit.
- Resolve all type errors without suppressions.
- Verify parity between app.json and TypeScript configuration.
