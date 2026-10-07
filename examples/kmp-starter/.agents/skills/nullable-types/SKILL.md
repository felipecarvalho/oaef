---
name: nullable-types
description: >-
  Use when a value can be absent, nil, null or optional in Kotlin Multiplatform. Triggers on: "null", "optional", "nil", "guard clause", "defensive". Chains into: test-generator, run-static-analysis. Owns defensive null handling and non-nullable collection defaults in Kotlin Multiplatform: absence carries business meaning, guard clauses return early instead of nesting, and a collection parameter defaults to a constant empty collection rather than an optional list.
argument-hint: "[path or type name]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.1.0
---

# Nullability & Types (Kotlin Multiplatform)

> **Stack Profile:** Kotlin Multiplatform
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Make absence explicit and collections total. A nullable parameter that means "no items" is a defect; a nullable value that means "unknown" is a domain fact and belongs in the type.

## Territory
- `src/commonMain/kotlin/**/*.kt` - public signatures, domain models and mappers.
- `**/features/<feature>/domain/**` - where absence becomes a sealed state, not a null.
- `**/features/<feature>/data/**` - decoders and boundary mappers that must not leak null.
- `src/commonTest/kotlin/**` - the tests that pin the guard clauses.

## Conventions
- `T?` is reserved for a real domain absence: "not loaded yet", "lookup found nothing", "optional field".
- Model multi-way absence with a `sealed interface` (`Loading` / `Loaded` / `Empty` / `Failed`), never with three nullable fields.
- `!!` is forbidden in production; use `?: error("...")` only for programmer-error invariants at the composition root.
- `lateinit` is forbidden for injected dependencies; inject through the constructor as `val`.
- Serialization decodes with explicit defaults: `@Serializable data class Payload(val items: List<Item> = emptyList())`.

## Non-Nullable Collections
- A public collection parameter or property is non-null with a constant empty default: `val items: List<Item> = emptyList()`.
- The `CC-08` token form is a nullable collection in a signature: `List<T>?`, `Map<K,V>?`, `Set<T>?`.
- Mappers normalize at the boundary: `items = payload.items.orEmpty()`.
- Copy-style builders preserve the non-null default; never let a builder introduce a nullable list.
- Empty is `emptyList()`, not `null`; consumers iterate unconditionally.

## Guard Clauses
- Return early: `val account = accounts.find(id) ?: return UiState.NotFound`.
- Flatten nesting: replace `if (a != null) { if (b != null) ... }` with `?.let` or two early returns.
- Resolve nullability before the composable body; never branch twice on the same nullable inside `@Composable`.
- Prefer `firstOrNull()`/`singleOrNull()` over a nullable accumulator mutated in a loop.
- Use `Result<T>` for recoverable failures instead of a nullable return that erases the error.

## Repository Conformance Gate
- Run `oaef clean-code` (native: `kotlinc -script tool/governance.main.kts clean-code`); `CC-08` findings are blocking under `strict`.
- Run `./gradlew detekt` and record unresolved nullability debt in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- No nullable collection parameter or property exists in a public signature.
- Every `T?` in a production signature is justified in one sentence in the PR description.
- Analyzer and tests pass with no new suppression.

## Anti-Patterns
- `List<Item>? = null` used to mean "no items".
- `!!` justified by "it can never be null here" without an invariant at the boundary.
- Nested null checks three levels deep instead of one early return.
