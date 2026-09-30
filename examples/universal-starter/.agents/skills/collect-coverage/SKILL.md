---
name: collect-coverage
description: Specialized collect-coverage skill for Universal / Polyglot under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: universal
  version: 1.0.0
---

# Collect Coverage (Universal / Polyglot)

> **Stack Profile:** Universal / Polyglot  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Execute test coverage extraction and verify mathematical compliance against `docs/wiki/metrics/baseline.json`.

## Commands
```bash
# Execute test suite with coverage instrumentation:
bash test.sh

# Generated coverage report location:
coverage.lcov
```

## Audit Targets
- Verify line coverage is `>= 95.0%` (or above current baseline floor).
- Verify branch coverage is `>= 90.0%`.
- If coverage improved, record the new floor with the Monotonic Ratchet.
