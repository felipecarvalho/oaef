---
name: component-author
description: >-
  Use when authoring or extracting a reusable component, widget, button, card or modal in Kotlin & JVM. Triggers on: "component", "widget", "button", "card", "modal". Chains into: ui-preview, responsive-layout, test-generator. Authors reusable Kotlin & JVM surfaces from design-system tokens: one responsibility per component, tokens instead of literals, and a contract that serves every consumer without a bespoke variant.
argument-hint: "[component name]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin
  version: 1.1.0
---

# Component Author (Kotlin & JVM)

> **Stack Profile:** Kotlin & JVM
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Author reusable Jetpack Compose surfaces with a single responsibility and a contract that
serves every caller. Colors, spacing, shape and typography come from the theme; the
component accepts a `Modifier` and hoists its state so it stays testable and previewable.

## Territory
- `**/components/**`, `**/shared/**`, `**/ui/**` — reusable surfaces.
- `**/designsystem/**`, `**/theme/**` — tokens, colors, typography, spacing.
- `**/features/<feature>/presentation/` — call sites that must not fork the component.

## Component Contract
- One responsibility per component; a boolean flag `isFoo` that changes structure means split it.
- Accept a trailing `Modifier = Modifier` and apply it to the root for composability.
- Hoist state: expose `value` plus `onValueChange`; keep internal state only when private and trivial.
- Content slots use `@Composable () -> Unit` parameters, not a grab-bag of optional flags.
- Naming: `BookingCard`, not `BookingCardWithShadowAndBorder`.

```kotlin
@Composable
fun BookingCard(
    booking: Booking,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Card(onClick = onClick, modifier = modifier) { /* content */ }
}
```

## Token Discipline
- Colors come from `MaterialTheme.colorScheme`; spacing from a defined `Dp` scale.
- Typography from `MaterialTheme.typography`; never a raw `sp` value.
- Shape from the shape scale; never an inline `RoundedCornerShape(7.dp)`.
- Literal colors, magic `dp`/`sp` values and one-off elevations are defects.

## Repository Conformance Gate
- Run `oaef doctor` (native: `kotlinc -script tool/governance.main.kts doctor`).
- Run `oaef lint` and `oaef clean-code`; no hardcoded token literals (`CC-04` adjacent).
- Record component decisions and follow-ups in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The component is stateless or trivially stateful and renders under `@Preview`.
- All visual values resolve from theme tokens.
- No structural boolean flags; variants are explicit parameters or separate components.
- Covered by a component test via `test-generator`.

## Anti-Patterns
- A "design system" component that hardcodes hex colors and pixel sizes.
- Optional-parameter explosion building a bespoke variant per caller.
- Internal state that callers must reach into to reset.
- Duplicating an existing component because reuse would need one parameter.
