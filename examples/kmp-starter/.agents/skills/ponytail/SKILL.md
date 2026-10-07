---
name: ponytail
description: >-
  Use when adding, refactoring, simplifying or deleting code in Kotlin Multiplatform. Triggers on: "new", "refactor", "add", "simple", "minimal", "YAGNI", "dead code", "delete", "remove". Chains into: screen-builder, component-author, nullable-types, code-review. Governs the seven-rung Simplicity Ladder across every Kotlin Multiplatform source tree: it demands the smallest correct diff, forbids ceremonial layers and speculative abstraction, and routes every root cause to the single shared guard instead of per-call-site defensive branches.
argument-hint: "[mode: lite|full|ultra] [path]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.1.0
---

# Ponytail - Simplicity Ladder (Kotlin Multiplatform)

> **Stack Profile:** Kotlin Multiplatform
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)

> **Attribution:** the Simplicity Ladder is inspired by Dietrich Gebert's *Ponytail* minimalism (smallest correct diff, zero AI slop).
> **Skill Class:** meta

## Mission
Reach the smallest correct diff in Kotlin Multiplatform before writing any abstraction. Every rung answered with "already satisfied" removes code that never needs a test, a mock or a target migration.

## Territory
- `src/commonMain/kotlin/**` - shared production code; the default home of a simplification.
- `src/androidMain/kotlin/**`, `src/iosMain/kotlin/**`, `src/desktopMain/kotlin/**` - source sets added only when a platform genuinely differs.
- `**/features/<feature>/{presentation,domain,data}/**` - feature slices; a rung answered here shrinks a whole vertical.
- `build.gradle.kts`, `gradle/libs.versions.toml` - every new coordinate is a rung that was not climbed.

## Modes
- `lite` - review-only pass: list what could be deleted, the caller list of the shared root, and the marker ceiling. No edits.
- `full` (default) - apply deletions, stdlib substitutions and the single shared guard, then re-run the analyzer.
- `ultra` - additionally collapse single-caller layers introduced in the current branch and re-evaluate the dependency graph.

## The N-Step Ladder
1. **YAGNI** - the requirement is not in the ticket. Delete the speculative seam.
2. **Reuse in the codebase** - grep the `commonMain` tree before adding a type; an existing `Flow` pipeline or sealed hierarchy usually already fits.
3. **Kotlin stdlib and coroutines** - `map`, `filter`, `fold`, `Result`, `sealed interface`, value classes, `use {}`, and the `Flow` operators already shipped with the compiler.
4. **Platform-native capability** - `expect/actual` for the one real difference, Compose primitives, `WindowSizeClass`; the platform already solves it.
5. **Already-declared dependency** - use what `gradle/libs.versions.toml` already resolves; a new coordinate needs a written justification.
6. **One-line idiomatic expression** - a `when` branch, a `?.let`, `singleOrNull()` instead of a hand-rolled loop over intermediate lists.
7. **Smallest correct diff** - everything above failed; still no ceremony, no interface with one implementation, no pass-through layer.

## Root-Cause Bug Fixing
- Grep every caller before patching: `grep -rn "<symbol>" src/commonMain src/androidMain src/iosMain`.
- Fix the shared root once; never add a defensive branch per call site.
- A null fix belongs at the producing boundary, not in each consumer.

## Complexity Taxonomy
- **Ceremonial layer** - a one-line use case or a single-implementation interface without a mock need. `[DELETE]`.
- **Reinvented primitive** - a hand-rolled fold where `fold`/`runningFold` exists. `[STDLIB]`.
- **Platform re-implementation** - per-source-set forks where `expect/actual` or a Compose primitive suffices. `[NATIVE]`.
- **Speculative seam** - generics, extension points or configuration for a second use that does not exist. `[YAGNI]`.
- **Bloat** - a 400-line composable that is three smaller ones. `[SHRINK]`.

## // ponytail: Debt Markers
```kotlin
// ponytail: in-memory cache; move to SQLDelight once writes exceed 10k/day
```
- Grammar is `ponytail: <ceiling + evolution trigger>`, introduced by the platform comment `//`.
- Never blocking: `oaef ponytail debt` lists every marker, `oaef ponytail audit` adds the `[TAG]` sweep.
- A marker without a numeric or observable trigger is rejected in review.

## Repository Conformance Gate
- Run `oaef clean-code` (native: `kotlinc -script tool/governance.main.kts clean-code`) and `./gradlew detekt`.
- Escalate only `CC-*` findings that touch the diff; record unresolved debt in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every rung below the chosen one is answered in the PR description.
- No `[DELETE]`, `[STDLIB]`, `[NATIVE]`, `[YAGNI]` or `[SHRINK]` candidate survives the diff unrebutted.
- `./gradlew detekt` passes with no new suppression.

## Anti-Patterns
- Adding an interface "for testability" when a fake constructor argument suffices.
- Introducing a new dependency for a problem three stdlib calls solve.
- Repeating the same null guard in five call sites instead of one shared root.
