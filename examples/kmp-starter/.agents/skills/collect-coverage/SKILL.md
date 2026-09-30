---
name: collect-coverage
description: Specialized collect-coverage skill for Kotlin Multiplatform (KMP) under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.0.0
---

# Collect Coverage (Kotlin Multiplatform (KMP))

> **Stack Profile:** Kotlin Multiplatform (KMP)  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Extract and evaluate multiplatform test coverage using Kover or JaCoCo against baseline.json.

## Guidelines & Invariants
- Run ./gradlew koverXmlReport or ./gradlew jacocoTestReport.
- Parse XML/LCOV outputs and calculate line and branch coverage across commonMain.
- Reject builds failing to satisfy mandatory baseline floors (>= 95% lines, >= 90% branches).
- Apply the Monotonic Ratchet if coverage increased.
