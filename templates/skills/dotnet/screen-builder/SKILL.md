---
name: screen-builder
description: Specialized screen-builder skill for C# & .NET Core under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: dotnet
  version: 1.0.0
---

# Screen Builder (C# & .NET Core)

> **Stack Profile:** C# & .NET Core  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Construct or refactor vertical feature modules and screens in C# & .NET Core adhering to Clean Sizing and layered architecture.

## Guidelines
- Maximum 300 LOC per file.
- Delegate state to `ASP.NET Core DI / MediatR`.
- Extract helper sub-components into separate dedicated files.
- Ensure all user-facing strings are localized or externalized.
