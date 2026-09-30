---
name: code-review
description: Specialized code-review skill for Kotlin Multiplatform (KMP) under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.0.0
---

# Code Review (Kotlin Multiplatform (KMP))

> **Stack Profile:** Kotlin Multiplatform (KMP)  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Perform comprehensive pre-PR audits ensuring full compliance with OAEF Quality Gates, Clean Code, and KMP invariants.

## Guidelines & Invariants
- Verify zero unallowed suppressions (only @Suppress("DEPRECATION") and @file:Suppress("UNCHECKED_CAST") allowed).
- Audit Clean Sizing (files <= 300 LOC, methods <= 50 LOC).
- Verify that automated multiplatform tests pass with >= 95% line coverage.
- Confirm that docs/wiki/memory/handoff.md is updated with zero credentials or PII.
