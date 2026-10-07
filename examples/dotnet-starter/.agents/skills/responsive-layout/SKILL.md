---
name: responsive-layout
description: >-
  Use when a surface must adapt to another screen size, form factor or payload shape in C# / .NET. Triggers on: "responsive", "adaptive", "breakpoint", "tablet", "foldable", "viewport". Chains into: ui-preview, test-generator. Owns adaptive design in C# / .NET: breakpoints, safe areas, dynamic type and foldables for interactive surfaces, and payload shaping, pagination, content negotiation and streaming backpressure for headless ones.
argument-hint: "[breakpoint or surface name]"
license: MIT
metadata:
  framework: OAEF
  stack: dotnet
  version: 1.1.0
---

# Responsive Layout (C# / .NET)

> **Stack Profile:** C# / .NET
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Make every C# / .NET surface adapt: interactive surfaces respond to breakpoints, safe areas and form factors; service-shaped code shapes payloads, paginates and streams with backpressure instead of returning one unbounded payload.

## Territory
- `src/<Project>/Presentation/**/*.xaml`, `*.razor` — MAUI/Blazor layout surfaces.
- `src/<Project>/Domain/**/*.cs`, `src/<Project>/Data/**/*.cs` — API-shaped services and DTOs.
- `Program.cs`, `Startup.cs` — host and serializer composition.
- `tests/**/*.cs` — adaptivity and pagination tests.

## Adaptive Surface Design
- Interactive surfaces adapt through named breakpoints and platform-aware resources.
- Service surfaces adapt through payload shaping: projection, windowed pagination and negotiation.
- One shared decision (a layout state helper or a paging contract), never a copy per page.
- Both modes avoid parallelism for its own sake; adaptivity lives in one place.

## Breakpoint Strategy
- Define breakpoints once: compact `< 600dp`, medium `600–1024dp`, expanded `> 1024dp`.
- MAUI: `<VisualStateManager>` with `<AdaptiveTrigger MinWindowWidth="...">` and `OnIdiom`/`OnPlatform` for form factor.
- Blazor: CSS `@media` and `@container` queries on component-level containers.
- Respect safe areas and insets; scale text through platform font settings, not fixed sizes.
- Foldables: react to `DeviceDisplay`/spanning when the platform reports posture changes.
- Headless adaptivity: cursor pagination, `Accept`-based content negotiation, ETag caching and schema versioning.
- Backpressure: expose `IAsyncEnumerable<T>` and let the consumer pull; never materialize an unbounded `List<T>` in the response path.

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint`, `oaef clean-code` or `dotnet run --project tool/Governance.csproj clean-code`.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every breakpoint is named and defined once.
- No unbounded payload is returned from a service-shaped endpoint.
- The surface renders correctly on compact and expanded widths at minimum.

## Anti-Patterns
- Magic width numbers repeated across files.
- Fixed pixel typography ignoring user font scaling.
- Buffering an entire result set before serialization.
