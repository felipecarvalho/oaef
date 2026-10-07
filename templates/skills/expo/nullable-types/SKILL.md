---
name: nullable-types
description: >-
  Use when a value can be absent, nil, null or optional in Expo. Triggers on: "null", "optional", "nil",
  "guard clause", "defensive". Chains into: test-generator, run-static-analysis. Owns defensive null handling and
  non-nullable collection defaults in Expo: absence carries business meaning, guard clauses return early instead of
  nesting, and a collection parameter defaults to a constant empty collection rather than an optional list.
argument-hint: "[path or type name]"
license: MIT
metadata:
  framework: OAEF
  stack: expo
  version: 1.1.0
---

# Nullable Types (Expo)

> **Stack Profile:** Expo
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Keep absence meaningful and narrow. TypeScript `strict` and `strictNullChecks` must stay on; `null` and `undefined` are reserved for genuine absence, never for "not decided yet" or "the caller forgot". Collections are never optional.

## Territory
- `src/features/<feature>/domain/` - entities, value objects, and result types.
- `src/features/<feature>/presentation/` - hooks and components consuming optional data.
- `src/shared/`, `src/components/` - reusable surfaces and utilities.
- `app/` - route loaders and screens bridging navigation params into typed data.

## Conventions
- Enable `"strict": true` in `tsconfig.json`; never relax a flag to silence a null complaint.
- Model genuine absence with a union (`Session | undefined`) and document why it happens.
- Prefer a small discriminated union or `Result`-style type over a pile of optional fields.
- Ban non-null assertions (`!`) in production logic; narrow with a check or a guard.
- Persisted or transported values are validated at the boundary (route param, storage, response) before they enter domain types.

## Non-Nullable Collections
A collection parameter or return value is non-nullable and defaults to a constant empty collection:

```ts
function mergeItems(items: ReadonlyArray<Item> = EMPTY_ITEMS): Item[] { /* ... */ }
```

`items?: Item[] | undefined` in a public signature is a design smell (`CC-08`), not a type. React rendering of an empty list keeps the same code path as a populated one.

## Guard Clauses
Return early at the entry point instead of nesting the happy path:

```ts
function displayName(session: Session | undefined): string {
  if (session === undefined) return 'Guest';
  return session.displayName;
}
```

Validate route params and API payloads once at the edge, then pass narrowed non-null values inward. Null checks live at the boundary, not scattered through render trees.

## Repository Conformance Gate
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`) and clear every `CC-08` finding.
- Run `oaef lint` and `oaef doctor`; keep `tsc --noEmit` clean.
- Record unresolved nullability decisions in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `npx tsc --noEmit` reports zero errors with strict null checks enabled.
- No nullable collection parameter without a constant-empty default remains.
- Every absence branch is covered by a test in `__tests__/` or `test/`.

## Anti-Patterns
- Optional collection parameters (`items?: Item[]`) instead of a constant-empty default.
- Non-null assertions used to quiet the compiler.
- Treating `undefined` as "not loaded", "empty", and "errored" with a single field.
