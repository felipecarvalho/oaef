---
name: collect-coverage
description: >-
  Use when measuring, collecting or enforcing coverage for C# / .NET. Triggers on: "coverage", "lcov", "jacoco", "cobertura", "branches". Chains into: run-static-analysis, code-review. Extracts native C# / .NET coverage (LCOV, JaCoCo, Cobertura or Coverlet), compares the result with the baseline floors of the repository, and applies the Monotonic Ratchet so quality can only move up.
argument-hint: "[coverage artifact or scope]"
license: MIT
metadata:
  framework: OAEF
  stack: dotnet
  version: 1.1.0
---

# Collect Coverage (C# / .NET)

> **Stack Profile:** C# / .NET
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Extract native .NET coverage as Cobertura, compare it against the repository floors, and enforce the Monotonic Ratchet so coverage never regresses.

## Territory
- `TestResults/**/coverage.cobertura.xml` — Coverlet collector output.
- `coverage/lcov.info` — converted LCOV when the pipeline needs it.
- `tests/**/*.csproj` — coverage collector configuration.
- `docs/wiki/metrics/baseline.json` — floors and ratchet history.

## Coverage Extraction
- Collect with:
```bash
dotnet test --collect:"XPlat Code Coverage" --results-directory TestResults
```
- Coverlet writes Cobertura by default; convert with `reportgenerator` when LCOV is required.
- Exclude `*.generated.cs`, migrations and `obj/`/`bin/` from the report, never from the test run.
- Report line, branch and method percentages separately; branch coverage is the gate that matters.

## Monotonic Ratchet
- Read the floors from `baseline.json`; the effective floor is `max(configured, last recorded)`.
- If current coverage is higher, record the new value as the floor for the next change.
- If lower, fail the gate: restore the tests or justify with a recorded decision.
- Never lower a floor to pass; a genuine reduction requires an explicit ADR.

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint`, `oaef clean-code` or `dotnet run --project tool/Governance.csproj clean-code`.
- Run `dotnet test --collect:"XPlat Code Coverage"` and read the artifact.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Coverage artifact exists for the scope under review.
- Every metric is at or above its ratchet floor.
- The new floor is recorded when coverage improved.

## Anti-Patterns
- Excluding production files from coverage to raise the number.
- Treating line coverage as sufficient while branch coverage lags.
- Lowering a baseline floor without an accepted ADR.
