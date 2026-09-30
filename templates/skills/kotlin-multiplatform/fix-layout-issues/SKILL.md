---
name: fix-layout-issues
description: Specialized fix-layout-issues skill for Kotlin Multiplatform (KMP) under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.0.0
---

# Fix Layout Issues (Kotlin Multiplatform (KMP))

> **Stack Profile:** Kotlin Multiplatform (KMP)  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Diagnose and resolve layout constraints, recomposition churn, and UI rendering defects in Compose Multiplatform.

## Guidelines & Invariants
- Inspect Modifier chains to prevent unbounded height or width exceptions.
- Use derivedStateOf and remember keys to eliminate unnecessary recompositions.
- Ensure edge-to-edge insets and safe areas adapt cleanly between Android WindowInsets and iOS safe area margins.
