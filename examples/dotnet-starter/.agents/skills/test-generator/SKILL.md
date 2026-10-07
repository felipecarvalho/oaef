---
name: test-generator
description: >-
  Use when writing or expanding automated tests, mocks or fixtures for C# / .NET. Triggers on: "test", "coverage", "mock", "fixture". Chains into: collect-coverage, run-static-analysis. Generates C# / .NET tests with the AAA pattern and one DRY factory per entity: unit, component and integration coverage of the happy path and of every error branch, with deterministic data and no dead parameters.
argument-hint: "[target class or module]"
license: MIT
metadata:
  framework: OAEF
  stack: dotnet
  version: 1.1.0
---

# Test Generator (C# / .NET)

> **Stack Profile:** C# / .NET
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Generate deterministic xUnit/NUnit tests that prove behavior and every error branch, driven by one DRY factory per entity and NSubstitute-style doubles instead of hand-built literals.

## Territory
- `tests/<Project>.UnitTests/**/*.cs` — unit tests.
- `tests/<Project>.IntegrationTests/**/*.cs` — integration tests.
- `src/**/*Tests.cs` — colocated test files where the project keeps them.
- `*.csproj` for the test project and its analyzers.

## Testing Pyramid
- Unit: fast, no I/O, one behavior per test, AAA layout with blank-line separation.
- Component: view model and MAUI/Blazor component rendered with fakes.
- Integration: real adapters against a disposable fixture, still deterministic.
- Every public method gets at least the happy path plus each error branch.

## DRY Test Factories (make*)
- Declare one local factory per entity, named `Make<Entity>()`, with defaults for every field.
- The factory exposes only the parameters that actually vary across call sites.
- Delete dead parameters (always `null`, always default, never read).
- An optional collection parameter defaults to a constant empty collection, not `null`.
```csharp
private static Booking MakeBooking(Guid? id = null, BookingStatus status = BookingStatus.Pending) =>
    new(id ?? Guid.Empty, "customer-1", status);
```
- Share factories between preview harnesses and tests; never duplicate literals.
- Data is deterministic: no ambient clock, no randomness, no network.

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint`, `oaef clean-code` or `dotnet run --project tool/Governance.csproj clean-code`.
- Run `dotnet test` before handing off.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `dotnet test` is green and every new branch is exercised.
- Every entity has exactly one factory.
- No test depends on wall-clock time or external services.

## Anti-Patterns
- Copy-pasting literals into every test instead of using a factory.
- Factories with a dozen rarely-used parameters.
- Over-mocking that asserts implementation rather than behavior.
