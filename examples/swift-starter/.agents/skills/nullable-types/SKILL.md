---
name: nullable-types
description: Specialized nullable-types skill for Swift & Apple Platforms under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: swift
  version: 1.0.0
---

# Nullable Types (Swift & Apple Platforms)

> **Stack Profile:** Swift & Apple Platforms  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Apply defensive, idiomatic null-safety and missing-value handling in Swift & Apple Platforms.

## Conventions
- **Philosophy**: Optional unwrapping via guard let and if let.
- **Guard Clauses**: Validate inputs at function entrypoints and return early.
- **Zero Deep Nesting**: Replace deeply nested `if` statements with pattern matching or early exits.
- **Model Absence Explicitly**: Never use sentinel values (like -1 or empty string) when absence should be represented by null/optional.
