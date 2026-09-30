---
name: collect-coverage
description: Specialized collect-coverage skill for React Native under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: react-native
  version: 1.0.0
---

# Collect Coverage (React Native)

> **Stack Profile:** React Native  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Collect and evaluate test coverage using Jest LCOV reporting.

## Guidelines & Invariants
- Run npm test -- --coverage --coverageReporters=lcov.
- Parse coverage/lcov.info and compare against docs/wiki/metrics/baseline.json.
- Apply Monotonic Ratchet when coverage exceeds baseline floor.
