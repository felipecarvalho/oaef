---
name: ui-preview
description: >-
  Use when a component or screen must be inspected in isolation before it is wired into the application in Kotlin Multiplatform. Triggers on: "preview", "storybook", "isolated render". Chains into: test-generator, run-static-analysis. Provides isolated preview harnesses for Kotlin Multiplatform: loading, success, empty and error states are rendered without booting the full runtime, so layout, tokens and typography are validated before integration.
argument-hint: "[component or screen name]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.1.0
---

# UI Preview (Kotlin Multiplatform)

> **Stack Profile:** Kotlin Multiplatform
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Render every meaningful state of a composable without the application runtime, so tokens, spacing and typography are inspected before the surface joins the navigation graph.

## Territory
- `src/commonMain/kotlin/**/components/**` - component previews live next to the component.
- `src/commonMain/kotlin/**/features/<feature>/presentation/**` - screen and section previews.
- `src/commonMain/kotlin/**/ui/theme/**` - previews that exercise the theme wrapper.
- `src/commonTest/kotlin/**` - optional screenshot or render assertions for critical surfaces.

## Preview Harness
- Use the Compose Multiplatform `@Preview` annotation with an explicit size, and `@PreviewParameter` to feed the states.
- Cover the four canonical states for any surface backed by `UiState`: `Loading`, `Loaded` (populated), `Empty`, `Failed`.
- Previews are pure: no container resolution, no network, no platform singleton. Pass fakes or literal data into the stateless content composable.
- Preview the stateless `Content`, not the `Route`; the route exists to bind the ViewModel and cannot render in isolation.
- Wrap previews in the app theme (`MaterialTheme`) so token regressions surface immediately.
- One preview function per meaningful variant; do not exhaustively render every data combination.
- Add a preview per breakpoint for adaptive surfaces (`responsive-layout`).
- Theme and locale variations are previewed explicitly when the surface is locale-sensitive.
- Keep previews in `commonMain` so every target renders the same harness; a target-specific preview is added only when the rendering genuinely differs.
- Name previews after the state they render (`ContentLoadedPreview`, `ContentFailedPreview`) so a failing render points at a state.
- A preview that needs a repository uses a hand-written fake with fixed data; never a mock configured per call count.
- Screenshot or render assertions for critical surfaces live in `commonTest` and reuse the same fake data as the preview.

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint` and `oaef clean-code` (native: `kotlinc -script tool/governance.main.kts clean-code`).
- Run `./gradlew detekt`; previews are production code and must contain no `println(` or `TODO(`.
- Record surfaces still lacking a preview in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Each new public composable has at least one preview covering its default state.
- Each `UiState`-backed surface has previews for loading, success, empty and error.
- No preview performs I/O or resolves a dependency container.

## Anti-Patterns
- A preview that boots the whole application or calls the network.
- Previewing only the happy path while the error state stays unrendered.
- Leaving an unused preview with stale parameters after the contract changes.
