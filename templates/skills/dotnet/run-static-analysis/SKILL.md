---
name: run-static-analysis
description: Specialized run-static-analysis skill for C# & .NET Core under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: dotnet
  version: 1.0.0
---

# Run Static Analysis (C# & .NET Core)

> **Stack Profile:** C# & .NET Core  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Execute strict static analysis and apply mechanical automated fixes in C# & .NET Core.

## Commands
```bash
# Static analysis check:
dotnet format --verify-no-changes

# Automated mechanical fixes:
dotnet format
```

## Rules
- Zero warnings and zero errors allowed.
- Never add inline ignore comments to bypass rules. Fix the underlying architectural violation.
