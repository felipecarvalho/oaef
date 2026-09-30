---
name: screen-builder
description: Specialized screen-builder skill for Kotlin Multiplatform (KMP) under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.0.0
---

# Screen Builder (Kotlin Multiplatform (KMP))

> **Stack Profile:** Kotlin Multiplatform (KMP)  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Construct complete vertical feature screens in Compose Multiplatform following Clean Sizing.

## Guidelines & Invariants
- Structure screens using the Page/View separation pattern.
- Delegate state management to a Multiplatform ViewModel or Decompose Component with StateFlow.
- Keep route entrypoint files <= 200 LOC by extracting sub-components into separate files.
