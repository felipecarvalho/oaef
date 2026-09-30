---
name: architecture-audit
description: Specialized architecture-audit skill for Kotlin & Android/JVM under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: kotlin
  version: 1.0.0
---

# Architecture Audit (Kotlin & Android/JVM)

> **Stack Profile:** Kotlin & Android/JVM  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Audit layer coupling, dependency direction, and architectural modularity in Kotlin & Android/JVM.

## Invariants
- Dependencies must point inwards towards core domain contracts.
- High-level business logic must not depend on low-level UI or database details.
- Audit file sizes and cyclomatic complexity using `Detekt cyclomatic complexity analyzer`.
