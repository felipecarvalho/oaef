---
name: collect-coverage
description: Specialized collect-coverage skill for Dart & Flutter under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: dart-flutter
  version: 1.0.0
---

# Collect Coverage (Dart & Flutter)

> **Stack Profile:** Dart & Flutter  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Execute test coverage extraction and verify mathematical compliance against `docs/wiki/metrics/baseline.json`.

## Commands
```bash
# Execute test suite with coverage instrumentation:
flutter test --coverage

# Generated coverage report location:
coverage/lcov.info
```

## Audit Targets
- Verify line coverage is `>= 95.0%` (or above current baseline floor).
- Verify branch coverage is `>= 90.0%`.
- If coverage improved, record the new floor with the Monotonic Ratchet.
