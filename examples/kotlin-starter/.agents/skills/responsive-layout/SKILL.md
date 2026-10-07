---
name: responsive-layout
description: >-
  Use when a surface must adapt to another screen size, form factor or payload shape in Kotlin & JVM. Triggers on: "responsive", "adaptive", "breakpoint", "tablet", "foldable", "viewport". Chains into: ui-preview, test-generator. Owns adaptive design in Kotlin & JVM: breakpoints, safe areas, dynamic type and foldables for interactive surfaces, and payload shaping, pagination, content negotiation and streaming backpressure for headless ones.
argument-hint: "[breakpoint or surface name]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin
  version: 1.1.0
---

# Responsive Layout (Kotlin & JVM)

> **Stack Profile:** Kotlin & JVM
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Make every interactive surface adapt to the window it is given. Use window size classes and
constraint-driven layout rather than device-name checks, respect safe areas and dynamic
type, and keep one layout tree per size class instead of branching deep inside composition.

## Territory
- `**/features/<feature>/presentation/` — screens and composables that adapt.
- `**/components/**`, `**/shared/**`, `**/ui/**` — adaptive reusable surfaces.
- `src/main/res/values/`, `values-w600dp/`, `values-sw600dp/` — resource qualifiers.
- `MainActivity.kt` and window configuration for size-class reporting.

## Adaptive Surface Design
- Drive layout from `WindowSizeClass` (compact/medium/expanded) and `calculateWindowSizeClass`.
- Use `BoxWithConstraints` when a component must react to its own slot, not the window.
- Respect insets: apply `WindowInsets.safeDrawing`/`safeContent` instead of fixed padding.
- Honor `fontScale`; do not hardcode text sizes that ignore the user setting.
- Foldables: consume hinge posture via window layout info; never assume a single rectangle.
- Prefer a `when (windowSizeClass)` dispatch at the top of the screen over scattered checks.

## Breakpoint Strategy
- Breakpoints map to size classes, not to physical device names.
- Compact: single column with bottom navigation. Medium: rail plus content.
  Expanded: permanent drawer plus a two-pane master-detail.
- List-detail on expanded, stacked navigation on compact; one navigation state per class.
- Fluid dimension values live in `Dp` and derive from available width, not magic constants.
- Resource-qualified alternative strings/dimensions over runtime arithmetic where possible.

```kotlin
@Composable
fun BookingSurface(windowSizeClass: WindowSizeClass) {
    when (windowSizeClass.widthSizeClass) {
        WindowWidthSizeClass.Compact -> BookingStacked()
        else -> BookingTwoPane()
    }
}
```

## Repository Conformance Gate
- Run `oaef doctor` (native: `kotlinc -script tool/governance.main.kts doctor`).
- Run `oaef lint` and `oaef clean-code`; no hardcoded size literals or device checks.
- Record any deferred adaptive work in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Each size class renders without overflow, clipping or unreachable controls.
- Safe areas and dynamic type are honored on every surface.
- Breakpoints derive from the framework, not from hardcoded pixel checks.
- Previewed per size class via `ui-preview` and covered by `test-generator`.

## Anti-Patterns
- Branching on `Build.MODEL` or device names instead of window size classes.
- A fixed `padding(16.dp)` ignoring window insets on edge-to-edge screens.
- Ignoring `fontScale`, breaking layout at large accessibility text sizes.
- Folding a two-pane layout onto a phone by shrinking instead of reflowing.
