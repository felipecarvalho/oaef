---
name: architecture-audit
description: Specialized architecture-audit skill for Rust under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: rust
  version: 1.0.0
---

# Architecture Audit (Rust)

> **Stack Profile:** Rust  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Audit layer coupling, dependency direction, and architectural modularity in Rust.

## Invariants
- Dependencies must point inwards towards core domain contracts.
- High-level business logic must not depend on low-level UI or database details.
- Audit file sizes and cyclomatic complexity using `Syn AST / Clippy metrics`.
