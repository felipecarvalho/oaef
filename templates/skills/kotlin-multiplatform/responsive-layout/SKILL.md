---
name: responsive-layout
description: >-
  Use when a surface must adapt to another screen size, form factor or payload shape in Kotlin Multiplatform. Triggers on: "responsive", "adaptive", "breakpoint", "tablet", "foldable", "viewport". Chains into: ui-preview, test-generator. Owns adaptive design in Kotlin Multiplatform: breakpoints, safe areas, dynamic type and foldables for interactive surfaces, and payload shaping, pagination, content negotiation and streaming backpressure for headless ones.
argument-hint: "[breakpoint or surface name]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.1.0
---

# Responsive Layout (Kotlin Multiplatform)

> **Stack Profile:** Kotlin Multiplatform
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Make a Compose Multiplatform surface correct at every window size, form factor and foldable posture, with safe areas and dynamic type respected, without forking the layout per platform.

## Territory
- `src/commonMain/kotlin/**/presentation/**` - adaptive screens and layout hosts.
- `src/commonMain/kotlin/**/components/**` - components that receive a size class instead of reading it.
- `src/androidMain/kotlin/**`, `src/iosMain/kotlin/**`, `src/desktopMain/kotlin/**` - only the platform-specific window and safe-area adapters.
- `src/commonTest/kotlin/**` - breakpoint and posture tests.

## Adaptive Surface Design
- Derive the size class once at the top of the surface with `calculateWindowSizeClass()` or a `BoxWithConstraints` and pass `WindowSizeClass` down; components never read the window directly.
- Map the size class to layout, not to behavior: compact is a single pane, medium a navigation rail, expanded a two-pane scaffold.
- Respect per-platform safe areas: apply window insets on Android and the safe-area insets on iOS at the surface root, not inside every child.
- Honor dynamic type: use `MaterialTheme.typography` and let text scale; never hardcode a `sp` that ignores `fontScale`.
- Handle foldables by posture: use the hinge/separating region to split content, not a fixed gutter.
- Keep the layout the same in `commonMain`; a platform difference is one `expect/actual` insets adapter, not a duplicated screen.
- No fixed pixel widths: sizes derive from constraints, `weight` and the size class.
- Nested scrollables are forbidden; one vertical scroll owner per surface.

## Breakpoint Strategy
- Define named breakpoints (compact, medium, expanded) from `WindowWidthSizeClass`; never scatter magic `600.dp` comparisons.
- Navigation adapts with the surface: bottom bar (compact), navigation rail (medium), permanent drawer (expanded), driven by one scaffold switch.
- Grids choose the column count from the size class (`LazyVerticalGrid(GridCells.Adaptive(minSize = 160.dp))`), not from a hardcoded count.
- Text containers constrain with `widthIn(max = ...)` so lines stay readable on a desktop window.
- Cards and dialogs switch to a side sheet or a two-pane layout on expanded, using the same content composable.
- Every breakpoint is previewable: add a preview per size class (`ui-preview`).
- Tablet and desktop use the same slice; only the scaffold composition changes.

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint` and `oaef clean-code` (native: `kotlinc -script tool/governance.main.kts clean-code`).
- Run `./gradlew detekt` and `./gradlew allTests`.
- Record unresolved adaptive gaps in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The surface renders correctly at compact, medium and expanded widths and in at least one foldable posture.
- Safe areas and dynamic type are verified on Android, iOS and desktop.
- No magic breakpoint number or fixed width remains in the layout code.

## Anti-Patterns
- Reading `WindowSizeClass` inside every leaf composable.
- Two near-identical screens - one per form factor - instead of one adaptive scaffold.
- Ignoring `fontScale` with hardcoded text sizes.
