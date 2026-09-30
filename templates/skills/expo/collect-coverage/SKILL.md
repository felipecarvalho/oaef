---
name: collect-coverage
description: Specialized collect-coverage skill for Expo under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: expo
  version: 1.0.0
---

# Collect Coverage (Expo)

> **Stack Profile:** Expo  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Extract and verify test coverage using jest-expo and LCOV reporting.

## Guidelines & Invariants
- Run npm test -- --coverage --coverageReporters=lcov using jest-expo preset.
- Audit line and branch coverage against baseline.json floors.
- Update baseline floor if coverage improved (Monotonic Ratchet).
