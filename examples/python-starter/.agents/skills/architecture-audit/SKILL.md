---
name: architecture-audit
description: Specialized architecture-audit skill for Python 3 & FastAPI under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: python
  version: 1.0.0
---

# Architecture Audit (Python 3 & FastAPI)

> **Stack Profile:** Python 3 & FastAPI  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Audit layer coupling, dependency direction, and architectural modularity in Python 3 & FastAPI.

## Invariants
- Dependencies must point inwards towards core domain contracts.
- High-level business logic must not depend on low-level UI or database details.
- Audit file sizes and cyclomatic complexity using `Radon cyclomatic & AST inspection`.
