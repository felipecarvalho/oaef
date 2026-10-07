---
name: nullable-types
description: >-
  Use when a value can be absent, nil, null or optional in TypeScript & Web. Triggers on: "null", "optional", "nil", "guard clause", "defensive". Chains into: test-generator, run-static-analysis. Owns defensive null handling and non-nullable collection defaults in TypeScript & Web: absence carries business meaning, guard clauses return early instead of nesting, and a collection parameter defaults to a constant empty collection rather than an optional list.
argument-hint: "[path or type name]"
license: MIT
metadata:
  framework: OAEF
  stack: typescript-web
  version: 1.1.0
---

# Nullable Types (TypeScript & Web)

> **Stack Profile:** TypeScript & Web
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission

Make absence explicit and rare. `null` and `undefined` are reserved for a genuine
business meaning ("no session", "no selection"); everywhere else the type system is
tightened so the absent case cannot occur. `strictNullChecks` is non-negotiable.

## Territory

- `src/**/*.ts`, `src/**/*.tsx` — production types and signatures.
- `src/features/<feature>/domain/` — domain entities and value objects.
- `src/features/<feature>/data/` — DTO parsing and boundary mapping.
- `src/shared/**`, `src/components/**` — public component props and shared helpers.

## Conventions

- Model absence with `T | null` only when it has business meaning; otherwise make the
  field required and non-optional.
- Prefer `undefined` for "not provided" and `null` for "explicitly empty"; do not mix the
  two for the same field.
- Return types are explicit: an optional return must be zero-argument overloads or a
  documented sentinel, not an untyped `T | undefined` leaking outward.
- Parse at the trust boundary. Once `src/features/*/data/` validates an external payload
  (schema or type guard), the inner layers receive a non-nullable shape.
- Never silence a real absence with `!` (non-null assertion) or `as T`; fix the type so
  the compiler proves it.

## Non-Nullable Collections

- A collection parameter defaults to a constant empty collection, not an optional list:

  ```ts
  export function rankResults(items: readonly string[] = EMPTY_RESULTS): number[] { … }
  ```

  where `const EMPTY_RESULTS: readonly string[] = Object.freeze([]);`.
- Signature rule (`CC-08`): `Array`, `ReadonlyArray`, `Map`, `Set` or `[]` parameters MUST
  NOT be optional or part of a union with `undefined`; supply a frozen empty default.
- `Object.freeze([])` is the shared constant; never allocate a fresh `[]` default per call.
- Do not return `null` in place of "no items" — return the frozen empty collection.

## Guard Clauses

Flatten nesting with early returns instead of `if` pyramids:

```ts
export function sessionLabel(session: Session | null): string {
  if (session === null) return "anonymous";
  if (!session.isActive) return "inactive";
  return session.displayName;
}
```

- Prefer optional chaining `session?.user?.name` and nullish coalescing `?? "anonymous"`
  for expression-level absence.
- Never use `||` for defaults where `0`, `""` or `false` are valid values.
- A guard clause performs the real check and returns; it does not wrap the rest of the
  body in an `else`.

## Repository Conformance Gate

- Run `oaef doctor`, `oaef lint`, `oaef clean-code` (native:
  `node tool/governance.mjs doctor|lint|clean-code`).
- Run `npx tsc --noEmit`; `CC-08` findings block under the strict profile.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria

- `npx tsc --noEmit` passes with `strictNullChecks` on and zero `!` assertions added.
- No optional collection parameter survives; each has a frozen empty default.
- Guard clauses replaced the nesting on every touched branch.

## Anti-Patterns

- `items?: string[]` in a public signature with `items && items.map(…)` at the call site.
- `!` or `as T` used to silence a nullable value instead of narrowing the type.
- `|| ""` defaults that also overwrite `0` and `false`.
- Returning `null` where "empty" is the correct business answer.
