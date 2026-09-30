---
name: component-author
description: Specialized component-author skill for Kotlin Multiplatform (KMP) under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.0.0
---

# Component Author (Kotlin Multiplatform (KMP))

> **Stack Profile:** Kotlin Multiplatform (KMP)  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Author modular, reusable Compose Multiplatform UI components following design tokens.

## Guidelines & Invariants
- Implement UI components in commonMain using Jetpack Compose Multiplatform.
- Never create helper rendering methods (prohibit _build* or render* functions). Extract each sub-view into a dedicated @Composable.
- Ensure components are stateless and accept state and event callbacks explicitly.
- Provide @Preview annotations for desktop/Android visual inspection.
