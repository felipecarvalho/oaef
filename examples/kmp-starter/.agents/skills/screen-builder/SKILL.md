---
name: screen-builder
description: >-
  Use when building or changing a screen, page, feature or user flow in Kotlin Multiplatform. Triggers on: "screen", "page", "feature", "flow", "view". Chains into: ui-preview, responsive-layout, test-generator. Constructs vertical feature slices in Kotlin Multiplatform inside the Clean Sizing bounds: state, presentation and routing arrive together, files stay under 300 lines, and the surface is previewable in isolation before integration.
argument-hint: "[screen or flow name]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.1.0
---

# Screen Builder (Kotlin Multiplatform)

> **Stack Profile:** Kotlin Multiplatform
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Deliver a complete vertical slice - state, presentation and routing - that runs on every target and is previewable before it is wired into the navigation graph.

## Territory
- `src/commonMain/kotlin/**/features/<feature>/presentation/**` - route, content and section composables.
- `src/commonMain/kotlin/**/features/<feature>/domain/**` - state model and the ViewModel contract.
- `src/commonMain/kotlin/**/features/<feature>/data/**` - the repository the ViewModel consumes.
- `src/commonMain/kotlin/**/navigation/**` - route registration for the shared navigation graph.
- `src/androidMain/kotlin/**`, `src/iosMain/kotlin/**`, `src/desktopMain/kotlin/**` - only when a platform entrypoint differs.

## Construction Steps
1. Declare the slice: `features/<feature>/{presentation,domain,data}` under `commonMain`.
2. Model the state in `domain` as an immutable `data class` or a `sealed interface` (`Loading`/`Loaded`/`Empty`/`Failed`).
3. Expose `StateFlow<UiState>` and a `sealed interface` of intents from a common ViewModel built on `androidx.lifecycle.ViewModel` (KMP variant).
4. Collect state with `collectAsStateWithLifecycle()` and dispatch intents through `viewModel::onIntent`.
5. Split the composable into a `Route` entrypoint, a stateless `Content` and focused sections; keep each file under 300 lines.
6. Register the route in the shared navigation graph (Navigation Compose, Voyager or Decompose - one, not two).
7. Add the preview harness (`ui-preview`) and the tests (`test-generator`) in the same change.

## State & Routing Contract
- One immutable `UiState` is the single source of truth; no duplicated mutable state in composables.
- Intents are a sealed interface consumed by the ViewModel; composables never mutate state directly.
- Navigation is expressed as parameters - `onNavigate: (Route) -> Unit` - not resolved from a container inside the screen.
- The ViewModel is resolved at the entrypoint (`*Activity*`, `*Application*`, `*Module.kt`) and passed in; a screen file never calls `inject<` or `getKoin().get(`.
- Screen-level effects use `LaunchedEffect`/`SharedFlow`; never a side effect inside state derivation.
- Errors are part of `UiState.Failed`, never a swallowed exception.

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint` and `oaef clean-code` (native: `kotlinc -script tool/governance.main.kts clean-code`).
- Run `./gradlew detekt` and `./gradlew allTests`.
- Record deferred screen work in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The slice compiles for every declared target with `./gradlew allTests`.
- The screen renders in isolation through the preview harness before integration.
- No file in the slice exceeds 300 lines and no composable exceeds 100 lines.

## Anti-Patterns
- A screen composable that reaches into a repository or container directly.
- Two navigation libraries active in the same graph.
- Business branching inside the composable instead of in the ViewModel.
