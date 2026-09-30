---
name: run-static-analysis
description: Specialized run-static-analysis skill for TypeScript & React/Next.js under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: typescript-web
  version: 1.0.0
---

# Run Static Analysis (TypeScript & React/Next.js)

> **Stack Profile:** TypeScript & React/Next.js  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Execute strict static analysis and apply mechanical automated fixes in TypeScript & React/Next.js.

## Commands
```bash
# Static analysis check:
eslint --max-warnings 0

# Automated mechanical fixes:
eslint --fix
```

## Rules
- Zero warnings and zero errors allowed.
- Never add inline ignore comments to bypass rules. Fix the underlying architectural violation.
