---
name: nullable-types
description: >-
  Use when a value can be absent, nil, null or optional in Swift. Triggers on: "null", "optional", "nil", "guard clause", "defensive". Chains into: test-generator, run-static-analysis. Owns defensive null handling and non-nullable collection defaults in Swift: absence carries business meaning, guard clauses return early instead of nesting, and a collection parameter defaults to a constant empty collection rather than an optional list.
argument-hint: "[path or type name]"
license: MIT
metadata:
  framework: OAEF
  stack: swift
  version: 1.1.0
---

# Nullable Types (Swift)

> **Stack Profile:** Swift
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Make absence explicit and deliberate. An `Optional` in Swift is a domain decision with business meaning, never a convenience default; defensive branching never replaces a well-typed model.

## Territory
- `Sources/` — production targets and their public APIs.
- `Sources/<Module>/{Domain,Data,Presentation}` — feature slice layers.
- `*.swift` at repository root.
- `Tests/` — regression tests that prove the absence policy.

## Conventions
- Model absence as an `enum` with associated values when it carries state, not parallel optionals.
- `if let`/`guard let` binds a descriptive name; never `let value = value`.
- Force-unwrap `!` is forbidden on production paths.
- `try?` that discards the error is a swallowed failure; route it instead.
- `Optional.map`/`Optional.flatMap` replace nested `if let` chains.

## Non-Nullable Collections
- A collection parameter defaults to a constant empty collection: `[T] = []`, not `[T]?`.
- Public signatures keep non-optional `[T]`, `[K: V]` and `Set<T>` (`CC-08`).
- Prefer `[]` at the call site over threading `nil` through the call graph.
- Where the API cannot express a default, document the parameter as nil-safe.

## Guard Clauses
- Return early; keep the happy path at the lowest indentation.
- One guard per invariant, at the root of the function.
- `fatalError("TODO` and `preconditionFailure(` are never guards against absent data (`CC-09`).
- A guard unwraps and names; the body never re-checks the same absence.

## Repository Conformance Gate
- `oaef doctor`
- `oaef lint`
- `oaef clean-code` (native: `swift tool/governance.swift clean-code`)
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every `Optional` in a signature has a documented business meaning.
- No `!` force-unwrap remains on a production path.
- Collection parameters carry a non-optional default.
- `swift test` passes with new cases for absent and empty inputs.

## Anti-Patterns
- `let value = maybeValue!` after an `if let` already proved existence.
- `[T]? = nil` in a public signature where `[T] = []` expresses the same contract.
- Nested `if let` pyramids instead of early `guard` returns.
- `fatalError("TODO` used to silence an absent-data path.
- An `Optional` added only to avoid updating existing call sites.
