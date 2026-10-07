---
name: fix-layout-issues
description: >-
  Use when a layout overflows, a constraint is unbounded or a render error breaks a surface in C# / .NET. Triggers on: "overflow", "unbounded", "layout", "layout broken", "render error". Chains into: test-generator, run-static-analysis. Diagnoses structural render defects in C# / .NET: it isolates the offending constraint, state or data shape, fixes the shared root cause instead of clipping the symptom, and proves the correction with a regression test.
argument-hint: "[symptom or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: dotnet
  version: 1.1.0
---

# Fix Layout Issues (C# / .NET)

> **Stack Profile:** C# / .NET
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Diagnose and correct structural render defects in MAUI/Blazor surfaces: overflow, unbounded constraints, clipped content and binding-driven re-render loops, fixed at the shared root.

## Territory
- `src/<Project>/Presentation/**/*.xaml`, `*.razor` — layout markup.
- `src/<Project>/Presentation/Features/**/*.cs` — view models feeding layout state.
- `src/<Project>/Presentation/Resources/Styles/` — styles affecting constraints.
- `tests/**/*ComponentTests.cs` — regression coverage.

## Triage Procedure
1. Reproduce with a deterministic fixture; capture the exact overflow or exception.
2. Identify the offending constraint: an unbounded parent, a missing `*` row/column, a fixed size inside a scroll region, an auto-size cycle.
3. Distinguish layout defect from data defect — a null or oversized collection may be the real cause (`nullable-types`).
4. Locate every other surface sharing the pattern (cascade), not just the reported file.
5. Fix the shared root: correct the constraint contract or normalize the data shape once.
6. Add a regression test rendering the failing state and asserting bounds.
7. Re-run the analyzer; do not silence a warning.

## Common Roots
- Nested scroll containers with unbounded height.
- `HorizontalStackLayout`/flex children without shrink constraints.
- A binding to a nullable value rendered without a placeholder.
- Re-render loop from a state mutation inside a render pass.

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint`, `oaef clean-code` or `dotnet run --project tool/Governance.csproj clean-code`.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The defect no longer reproduces with the recorded fixture.
- A regression test fails before the fix and passes after.
- The same pattern is corrected across every equivalent surface.

## Anti-Patterns
- Clipping or hiding overflowing content instead of fixing the constraint.
- Hardcoding a device width to make a screenshot pass.
- Fixing one screen while sibling screens keep the defect.
