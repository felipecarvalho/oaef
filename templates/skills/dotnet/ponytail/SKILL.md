---
name: ponytail
description: >-
  Use when adding, refactoring, simplifying or deleting code in C# / .NET. Triggers on: "new", "refactor", "add", "simple", "minimal", "YAGNI", "dead code", "delete", "remove". Chains into: screen-builder, component-author, nullable-types, code-review. Governs the seven-rung Simplicity Ladder across every C# / .NET source tree: it demands the smallest correct diff, forbids ceremonial layers and speculative abstraction, and routes every root cause to the single shared guard instead of per-call-site defensive branches.
argument-hint: "[mode: lite|full|ultra] [path]"
license: MIT
metadata:
  framework: OAEF
  stack: dotnet
  version: 1.1.0
---

# Ponytail — Simplicity Ladder (C# / .NET)

> **Stack Profile:** C# / .NET
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)

> **Attribution:** the Simplicity Ladder is inspired by Dietrich Gebert's *Ponytail* minimalism (smallest correct diff, zero AI slop).
> **Skill Class:** meta

## Mission
Govern every edit in a C# / .NET tree with the Simplicity Ladder: stop at the first rung that solves the real problem, keep the diff minimal, and delete dead weight before adding new weight.

## Territory
- `src/**/*.cs` and root-level `*.cs` — every production source file.
- `src/<Project>/Domain/`, `src/<Project>/Data/`, `src/<Project>/Presentation/` — layer projects.
- `tests/**/*.cs`, `*Tests.cs` — ladder applies to fixtures too, but factories stay real.
- `*.csproj`, `Directory.Packages.props` — dependency surface.

## Modes
- `lite` (default): apply sensible simplifications inside the touched file.
- `full`: question every rung for every symbol in scope; aggressively remove duplication.
- `ultra`: nothing survives without a caller and a test; delete unproven code.

## The N-Step Ladder
1. **YAGNI** — delete the requirement that does not exist yet.
2. **Reuse in the codebase** — the pattern already exists; use it instead of a twin.
3. **BCL primitive** — `LINQ`, `record`, pattern matching, `IReadOnlyList<T>`, `StringBuilder`, `System.Text.Json`, `Span<T>`.
4. **Platform-native capability** — MAUI/Blazor adaptive triggers, `System.Text.Json` source generation, `IAsyncEnumerable<T>` streaming.
5. **Already-installed dependency** — no new NuGet package for a solved problem.
6. **One-line idiomatic expression** — the smallest expression that is still readable.
7. **Smallest correct diff** — touch only what must change.

## Root-Cause Bug Fixing
- Search every caller before patching: `rg "MethodName\(" src`.
- Fix the shared root once (`ArgumentNullException.ThrowIfNull`, one validated invariant) instead of defensive `if` branches per call site.
- A guard clause repeated at three call sites is a design defect, not a fix.

## Complexity Taxonomy
- Ceremonial layer: pass-through service, wrapper that only forwards arguments, single-implementation interface with no mock need.
- Speculative abstraction: generic repository or base class with one concrete caller.
- Narration comment: restates the next line.
- Dead weight: unused `private` method, unused `using`, unreferenced project reference.

## // ponytail: Debt Markers
Declare a deliberate simplification in place:
```csharp
// ponytail: in-memory session store; introduce a distributed cache when a second replica exists
```
Audited by `PT-01` with `oaef ponytail debt` or `dotnet run --project tool/Governance.csproj ponytail-debt`.

## Safety Frontier
Never pruned to gain simplicity: input validation, error routing, privacy/consent, accessibility and every Quality Gate. Simplicity never licenses an unsafe shortcut.

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint`, `oaef clean-code` or `dotnet run --project tool/Governance.csproj clean-code`.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every symbol added has a caller; every deletion leaves `dotnet build /warnaserror` green.
- No ceremonial layer, narration comment or dead parameter remains.
- No `// ponytail:` marker exists without a ceiling and an evolution trigger.

## Anti-Patterns
- Adding an interface before a second implementation exists.
- "Utility" helpers that wrap a single BCL call.
- Refactoring untouched files inside an unrelated diff.
