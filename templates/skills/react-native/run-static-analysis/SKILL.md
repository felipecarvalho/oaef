---
name: run-static-analysis
description: Specialized run-static-analysis skill for React Native under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: react-native
  version: 1.0.0
---

# Run Static Analysis (React Native)

> **Stack Profile:** React Native  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Execute strict linting and typechecking via ESLint, Biome, and tsc --noEmit.

## Guidelines & Invariants
- Run npm run lint and npx tsc --noEmit.
- Treat all type errors and lint warnings as fatal (zero warnings policy).
- Ensure zero unallowed /* eslint-disable */ or @ts-ignore comments.
