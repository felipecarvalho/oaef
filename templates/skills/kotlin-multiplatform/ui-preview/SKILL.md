---
name: ui-preview
description: Specialized ui-preview skill for Kotlin Multiplatform (KMP) under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.0.0
---

# Ui Preview (Kotlin Multiplatform (KMP))

> **Stack Profile:** Kotlin Multiplatform (KMP)  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Generate and maintain interactive Compose Multiplatform component previews.

## Guidelines & Invariants
- Annotate preview composables with @Preview from org.jetbrains.compose.ui.tooling.preview.
- Provide mock state data and theme providers for isolated preview rendering.
- Validate light and dark mode appearance without deploying to physical devices.
