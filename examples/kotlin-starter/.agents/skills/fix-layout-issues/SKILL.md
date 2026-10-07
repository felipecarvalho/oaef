---
name: fix-layout-issues
description: >-
  Use when a layout overflows, a constraint is unbounded or a render error breaks a surface in Kotlin & JVM. Triggers on: "overflow", "unbounded", "layout", "layout broken", "render error". Chains into: test-generator, run-static-analysis. Diagnoses structural render defects in Kotlin & JVM: it isolates the offending constraint, state or data shape, fixes the shared root cause instead of clipping the symptom, and proves the correction with a regression test.
argument-hint: "[symptom or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin
  version: 1.1.0
---

# Fix Layout Issues (Kotlin & JVM)

> **Stack Profile:** Kotlin & JVM
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Find and fix the structural cause of a render defect. Compose reports the symptom, not the
cause: isolate the offending constraint, state or data shape, fix it once at the shared
root, and pin it with a regression test.

## Territory
- `**/features/<feature>/presentation/` — composables that misbehave.
- `**/components/**`, `**/shared/**` — reusable surfaces with inherited constraints.
- `**/theme/**`, `src/main/res/values*/` — dimensions and qualifiers involved.
- `**/preview/**` — reproduction harnesses for the defect.

## Triage Procedure
1. Reproduce in an isolated `@Preview` with the smallest state that triggers the defect.
2. Identify the constraint source: parent `Modifier`, scroll container, or an intrinsic size.
3. Common Kotlin/Compose root causes:
   - A scrollable child inside an unbounded-height parent (lazy list in a `Column`).
   - `fillMaxSize()` inside a `LazyColumn` item causing measurement loops.
   - Nested `Column`/`Row` scrollables fighting for the scroll gesture.
   - Text without `maxLines` producing unbounded intrinsic height.
   - Missing `weight`/`fillMaxWidth` causing overflow on long content or large font scale.
4. Fix the shared root: adjust the container, not each child's clip.
5. Re-run the preview across size classes and font scales.
6. Add a regression test asserting the layout under the triggering input.

## Repository Conformance Gate
- Run `oaef doctor` (native: `kotlinc -script tool/governance.main.kts doctor`).
- Run `oaef lint` and `oaef clean-code` after the fix.
- Record the root cause and the guard added in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The defect no longer reproduces at any relevant size class or font scale.
- The fix addresses a shared cause, not a per-call-site clip or magic padding.
- A regression test fails before the fix and passes after it.
- No new `CC-*` violation introduced by the change.

## Anti-Patterns
- Adding `Modifier.clipToBounds()` or `height(fixedDp)` to hide the overflow.
- Wrapping the offending child in a scrollable to silence the constraint error.
- Fixing one call site while the same pattern remains elsewhere (see `code-review`).
- Replacing a real measurement fix with hardcoded sizes.
