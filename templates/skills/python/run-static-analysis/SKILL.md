---
name: run-static-analysis
description: Specialized run-static-analysis skill for Python 3 & FastAPI under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: python
  version: 1.0.0
---

# Run Static Analysis (Python 3 & FastAPI)

> **Stack Profile:** Python 3 & FastAPI  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Execute strict static analysis and apply mechanical automated fixes in Python 3 & FastAPI.

## Commands
```bash
# Static analysis check:
ruff check && mypy --strict

# Automated mechanical fixes:
ruff check --fix
```

## Rules
- Zero warnings and zero errors allowed.
- Never add inline ignore comments to bypass rules. Fix the underlying architectural violation.
