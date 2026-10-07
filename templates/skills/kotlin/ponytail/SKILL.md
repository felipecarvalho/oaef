---
name: ponytail
description: >-
  Use when adding, refactoring, simplifying or deleting code in Kotlin & JVM. Triggers on: "new", "refactor", "add", "simple", "minimal", "YAGNI", "dead code", "delete", "remove". Chains into: screen-builder, component-author, nullable-types, code-review. Governs the seven-rung Simplicity Ladder across every Kotlin & JVM source tree: it demands the smallest correct diff, forbids ceremonial layers and speculative abstraction, and routes every root cause to the single shared guard instead of per-call-site defensive branches.
argument-hint: "[mode: lite|full|ultra] [path]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin
  version: 1.1.0
---

# Ponytail (Kotlin & JVM)

> **Stack Profile:** Kotlin & JVM
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)

> **Attribution:** the Simplicity Ladder is inspired by Dietrich Gebert's *Ponytail* minimalism (smallest correct diff, zero AI slop).
> **Skill Class:** meta

## Mission
Climb the Simplicity Ladder before writing a single line. The best Kotlin is the Kotlin
that did not have to be written: fewer files, fewer classes, fewer abstractions, one clear
root cause. This meta-skill qualifies every other skill and every new or refactored line.

## Territory
- `src/main/`, `app/src/main/` — all production Kotlin and Compose sources.
- `**/features/<feature>/{presentation,domain,data}` — feature slices.
- `build.gradle.kts`, `gradle/libs.versions.toml` — dependency surface to keep minimal.
- Any `.kt` or `.kts` file touched by the current change.

## Modes
- `lite` — default. Rewrite freely; only flag debt.
- `full` — propose the smallest correct diff and justify each new symbol.
- `ultra` — delete first. Every surviving line must answer a caller.

## The N-Step Ladder
Climb top-down and stop at the first rung that holds:

1. **YAGNI** — does this need to exist now? If not, delete the request.
2. **Reuse in codebase** — search for an existing function, composable or extension.
3. **Kotlin stdlib primitive** — `map`/`filter`/`fold`, `Result`, sealed interface, value class, `use {}`.
4. **Platform-native capability** — Compose primitives, `remember`/`derivedStateOf`, resource qualifiers.
5. **Already-installed dependency** — Coroutines, Koin, OkHttp already on the classpath.
6. **One-line idiomatic expression** — a single `let`, `takeIf`, or `when` expression.
7. **Smallest correct diff** — only then write new structure.

Adding a dependency requires that rungs 1-6 are demonstrably exhausted.

## Root-Cause Bug Fixing
- `grep -rn` every caller of the failing symbol before editing any of them.
- Fix the single shared root (the null source, the bad factory, the missing guard) once.
- Never paste the same defensive branch into each call site; that is AI slop.
- A fix that touches five call sites instead of one shared guard is rejected.

## Complexity Taxonomy
- **Necessary** — domain logic, state transitions, error routing, accessibility.
- **Accidental** — wrappers whose only body delegates to one other call, single-implementation
  interfaces without a mock need, DTOs mirroring DTOs, `use case` classes with one line.
- Delete accidental complexity; the Ponytail Ladder names the replacement.

## // ponytail: Debt Markers
When a deliberate ceiling is left in place, annotate it:

```kotlin
// ponytail: O(n^2) scan; replace with an index when the list exceeds 1e4 entries.
fun findBooking(id: BookingId): Booking? = bookings.firstOrNull { it.id == id }
```

Grammar: `// ponytail: <ceiling>; <evolution trigger>`. Audit with
`oaef ponytail debt` (native: `kotlinc -script tool/governance.main.kts ponytail-debt`).

## Safety Frontier
The Ladder never prunes: input validation, error routing, privacy redaction,
accessibility, tests and the Quality Gate Matrix. Nothing else is exempt.

## Repository Conformance Gate
- Run `oaef doctor` (native: `kotlinc -script tool/governance.main.kts doctor`).
- Run `oaef lint` and `oaef clean-code` (native: `... governance.main.kts clean-code`).
- Record any unresolved debt marker or finding in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The diff is the smallest that satisfies the request; no speculative abstraction remains.
- Every `// ponytail:` marker carries a ceiling and an evolution trigger.
- `oaef clean-code` reports no new blocking violation.

## Anti-Patterns
- One-line pass-through use cases and single-implementation interfaces.
- Narration comments restating the code; `// TODO: refactor later` without a marker.
- Reaching for a new dependency before exhausting the stdlib and the platform.
- Fixing the symptom at each call site instead of the shared root.
