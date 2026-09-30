---
name: architecture-audit
description: Specialized architecture-audit skill for Expo under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: expo
  version: 1.0.0
---

# Architecture Audit (Expo)

> **Stack Profile:** Expo  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Audit Expo Router file structure, Config Plugins compliance, and managed workflow boundaries.

## Guidelines & Invariants
- Verify route files in app/ act strictly as coordinators and delegate logic to src/.
- Ensure all native configurations are declared via Expo Config Plugins in app.json / app.config.ts.
- Prohibit direct edits to transient prebuild folders (android/ and ios/).
