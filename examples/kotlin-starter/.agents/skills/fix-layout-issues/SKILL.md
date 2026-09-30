---
name: fix-layout-issues
description: Specialized fix-layout-issues skill for Kotlin & Android/JVM under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: kotlin
  version: 1.0.0
---

# Fix Layout Issues (Kotlin & Android/JVM)

> **Stack Profile:** Kotlin & Android/JVM  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Diagnose and resolve layout overflows, rendering glitches, and responsive viewport bugs in Kotlin & Android/JVM.

## Structural Resolution Workflow
1. **Inspect Constraints**: Determine if the error is caused by unbounded parent constraints or conflicting flex/grid layouts.
2. **Never Use Hacky Offsets**: Avoid negative margins or arbitrary magic numbers.
3. **Responsive Boundaries**: Verify views adapt gracefully from small mobile screens to tablets and desktop viewports.
