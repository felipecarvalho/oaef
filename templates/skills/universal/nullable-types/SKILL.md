---
name: nullable-types
description: Specialized nullable-types skill for Universal / Polyglot under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: universal
  version: 1.0.0
---

# Nullable Types (Universal / Polyglot)

> **Stack Profile:** Universal / Polyglot  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Apply defensive, idiomatic null-safety and missing-value handling in Universal / Polyglot.

## Conventions
- **Philosophy**: Defensive guards and input validation.
- **Guard Clauses**: Validate inputs at function entrypoints and return early.
- **Zero Deep Nesting**: Replace deeply nested `if` statements with pattern matching or early exits.
- **Model Absence Explicitly**: Never use sentinel values (like -1 or empty string) when absence should be represented by null/optional.
