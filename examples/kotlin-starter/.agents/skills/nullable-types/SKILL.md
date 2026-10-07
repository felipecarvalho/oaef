---
name: nullable-types
description: >-
  Use when a value can be absent, nil, null or optional in Kotlin & JVM. Triggers on: "null", "optional", "nil", "guard clause", "defensive". Chains into: test-generator, run-static-analysis. Owns defensive null handling and non-nullable collection defaults in Kotlin & JVM: absence carries business meaning, guard clauses return early instead of nesting, and a collection parameter defaults to a constant empty collection rather than an optional list.
argument-hint: "[path or type name]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin
  version: 1.1.0
---

# Nullable Types (Kotlin & JVM)

> **Stack Profile:** Kotlin & JVM
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Keep `null` meaningful. A nullable type must encode an absence that the domain
understands, not a lazy default. Guard clauses return early, collections default to an
immutable empty instance, and `!!` is treated as a defect awaiting a crash.

## Territory
- `src/main/`, `app/src/main/` — production Kotlin sources.
- `**/features/<feature>/{domain,data}` — public contracts and model shapes.
- `**/di/**`, `*Module.kt` — dependency wiring where optional parameters leak.
- `src/test/`, `app/src/test/` — the tests that pin absence behaviour.

## Conventions
- Model absent business state with a sealed hierarchy or a nullable field, never with a
  sentinel value such as `-1`, `""` or `Instant.MIN`.
- Prefer `val` with a smart-castable null check over a nullable `var` mutated later.
- Prefer `?.let { }`, `takeIf`, `takeUnless`, `orEmpty()` over manual branching.
- `!!` is forbidden on non-final fields and on any value crossing a function boundary.
- Use `requireNotNull`/`checkNotNull` only at a true boundary, with a message.

```kotlin
// Guard clause: early return beats nesting.
fun Booking.requireSession(session: Session?): Booking {
    val active = session ?: return this
    return copy(sessionId = active.id)
}
```

## Non-Nullable Collections
- A collection parameter is `List<T>` not `List<T>?`; absent means the constant `emptyList()`.
- Defaults use `emptyList()`, `emptyMap()`, `emptySet()` — never a mutable literal.
- Never default to `mutableListOf()`; a shared mutable default is a latent aliasing bug.
- A truly optional collection carries explicit business meaning and is documented.

```kotlin
fun render(rows: List<Row> = emptyList(), meta: Map<String, String> = emptyMap()) { }
```

Automated check `CC-08` flags `List<T>?`/`Map<K,V>?`/`Set<T>?` parameters without a
non-null constant-empty default.

## Guard Clauses
- Validate at the boundary, then work with non-null types for the rest of the function.
- One reason to bail per guard, at the top of the function.
- Return `Result.failure` or a sealed error for domain absence; throw only for programmer error.
- Consolidate repeated guards into a shared extension when the same check appears twice.

## Repository Conformance Gate
- Run `oaef doctor` (native: `kotlinc -script tool/governance.main.kts doctor`).
- Run `oaef lint` and `oaef clean-code`; `CC-08` findings are blocking in `strict`.
- Record unresolved nullability findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- No production `!!` outside a justified, comment-documented boundary.
- Every collection parameter is non-null with a constant empty default.
- Guard clauses replace nested null checks; tests cover the absent branch.

## Anti-Patterns
- `?: throw IllegalStateException("unexpected")` masking a real domain absence.
- Defaulting a parameter to `mutableListOf()` and mutating shared state.
- Nullable collection parameter documented "must not be null".
- Sparse `!!` use that only relocates the crash deeper into the stack.
