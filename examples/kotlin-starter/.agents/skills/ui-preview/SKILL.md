---
name: ui-preview
description: >-
  Use when a component or screen must be inspected in isolation before it is wired into the application in Kotlin & JVM. Triggers on: "preview", "storybook", "isolated render". Chains into: test-generator, run-static-analysis. Provides isolated preview harnesses for Kotlin & JVM: loading, success, empty and error states are rendered without booting the full runtime, so layout, tokens and typography are validated before integration.
argument-hint: "[component or screen name]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin
  version: 1.1.0
---

# UI Preview (Kotlin & JVM)

> **Stack Profile:** Kotlin & JVM
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Render a surface without the whole application. Preview harnesses prove layout, tokens,
typography and state handling before integration, catching defects where they are cheapest
to fix. Every meaningful state of a surface is previewable.

## Territory
- `**/features/<feature>/presentation/` — screens with `@Preview` functions.
- `**/components/**`, `**/shared/**` — reusable surfaces.
- `**/preview/**`, `src/debug/` — preview-only fixtures and sample data.
- Any `@Composable` that renders UI from state.

## Preview Harness
- One `@Preview` per meaningful state: loading, success, empty, error, long content.
- Parameterize size, theme and font scale with `@Preview(showBackground = true, widthDp = ...)`.
- Provide deterministic sample data via a preview-only `make*` fixture; never call the network.
- Use `@PreviewParameter` to iterate a data provider across a set of representative states.
- Wrap previews in the app theme so token regressions are visible in the preview itself.
- Multi-size previews validate the size classes of `responsive-layout`.

```kotlin
@Preview(name = "Empty", showBackground = true)
@Composable
private fun BookingCardEmptyPreview() {
    AppTheme { BookingCard(booking = makeBooking(id = BookingId(0)), onClick = {}) }
}
```

## Repository Conformance Gate
- Run `oaef doctor` (native: `kotlinc -script tool/governance.main.kts doctor`).
- Run `oaef lint` and `oaef clean-code`; preview fixtures must not reach into production DI.
- Record preview-only scaffolding still to remove in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every state of the surface has a preview rendering under the app theme.
- Preview data is deterministic and network-free.
- At least one preview per relevant size class for adaptive surfaces.
- The preview path adds zero runtime cost to release builds.

## Anti-Patterns
- A preview that boots the full app or hits a live service.
- Only the happy-path state previewed.
- Hardcoded colors or sizes in previews masking token bugs.
- Preview fixtures drifting from the real model shape.
