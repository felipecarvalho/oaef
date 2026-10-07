---
name: nullable-types
description: >-
  Use when a value can be absent, nil, null or optional in Rust. Triggers on: "null", "optional", "nil",
  "guard clause", "defensive". Chains into: test-generator, run-static-analysis. Owns defensive null
  handling and non-nullable collection defaults in Rust: absence carries business meaning, guard clauses
  return early instead of nesting, and a collection parameter defaults to a constant empty collection
  rather than an optional list.
argument-hint: "[path or type name]"
license: MIT
metadata:
  framework: OAEF
  stack: rust
  version: 1.1.0
---

# Nullable Types and Absence (Rust)

> **Stack Profile:** Rust
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Model absence explicitly with `Option<T>` and failure with `Result<T, E>`, so a missing value is part of
the type and never a surprise at runtime.

## Territory
- `src/**/*.rs` — every module that returns or accepts a possibly-absent value.
- `src/<feature>/domain` — domain types where absence carries business meaning.
- `src/<feature>/data` — boundary code that parses external payloads into typed values.

## Conventions
- Model absence with `Option<T>`; never use sentinel values (`-1`, `""`, `0`) for "not present".
- Represent failure with `Result<T, E>` and propagate with `?`; do not encode errors in `Option`.
- Prefer `Option<&T>` over `Option<T>` on read paths: absence of a borrow costs no allocation.
- Replace `unwrap()`/`expect()` in production with explicit handling; reserve them for tests and for
  provably unreachable branches carrying a message.
- `Option<Vec<T>>` for "zero or more" is a smell: absence and emptiness are distinct only when the
  domain says so.

## Non-Nullable Collections
- A collection parameter is a borrowed slice `&[T]` (or `&mut Vec<T>` when growth is required) and it
  defaults to the constant empty slice `&[]` instead of an optional collection.
- "No values" is expressed as an empty `Vec`/slice, not as `None`; reserve `None` for "unknown" or
  "not supplied".
- Return `impl Iterator<Item = &T>` when the caller only reads, to avoid materializing a collection.
- The Rust governance engine treats nullable-collection detection as a documented no-op (`CC-08`);
  this skill is the idiomatic substitute. Document every collection parameter that can be `nil`-like
  as explicitly empty-safe in its doc comment.

## Guard Clauses
- Use `let ... else` and early `return` to flatten nesting:
  ```rust
  let Some(order) = repository.find(order_id)? else {
      return Ok(None);
  };
  ```
- Validate inputs at function entry and return a typed error; never proceed with a partially valid value.
- Keep one guard at the shared root of a call graph instead of a defensive branch per call site.
- Match exhaustively: `match` on `Option` and custom enums without a catch-all `_` arm when new variants
  could silently be ignored.

## Repository Conformance Gate
- `cargo run --bin governance -- clean-code`
- `oaef lint` and the native `cargo clippy --all-targets -- -D warnings`
- `oaef doctor`
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every absence is typed as `Option`, every failure as `Result`, with no sentinel values.
- No production `unwrap()`/`expect()` on fallible external input.

## Anti-Patterns
- `Option<Vec<T>>` used to mean "empty list".
- `match` with a wildcard arm that swallows a new enum variant.
- Deeply nested `if let` where a `let ... else` guard clause is enough.
- Stringly-typed errors built to avoid declaring a `Result` error type.
