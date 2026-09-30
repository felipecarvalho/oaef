---
name: nullable-types
description: Specialized nullable-types skill for TypeScript & React/Next.js under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: typescript-web
  version: 1.0.0
---

# Nullable Types (TypeScript & React/Next.js)

> **Stack Profile:** TypeScript & React/Next.js  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Apply defensive, idiomatic null-safety and missing-value handling in TypeScript & React/Next.js.

## Conventions
- **Philosophy**: Strict null checks with optional chaining (?.) and nullish coalescing (??).
- **Guard Clauses**: Validate inputs at function entrypoints and return early.
- **Zero Deep Nesting**: Replace deeply nested `if` statements with pattern matching or early exits.
- **Model Absence Explicitly**: Never use sentinel values (like -1 or empty string) when absence should be represented by null/optional.
