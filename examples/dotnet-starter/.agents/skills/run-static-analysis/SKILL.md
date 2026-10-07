---
name: run-static-analysis
description: >-
  Use when the analyzer, linter or type checker reports findings in C# / .NET. Triggers on: "analyze", "lint", "typecheck", "warnings". Chains into: code-review. Runs the C# / .NET analyzer with warnings treated as errors and zero suppressions: every finding is fixed in the code instead of being silenced with an inline ignore directive, and machine-generated files stay the only exemption.
argument-hint: "[scope or analyzer]"
license: MIT
metadata:
  framework: OAEF
  stack: dotnet
  version: 1.1.0
---

# Run Static Analysis (C# / .NET)

> **Stack Profile:** C# / .NET
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Run the .NET compiler, analyzers and format checks with warnings as errors, and fix every finding at its source instead of silencing it.

## Territory
- `*.sln`, `*.csproj` — `TreatWarningsAsErrors`, `AnalysisLevel`, `EnforceCodeStyleInBuild`.
- `src/**/*.cs` — production sources under analysis.
- `.editorconfig`, `Directory.Build.props` — analyzer severity configuration.
- `tests/**/*.cs` — test sources, held to the same analyzer level.

## Analyzer Invocation
```bash
dotnet build /warnaserror
dotnet format --verify-no-changes
dotnet run --project tool/Governance.csproj clean-code
```
- Enable `dotnet_diagnostic` severity at the repository level, not per file.
- `AnalysisLevel` and `EnforceCodeStyleInBuild=true` live in `Directory.Build.props`.
- Run the governance engine (`oaef lint`) for `CC-*` and `SK-*` findings alongside the compiler.

## Zero-Suppression Policy
- No `#pragma warning disable`, no `[SuppressMessage]`, no `NoWarn` for your own code.
- The only permitted exemptions are machine-generated files and a third-party deprecation during an active migration, scoped to the single call site.
- A nuisance warning is fixed by correcting the code or the analyzer configuration for everyone, never by an inline ignore.
- `dotnet format` output is applied, not reverted.

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint`, `oaef clean-code` or `dotnet run --project tool/Governance.csproj clean-code`.
- Run `dotnet build /warnaserror` and `dotnet format --verify-no-changes`.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `dotnet build /warnaserror` passes with zero warnings.
- `dotnet format --verify-no-changes` reports no diff.
- No unallowed suppression directive exists in the change set.

## Anti-Patterns
- `#pragma warning disable` used to land a change.
- Lowering the repository `AnalysisLevel` to hide findings.
- Editing generated files to appease the analyzer.
