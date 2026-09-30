---
name: screen-builder
description: Specialized screen-builder skill for Go (Golang) under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: go
  version: 1.0.0
---

# Screen Builder (Go (Golang))

> **Stack Profile:** Go (Golang)  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Construct or refactor vertical feature modules and screens in Go (Golang) adhering to Clean Sizing and layered architecture.

## Guidelines
- Maximum 300 LOC per file.
- Delegate state to `Service struct injection`.
- Extract helper sub-components into separate dedicated files.
- Ensure all user-facing strings are localized or externalized.
