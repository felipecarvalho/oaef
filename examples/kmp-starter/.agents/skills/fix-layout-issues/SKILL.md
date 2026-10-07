---
name: fix-layout-issues
description: >-
  Use when a layout overflows, a constraint is unbounded or a render error breaks a surface in Kotlin Multiplatform. Triggers on: "overflow", "unbounded", "layout", "layout broken", "render error". Chains into: test-generator, run-static-analysis. Diagnoses structural render defects in Kotlin Multiplatform: it isolates the offending constraint, state or data shape, fixes the shared root cause instead of clipping the symptom, and proves the correction with a regression test.
argument-hint: "[symptom or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.1.0
---

# Fix Layout Issues (Kotlin Multiplatform)

> **Stack Profile:** Kotlin Multiplatform
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Find why the constraint chain is broken, not where the pixels are wrong. Fix the shared root cause and lock it with a regression test.

## Territory
- `src/commonMain/kotlin/**/presentation/**` - screens and sections where overflow appears.
- `src/commonMain/kotlin/**/components/**` - the component that imposes or drops a constraint.
- `src/commonMain/kotlin/**/ui/theme/**` - spacing tokens that replace magic sizes.
- `src/commonTest/kotlin/**` - the regression test file for the fixed surface.

## Triage Procedure
1. **Reproduce in isolation** - render the surface through a preview (`ui-preview`) at the failing size; if it renders, the constraint comes from a parent.
2. **Read the exception** - an unbounded constraint usually surfaces as `IllegalStateException` from the measure pass naming the composable; that node owns the broken chain.
3. **Walk the chain** - from the failing node upward, find the first parent that does not bound the axis: a `Column` without a scroll owner, a `Box` without a size, or a `LazyColumn` inside a `Column`.
4. **Isolate the constraint** - classify the cause: missing bound, nested scrollables, `weight` used outside a `Row`/`Column` scope, an unbounded child inside `fillMaxSize`.
5. **Inspect the data shape** - an overflow frequently follows a data state (a long label, an empty collection, a null branch rendered as placeholder).
6. **Fix the root** - add the missing bound (`heightIn`, `weight`, `Modifier.verticalScroll` on the single scroll owner) at the shared place, not at the leaf where the symptom shows.
7. **Never clip** - `clipToBounds()` or a fixed height that hides content is a rejected fix.
8. **Prove it** - add a regression test that renders the fixed surface at the failing size and asserts the node tree measures.

## Common Root Causes
- `LazyColumn` nested inside a scrollable `Column`: give the list the scroll ownership.
- `Modifier.weight` used in a container that is not `RowScope`/`ColumnScope`.
- A `Row` child with `fillMaxWidth` inside an unbounded parent.
- Text not limited with `maxLines` and `overflow` in a constrained row.
- Insets applied twice, producing negative available space.

## Repository Conformance Gate
- Run `oaef clean-code` (native: `kotlinc -script tool/governance.main.kts clean-code`) and `./gradlew detekt`.
- Run `./gradlew allTests`, including the new regression test.
- Record any deferred layout debt in `docs/wiki/memory/handoff.md` with the surface name.

## Exit Criteria
- The surface renders at the failing size with no unbounded-constraint exception.
- The fix lives at the shared root; no leaf-level clipping was added.
- A regression test reproduces the defect before the fix and passes after.

## Anti-Patterns
- Masking overflow with `clipToBounds()` or an opaque fixed height.
- Adding a second scrollable inside the first to silence the exception.
- Fixing one call site while sibling surfaces keep the same unbounded parent.
