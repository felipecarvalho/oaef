---
name: architecture-audit
description: Specialized architecture-audit skill for C# & .NET Core under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: dotnet
  version: 1.0.0
---

# Architecture Audit (C# & .NET Core)

> **Stack Profile:** C# & .NET Core  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Audit layer coupling, dependency direction, and architectural modularity in C# & .NET Core.

## Invariants
- Dependencies must point inwards towards core domain contracts.
- High-level business logic must not depend on low-level UI or database details.
- Audit file sizes and cyclomatic complexity using `Roslyn Analyzer metrics`.
