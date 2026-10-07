---
name: nullable-types
description: >-
  Use when a value can be absent, nil, null or optional in React Native. Triggers on: "null", "optional", "nil", "guard clause", "defensive". Chains into: test-generator, run-static-analysis. Owns defensive null handling and non-nullable collection defaults in React Native: absence carries business meaning, guard clauses return early instead of nesting, and a collection parameter defaults to a constant empty collection rather than an optional list.
argument-hint: "[path or type name]"
license: MIT
metadata:
  framework: OAEF
  stack: react-native
  version: 1.1.0
---

# Nullable Types (React Native)

> **Stack Profile:** React Native
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Make absence explicit and collections total. A nullable value is a business statement, never a default. TypeScript strict mode surfaces `null`/`undefined` at the boundary, so the type system is the first guard.

## Territory
- `src/**/*.{ts,tsx}` — public signatures and exported types.
- `src/features/<feature>/{domain,data}` — entities, mappers and repositories.
- `src/components/`, `src/shared/` — props contracts of reusable surfaces.
- `src/features/<feature>/presentation` — hooks and view models.

## Conventions
- Enable `strictNullChecks`; never widen a type with `any` or a non-null `!` assertion to silence the compiler.
- `null`/`undefined` is reserved for genuine business absence: "no selected session", "no cached analytics payload".
- Prefer an explicit union (`type Selection = { kind: 'none' } | { kind: 'item'; value: Item }`) over an optional field when the absence carries behaviour.
- Distinguish `undefined` (not provided) from `null` (explicitly empty) only when both are meaningful; otherwise pick one.
- Never return a nullable collection; return `[]`.

## Non-Nullable Collections
- A collection prop or parameter defaults to a module-level constant empty array:
  `const EMPTY_ITEMS: readonly Item[] = Object.freeze([]);`
- Signature: `items?: readonly Item[]` with `items = EMPTY_ITEMS` at the parameter, never `items?.map(...)` at every use site.
- The constant is frozen and shared so referential equality holds and `useMemo` dependencies stay stable across renders (`CC-08`).
- Do not call `useState<Item[] | null>(null)`; start from the empty array and model loading with a separate status field.

## Guard Clauses
- Return early on absence; do not nest the happy path inside `if (value)`:
  `if (session == null) return <EmptyState />;`
- One guard at the boundary (mapper or hook), not repeated optional chaining in every consumer.
- Centralise defaulting once; consumers may assume the narrowed type afterwards.
- Use `== null` (covers both `null` and `undefined`) when either is acceptable; use explicit comparison when only one is.

## Repository Conformance Gate
- Run `oaef doctor` (native: `node tool/governance.mjs doctor`).
- Run `oaef lint` (native: `npx eslint .`).
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`); `CC-08` is blocking in strict.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- No optional collection parameter without a constant empty default.
- Absence is narrowed by a guard clause, not by scattered optional chaining.
- No `!` assertion or `any` used to dodge the strict null checker.

## Anti-Patterns
- `items?.map(...)` repeated in every consumer.
- `useState<T[] | null>(null)` for what is conceptually an empty list.
- A single-letter catch or lambda binding used to mask an untyped `unknown`.
- Swallowing a null case where the domain requires an error.
