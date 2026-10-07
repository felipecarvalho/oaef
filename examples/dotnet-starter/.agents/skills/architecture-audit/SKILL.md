---
name: architecture-audit
description: >-
  Use when reviewing module boundaries, coupling or dependency direction in C# / .NET. Triggers on: "architecture", "boundary", "coupling", "cycle". Chains into: conformance-audit, code-review. Audits layer boundaries, cyclic dependencies and Clean Sizing inside C# / .NET: domain code never reaches outward, infrastructure never leaks inward, and every module keeps a single reason to change.
argument-hint: "[module path or boundary name]"
license: MIT
metadata:
  framework: OAEF
  stack: dotnet
  version: 1.1.0
---

# Architecture Audit (C# / .NET)

> **Stack Profile:** C# / .NET
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Prove that every C# / .NET project respects layer direction, dependency inversion and Clean Sizing, and that no assembly reference or namespace shortcut creates an upward or cyclic dependency.

## Territory
- `src/<Project>/Domain/` — entities, value objects, domain services, contracts.
- `src/<Project>/Data/`, `src/<Project>/Infrastructure/` — repositories, adapters.
- `src/<Project>/Presentation/` — view models, controllers, pages.
- `*.csproj`, `*.sln` — project references define the allowed graph.

## Boundary Checklist
- Domain references no `Microsoft.*` framework package beyond the BCL and owns its abstractions.
- Data implements interfaces declared by Domain; the `ProjectReference` points Domain -> nothing, Data -> Domain, Presentation -> Domain.
- No `using` in Domain pulls `System.Net.Http`, EF Core or any ORM.
- No cyclic project reference and no `InternalsVisibleTo` used to break a cycle.
- Concrete I/O (`new HttpClient(`, `DbContext`, file system) lives at the edge, never in Domain (`CC-10`).
- Cross-cutting concerns arrive as injected interfaces, not static helpers.

## Sizing Bounds
- File <= 300 physical lines (target <= 200); method <= 50 lines (target <= 30).
- One reason to change per class; a class name with `And`/`Manager`/`Helper` is a smell.
- Assembly dependency direction is acyclic: verify with `dotnet list <project> reference`.
- Duplication across layers is a signal to elevate a shared abstraction (Rule of Two), not to copy.

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint`, `oaef clean-code` or `dotnet run --project tool/Governance.csproj clean-code`.
- Run `dotnet list src/<Project> reference` to confirm the reference graph.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The reference graph is acyclic and points inward.
- Domain has zero infrastructure imports.
- Every oversize file or method is either split or recorded with a `// ponytail:` ceiling.

## Anti-Patterns
- `Helpers`/`Utils` static classes shared across layers.
- Domain depending on EF Core attributes.
- Presentation reaching directly into a database context.
