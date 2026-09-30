---
name: nullable-types
description: Specialized nullable-types skill for Go (Golang) under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: go
  version: 1.0.0
---

# Nullable Types (Go (Golang))

> **Stack Profile:** Go (Golang)  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Apply defensive, idiomatic null-safety and missing-value handling in Go (Golang).

## Conventions
- **Philosophy**: Explicit nil checking with error wrapping via fmt.Errorf("%w").
- **Guard Clauses**: Validate inputs at function entrypoints and return early.
- **Zero Deep Nesting**: Replace deeply nested `if` statements with pattern matching or early exits.
- **Model Absence Explicitly**: Never use sentinel values (like -1 or empty string) when absence should be represented by null/optional.
