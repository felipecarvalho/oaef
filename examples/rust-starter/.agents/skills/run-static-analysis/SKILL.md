---
name: run-static-analysis
description: Specialized run-static-analysis skill for Rust under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: rust
  version: 1.0.0
---

# Run Static Analysis (Rust)

> **Stack Profile:** Rust  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Execute strict static analysis and apply mechanical automated fixes in Rust.

## Commands
```bash
# Static analysis check:
cargo clippy -- -D warnings

# Automated mechanical fixes:
cargo fmt
```

## Rules
- Zero warnings and zero errors allowed.
- Never add inline ignore comments to bypass rules. Fix the underlying architectural violation.
