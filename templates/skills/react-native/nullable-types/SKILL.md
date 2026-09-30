---
name: nullable-types
description: Specialized nullable-types skill for React Native under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: react-native
  version: 1.0.0
---

# Nullable Types (React Native)

> **Stack Profile:** React Native  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Enforce strict TypeScript null and undefined handling across React Native code.

## Guidelines & Invariants
- Enable and satisfy strictNullChecks in tsconfig.json.
- Use optional chaining (?.) and nullish coalescing (??) instead of loose truthiness checks.
- Avoid non-null assertions (!) in business logic.
