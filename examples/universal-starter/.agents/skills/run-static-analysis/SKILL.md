---
name: run-static-analysis
description: Specialized run-static-analysis skill for Universal / Polyglot under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: universal
  version: 1.0.0
---

# Run Static Analysis (Universal / Polyglot)

> **Stack Profile:** Universal / Polyglot  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Execute strict static analysis and apply mechanical automated fixes in Universal / Polyglot.

## Commands
```bash
# Static analysis check:
bash lint.sh

# Automated mechanical fixes:
bash format.sh
```

## Rules
- Zero warnings and zero errors allowed.
- Never add inline ignore comments to bypass rules. Fix the underlying architectural violation.
