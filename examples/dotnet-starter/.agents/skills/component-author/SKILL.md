---
name: component-author
description: >-
  Use when authoring or extracting a reusable component, widget, button, card or modal in C# / .NET. Triggers on: "component", "widget", "button", "card", "modal". Chains into: ui-preview, responsive-layout, test-generator. Authors reusable C# / .NET surfaces from design-system tokens: one responsibility per component, tokens instead of literals, and a contract that serves every consumer without a bespoke variant.
argument-hint: "[component name]"
license: MIT
metadata:
  framework: OAEF
  stack: dotnet
  version: 1.1.0
---

# Component Author (C# / .NET)

> **Stack Profile:** C# / .NET
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Extract or author a reusable MAUI/Blazor component with a stable contract, token-driven styling and no consumer-specific branches, so one definition serves every call site.

## Territory
- `src/<Project>/Presentation/Shared/Components/` — reusable MAUI controls.
- `src/<Project>/Presentation/Shared/` — Blazor `.razor` components.
- `src/<Project>/Presentation/Resources/Styles/`, `wwwroot/css/tokens.css` — token sources.
- `tests/**/*ComponentTests.cs` — component tests.

## Component Contract
- One responsibility per component; a name with `And` signals a split.
- Inputs are typed parameters (`record` bag or explicit properties); never `object` or a string dictionary.
- Bindable properties are immutable in intent; when a collection parameter exists it is non-null with an `Array.Empty<T>()` default (`CC-08`).
- Expose events/callbacks for consumer reactions; no business logic inside the component.
- No service-locator resolution inside a component (`CC-07`).
- A component owns no application state and no data fetching; it renders what it receives.

## Token Discipline
- Colors, spacing, radius and typography come from tokens (`StaticResource`, CSS variables), never literals.
- Token names follow the design-system vocabulary; never invent a parallel scale.
- A hardcoded `Color.FromArgb("#FF0000")` or `margin: 13px` is a defect.
- State variants (default/hover/pressed/disabled) are declared through the token set, not inline overrides.
- Verify contrast and touch-target size; accessibility is part of the token contract.

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint`, `oaef clean-code` or `dotnet run --project tool/Governance.csproj clean-code`.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The component builds with `dotnet build /warnaserror` and renders every declared state.
- No literal style value remains in the component.
- A consumer can use it without a bespoke variant or wrapper.

## Anti-Patterns
- Boolean flag parameters that switch layout (`IsCompact`, `IsModal`) — split the component.
- Copy-pasting a shared component into a feature folder.
- Styling with inline literal colors or magic spacing.
