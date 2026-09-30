---
name: run-static-analysis
description: Specialized run-static-analysis skill for Swift & Apple Platforms under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: swift
  version: 1.0.0
---

# Run Static Analysis (Swift & Apple Platforms)

> **Stack Profile:** Swift & Apple Platforms  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Execute strict static analysis and apply mechanical automated fixes in Swift & Apple Platforms.

## Commands
```bash
# Static analysis check:
swiftlint --strict

# Automated mechanical fixes:
swiftlint --fix
```

## Rules
- Zero warnings and zero errors allowed.
- Never add inline ignore comments to bypass rules. Fix the underlying architectural violation.
