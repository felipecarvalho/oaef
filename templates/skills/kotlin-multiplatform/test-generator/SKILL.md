---
name: test-generator
description: Specialized test-generator skill for Kotlin Multiplatform (KMP) under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.0.0
---

# Test Generator (Kotlin Multiplatform (KMP))

> **Stack Profile:** Kotlin Multiplatform (KMP)  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Generate comprehensive unit and integration tests using kotlin.test, Mockative/MockK, and kotlinx-coroutines-test.

## Guidelines & Invariants
- Write test suites in commonTest for maximum cross-platform verification.
- Test StateFlow and Flow emissions deterministically with kotlinx-coroutines-test.
- Assert edge cases and branch branches to satisfy >= 90% branch coverage.
