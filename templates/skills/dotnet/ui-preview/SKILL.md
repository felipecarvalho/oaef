---
name: ui-preview
description: >-
  Use when a component or screen must be inspected in isolation before it is wired into the application in C# / .NET. Triggers on: "preview", "storybook", "isolated render". Chains into: test-generator, run-static-analysis. Provides isolated preview harnesses for C# / .NET: loading, success, empty and error states are rendered without booting the full runtime, so layout, tokens and typography are validated before integration.
argument-hint: "[component or screen name]"
license: MIT
metadata:
  framework: OAEF
  stack: dotnet
  version: 1.1.0
---

# UI Preview (C# / .NET)

> **Stack Profile:** C# / .NET
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Render a component, page or view model in isolation across every state, so layout, tokens and typography are validated without launching the whole application or the real backend.

## Territory
- `src/<Project>/Presentation/Shared/Components/` — the components to preview.
- `src/<Project>/Presentation/Features/<Feature>/` — screen-level previews.
- `previews/` or `src/<Project>.Previews/` — preview host projects.
- `tests/**/*ComponentTests.cs` — deterministic state snapshots.

## Preview Harness
- MAUI: a lightweight preview project hosting the component with fake data and a state switcher.
- Blazor: a preview page/route rendering the component against a stub view model.
- Each preview renders at least Loading, success, empty and error states.
- Feed deterministic `record` fixtures; inject a fake service; never touch the network.
- Keep preview hosts excluded from production publish (`Condition="'$(Configuration)' == 'Debug'"` when needed).

## State Matrix
- Loading: skeleton or spinner with no layout shift on resolve.
- Success: representative data sized to expose long text and overflow early.
- Empty: explicit empty state carrying a next action.
- Error: a rendered retry path, never a bare toast.
- Narrow and wide: re-render at compact and expanded widths.
- Record the preview fixture path in `docs/wiki/log.md` for reproducibility.

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint`, `oaef clean-code` or `dotnet run --project tool/Governance.csproj clean-code`.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every state renders in isolation with no backend running.
- The preview host builds with `dotnet build /warnaserror`.
- Preview fixtures are shared with `test-generator` factories, not duplicated.

## Anti-Patterns
- Previews that boot the whole app and hit live services.
- Hardcoded colorful data that hides real empty/error states.
- Preview code shipped in the release artifact without a guard.
