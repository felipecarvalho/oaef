---
name: screen-builder
description: >-
  Use when building or changing a screen, page, feature or user flow in Kotlin & JVM. Triggers on: "screen", "page", "feature", "flow", "view". Chains into: ui-preview, responsive-layout, test-generator. Constructs vertical feature slices in Kotlin & JVM inside the Clean Sizing bounds: state, presentation and routing arrive together, files stay under 300 lines, and the surface is previewable in isolation before integration.
argument-hint: "[screen or flow name]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin
  version: 1.1.0
---

# Screen Builder (Kotlin & JVM)

> **Stack Profile:** Kotlin & JVM
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Deliver a complete vertical slice for one screen or flow: an immutable UI state, a
stateless composable that renders it, an event surface, and a ViewModel that owns the
effects. One screen is one responsibility and stays under the Clean Sizing bounds.

## Territory
- `**/features/<feature>/presentation/` — composables, ViewModel, UI state.
- `**/features/<feature>/domain/` — use cases and models the screen consumes.
- `**/features/<feature>/data/` — repositories the ViewModel depends on.
- Navigation graph files (`*NavGraph.kt`, route definitions).

## Construction Steps
1. Define the UI state as a single immutable `data class` with a sealed error channel.
2. Define the event surface as a sealed interface consumed by the ViewModel.
3. Implement the ViewModel with constructor injection; expose `StateFlow<UiState>`.
4. Write a stateless `@Composable` that takes state plus callbacks; no logic in composition.
5. Wire routing: route constant, argument parsing, navigation callback.
6. Add a `@Preview` for each meaningful state and run `ui-preview`.
7. Cover the state reducer and the ViewModel with `test-generator`.

## State & Routing Contract
- The composable is stateless; all state flows in as parameters, all intent flows out.
- State is immutable; mutate through `copy()` and `StateFlow.update {}`.
- Side effects live in `LaunchedEffect` or the ViewModel, never inline in composition.
- Routing arguments are parsed and validated at the boundary, not inside the composable.
- Loading, empty, content and error are explicit states, not inferred from a nullable field.

```kotlin
data class BookingUiState(
    val isLoading: Boolean = false,
    val bookings: List<Booking> = emptyList(),
    val error: BookingError? = null,
)

@Composable
fun BookingScreen(state: BookingUiState, onRetry: () -> Unit) { /* render only */ }
```

## Repository Conformance Gate
- Run `oaef doctor` (native: `kotlinc -script tool/governance.main.kts doctor`).
- Run `oaef lint` and `oaef clean-code` before declaring the slice complete.
- Record deferred work and follow-ups in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The screen renders every state and is previewable without the full app runtime.
- Files under 300 lines, functions under 50 lines, one screen per slice.
- ViewModel dependencies are injected via constructor.
- Routing arguments validated; navigation callbacks covered by tests.

## Anti-Patterns
- Business logic inside a composable body.
- A nullable "content" field standing in for loading/empty/error states.
- A screen reading a global container instead of receiving its ViewModel.
- One mega-composable mixing layout, data fetch and navigation.
