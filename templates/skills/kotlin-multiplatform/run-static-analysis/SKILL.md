---
name: run-static-analysis
description: Specialized run-static-analysis skill for Kotlin Multiplatform (KMP) under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.0.0
---

# Run Static Analysis (Kotlin Multiplatform (KMP))

> **Stack Profile:** Kotlin Multiplatform (KMP)  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Execute strict static analysis with detekt, ktlint, and the Kotlin compiler with all warnings as errors.

## Guidelines & Invariants
- Run ./gradlew detekt ktlintCheck.
- Enforce zero warnings with -Werror.
- Zero tolerance for unallowed @Suppress annotations; resolve root architectural issues directly.
