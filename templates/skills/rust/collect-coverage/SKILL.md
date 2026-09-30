---
name: collect-coverage
description: Specialized collect-coverage skill for Rust under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: rust
  version: 1.0.0
---

# Collect Coverage (Rust)

> **Stack Profile:** Rust  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Execute test coverage extraction and verify mathematical compliance against `docs/wiki/metrics/baseline.json`.

## Commands
```bash
# Execute test suite with coverage instrumentation:
cargo tarpaulin --out Lcov

# Generated coverage report location:
tarpaulin-report.lcov
```

## Audit Targets
- Verify line coverage is `>= 95.0%` (or above current baseline floor).
- Verify branch coverage is `>= 90.0%`.
- If coverage improved, record the new floor with the Monotonic Ratchet.
