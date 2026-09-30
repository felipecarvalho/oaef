---
name: screen-builder
description: Specialized screen-builder skill for Rust under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: rust
  version: 1.0.0
---

# Screen Builder (Rust)

> **Stack Profile:** Rust  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Construct or refactor vertical feature modules and screens in Rust adhering to Clean Sizing and layered architecture.

## Guidelines
- Maximum 300 LOC per file.
- Delegate state to `Arc<dyn Trait> / Actor pattern`.
- Extract helper sub-components into separate dedicated files.
- Ensure all user-facing strings are localized or externalized.
