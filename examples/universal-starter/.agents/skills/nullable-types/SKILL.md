---
name: nullable-types
description: >-
  Use when a value can be absent, nil, null or optional in Universal / Polyglot. Triggers on: "null", "optional", "nil", "guard clause", "defensive". Chains into: test-generator, run-static-analysis. Owns defensive null handling and non-nullable collection defaults in Universal / Polyglot: absence carries business meaning, guard clauses return early instead of nesting, and a collection parameter defaults to a constant empty collection rather than an optional list.
argument-hint: "[path or type name]"
license: MIT
metadata:
  framework: OAEF
  stack: universal
  version: 1.1.0
---

# Nullable Types & Absence Discipline (Universal / Polyglot)

> **Stack Profile:** Universal / Polyglot
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Make absence explicit and meaningful in every embedded language. The universal engine is a documented no-op for `CC-08`; each language family enforces the rule through its own typed mechanism, guided by `templates/rules/<stack>/rules.md`.

## Territory
- Any source file over `.dart`, `.ts`, `.tsx`, `.js`, `.mjs`, `.cjs`, `.jsx`, `.py`, `.go`, `.rs`, `.kt`, `.kts`, `.swift`, `.cs`, `.sh`, `.bash`.
- Public signatures: functions, methods, constructors and exported helpers.

## Conventions
- `null` / `nil` / `None` / `None`-equivalents are reserved for genuine business absence, never for "I have not set this yet".
- A required dependency is a constructor parameter, never a nullable field lazily filled later.
- Wire and configuration boundaries convert absent values into domain meaning once, at the edge.

## Non-Nullable Collections
- A collection parameter defaults to a constant empty collection, not an optional list.
- Language realization: Dart `const <T>[]`, TypeScript `readonly T[] = []`, Python `()`/immutable default via `field(default_factory=...)`, Kotlin `emptyList()`, Swift `[]`, C# `Array.Empty<T>()`.
- Go and Rust cannot express a non-null default: document the parameter as nil-safe and never mutate caller storage.
- `Optional[List]` / `list | None` / `Map<...>?` in a public signature is a finding under the matching language rule.

## Guard Clauses
- Validate at the top of the function, return or raise early, and keep the happy path unindented.
- One guard in the shared root beats N defensive branches at N call sites.
- A guard must route the error: return a typed result, raise a domain error, or log with context. Silence is forbidden.

## Repository Conformance Gate
- `oaef doctor` and `oaef lint` clean for the touched repository.
- `oaef clean-code` (native: `bash tool/governance.sh clean-code`).
- Consult `templates/rules/<stack>/rules.md` for the language family in play.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- No public signature exposes an optional collection without a constant-empty default or a documented nil-safe contract.
- Every guard clause routes absence to an explicit outcome.
- Optionality introduced on the wire is resolved once at the boundary.

## Anti-Patterns
- A nullable field that is always set before use.
- `if x is None: return None` repeated at every caller instead of a root guard.
- Defaulting a list parameter to `null` and mutating it inside the function.
