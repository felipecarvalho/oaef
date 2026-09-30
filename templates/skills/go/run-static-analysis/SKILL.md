---
name: run-static-analysis
description: Specialized run-static-analysis skill for Go (Golang) under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: go
  version: 1.0.0
---

# Run Static Analysis (Go (Golang))

> **Stack Profile:** Go (Golang)  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Execute strict static analysis and apply mechanical automated fixes in Go (Golang).

## Commands
```bash
# Static analysis check:
golangci-lint run

# Automated mechanical fixes:
go fmt ./...
```

## Rules
- Zero warnings and zero errors allowed.
- Never add inline ignore comments to bypass rules. Fix the underlying architectural violation.
