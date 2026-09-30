---
name: screen-builder
description: Specialized screen-builder skill for Kotlin & Android/JVM under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: kotlin
  version: 1.0.0
---

# Screen Builder (Kotlin & Android/JVM)

> **Stack Profile:** Kotlin & Android/JVM  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Construct or refactor vertical feature modules and screens in Kotlin & Android/JVM adhering to Clean Sizing and layered architecture.

## Guidelines
- Maximum 300 LOC per file.
- Delegate state to `Kotlin Coroutines / Flow & StateFlow`.
- Extract helper sub-components into separate dedicated files.
- Ensure all user-facing strings are localized or externalized.
