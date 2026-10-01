---
name: architecture-audit
description: Specialized architecture-audit skill for Kotlin Multiplatform (KMP) under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.0.0
---

# Architecture Audit (Kotlin Multiplatform (KMP))

> **Stack Profile:** Kotlin Multiplatform (KMP)  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Audit layer coupling, source-set boundaries (commonMain vs platform targets), and dependency inversion in Kotlin Multiplatform.

## Guidelines & Invariants
- Ensure domain models, business logic, and Compose Multiplatform UI remain strictly inside commonMain.
- Verify that platform source sets (androidMain, iosMain, desktopMain) contain solely hardware/OS bridging via expect/actual or interfaces.
- Enforce that Android Context and iOS UIViewController never leak into commonMain.
- Check Clean Sizing bounds across all modules (<=300 LOC/file).

---

## Repository Conformance Gate
Before approving this review, run `oaef doctor` (native: `tool/governance.* doctor`) and `oaef lint`. A failing conformance or lint check blocks approval; unresolved findings MUST be recorded in `docs/wiki/memory/handoff.md` per the Inviolable Trust Hierarchy.
