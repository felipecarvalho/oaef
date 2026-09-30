---
name: run-static-analysis
description: Specialized run-static-analysis skill for Kotlin & Android/JVM under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: kotlin
  version: 1.0.0
---

# Run Static Analysis (Kotlin & Android/JVM)

> **Stack Profile:** Kotlin & Android/JVM  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Execute strict static analysis and apply mechanical automated fixes in Kotlin & Android/JVM.

## Commands
```bash
# Static analysis check:
./gradlew detekt

# Automated mechanical fixes:
./gradlew ktlintFormat
```

## Rules
- Zero warnings and zero errors allowed.
- Never add inline ignore comments to bypass rules. Fix the underlying architectural violation.
