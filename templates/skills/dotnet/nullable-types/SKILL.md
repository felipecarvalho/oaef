---
name: nullable-types
description: >-
  Use when a value can be absent, nil, null or optional in C# / .NET. Triggers on: "null", "optional", "nil", "guard clause", "defensive". Chains into: test-generator, run-static-analysis. Owns defensive null handling and non-nullable collection defaults in C# / .NET: absence carries business meaning, guard clauses return early instead of nesting, and a collection parameter defaults to a constant empty collection rather than an optional list.
argument-hint: "[path or type name]"
license: MIT
metadata:
  framework: OAEF
  stack: dotnet
  version: 1.1.0
---

# Nullable Types (C# / .NET)

> **Stack Profile:** C# / .NET
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Make absence explicit and collections total: Nullable Reference Types carry business meaning, guards fail fast at the entrypoint, and every collection parameter is non-null with a constant empty default.

## Territory
- `src/<Project>/Domain/**/*.cs`, `src/<Project>/Data/**/*.cs` — entities, DTOs, contracts.
- `src/<Project>/Presentation/**/*.cs` — view models that project optional data.
- `src/**/*.cs` — any public signature (`CC-08`).

## Conventions
- Enable `<Nullable>enable</Nullable>` per `*.csproj`; a warning is a defect.
- Use `T?` only when absence is a real business state; never as "caller forgot".
- Model outcomes with `Result<T>` or a discriminated `record` union, not with magic sentinels.
- Prefer pattern matching (`is not null`, `is { Length: > 0 }`, `switch` expressions) over layered `if`.
- Non-null assertion (`!`) stays banned in business logic; fix the flow instead.
- Validate inputs with `ArgumentNullException.ThrowIfNull(value)`.
- DTO mapping uses `required` members so the compiler proves initialization.

## Non-Nullable Collections
- A collection parameter or return value is non-null and defaults to `Array.Empty<T>()` (immutable in intent), never to `null`.
- Signature smell: `IEnumerable<Item>? items` or `List<Item>? items` (`CC-08`).
```csharp
public IReadOnlyList<Item> Filter(IReadOnlyList<Item> items, string query)
{
    ArgumentNullException.ThrowIfNull(items);
    return items.Where(item => item.Matches(query)).ToList();
}
```
- Expose `IReadOnlyList<T>`/`IReadOnlyDictionary<K,V>` across boundaries; keep `List<T>` private.
- Where a null collection is legacy-fixed, normalize once at the boundary and remove the optional at the signature.

## Guard Clauses
- Validate preconditions at the top of the method and return immediately; keep the happy path unindented.
- Extract compound conditions into named predicates (`IsExpired(session)`), never nest deeper than 2 levels.
- Separate error handling into its own method; a guard does one thing.
```csharp
public Session RequireActiveSession(Session? session)
{
    ArgumentNullException.ThrowIfNull(session);
    if (!session.IsActive) throw new SessionExpiredException(session.Id);
    return session;
}
```

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint`, `oaef clean-code` or `dotnet run --project tool/Governance.csproj clean-code` (`CC-08`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- No public collection signature is nullable.
- No `!` null-forgiving operator remains in business logic.
- `dotnet build /warnaserror` passes with nullable warnings enabled.

## Anti-Patterns
- Sentinel values (`-1`, `""`, `Guid.Empty`) standing in for absence.
- `if (x != null) { ... }` nesting instead of a guard clause.
- Nullable collections to "keep the API flexible".
