---
name: screen-builder
description: >-
  Use when building or changing a screen, page, feature or user flow in C# / .NET. Triggers on: "screen", "page", "feature", "flow", "view". Chains into: ui-preview, responsive-layout, test-generator. Constructs vertical feature slices in C# / .NET inside the Clean Sizing bounds: state, presentation and routing arrive together, files stay under 300 lines, and the surface is previewable in isolation before integration.
argument-hint: "[screen or flow name]"
license: MIT
metadata:
  framework: OAEF
  stack: dotnet
  version: 1.1.0
---

# Screen Builder (C# / .NET)

> **Stack Profile:** C# / .NET
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Build a vertical feature slice in MAUI or Blazor: one page/route, its view model, its state and its data contract delivered together, small enough to review and previewable before wiring.

## Territory
- `src/<Project>/Presentation/Features/<Feature>/` — page/component, view model, state.
- `src/<Project>/Presentation/Features/<Feature>/*.xaml`, `*.razor` — markup surfaces.
- `src/<Project>/Domain/<Feature>/`, `src/<Project>/Data/<Feature>/` — feature contract and adapter.
- Routing/registration in `Program.cs`, `Startup.cs`, `AppShell.xaml`.

## Construction Steps
1. Define the feature contract (`record` request/response) in Domain; no nullable collections.
2. Implement the view model with one injected interface and command methods; no service-locator lookups.
3. Author the page/component consuming design-system tokens only.
4. Register the route/navigation in the shell and the dependency in the composition root.
5. Keep each file <= 300 lines; split sub-surfaces into components when it grows.
6. Add the isolated preview (`ui-preview`) and the adaptivity pass (`responsive-layout`).

## State & Routing Contract
- State is an immutable `record` with a small state machine (`Loading`, `Loaded`, `Empty`, `Error`).
- View model exposes observable state; the view binds, it never fetches.
- Navigation carries typed parameters, not string dictionaries.
- Errors surface as a rendered state, never as a swallowed `catch { }` (`CC-06`).
- No business logic in code-behind; markup calls commands only.

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint`, `oaef clean-code` or `dotnet run --project tool/Governance.csproj clean-code`.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The slice builds with `dotnet build /warnaserror` and every file is within Clean Sizing.
- The screen renders Loading/success/empty/error states through the view model.
- Route registration and composition-root wiring exist in the same change set.

## Anti-Patterns
- Fat code-behind mixing layout and data access.
- A "screen" that resolves services from a global container (`CC-07`).
- Feature files scattered outside the feature folder.
