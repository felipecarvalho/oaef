---
name: nullable-types
description: Specialized nullable-types skill for Kotlin Multiplatform (KMP) under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.0.0
---

# Nullable Types (Kotlin Multiplatform (KMP))

> **Stack Profile:** Kotlin Multiplatform (KMP)  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Enforce strict null-safety and defensive modeling in Kotlin Multiplatform.

## Guidelines & Invariants
- Strictly forbid the non-null assertion operator (!!).
- Use safe calls (?.), the Elvis operator (?:), and explicit guards (checkNotNull, requireNotNull).
- Model optional values explicitly; avoid ambiguous default sentinel values.
