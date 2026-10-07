---
name: screen-builder
description: >-
  Use when building or changing a screen, page, feature or user flow in Dart & Flutter. Triggers on: "screen", "page", "feature", "flow", "view".
  Chains into: ui-preview, responsive-layout, test-generator. Constructs vertical feature slices in Dart & Flutter inside the Clean Sizing bounds: state, presentation and routing arrive together, files stay under 300 lines, and the surface is previewable in isolation before integration.
argument-hint: "[screen or flow name]"
license: MIT
metadata:
  framework: OAEF
  stack: dart-flutter
  version: 1.1.0
---

# Screen Builder (Dart & Flutter)

> **Stack Profile:** Dart & Flutter
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Build a vertical feature slice that owns its state, presentation and routing as one coherent unit. The screen is constructed inside the Clean Sizing bounds, its states are explicit, and it renders in isolation before it is wired into the router.

## Territory
- `lib/features/<feature>/presentation/**` — screens, view models and state holders for the slice.
- `lib/features/<feature>/domain/**` — entities and use-case contracts the screen consumes.
- `lib/features/<feature>/data/**` — repositories bound in the composition root and injected into the screen.
- `lib/shared/**`, `lib/ui/**` — reusable widgets and tokens the screen composes.
- `lib/di/**`, `lib/main.dart` — where the screen's dependencies are wired; the only place a container token is legitimate.
- `test/features/<feature>/**` — widget tests covering each declared state.

## Construction Steps
1. Declare the feature slice skeleton: `presentation`, `domain`, `data` directories under `lib/features/<feature>/`.
2. Model the screen state as a sealed hierarchy or an `AsyncValue`; enumerate loading, success, empty and error as distinct states before writing layout.
3. Define the state holder (a `ChangeNotifier`, a Bloc/Cubit or a plain `ValueNotifier`), injected with its use-case contracts through the constructor (`required`/`final`).
4. Compose the presentation from `lib/shared/**` and `lib/ui/**` widgets; keep the screen file under 300 lines by extracting sub-widgets, never by inlining more branches.
5. Wire routing in one place (the router or `MaterialApp.onGenerateRoute`), passing arguments typed, not as dynamic maps.
6. Add a preview harness and cover each state with a widget test before integration.

## State & Routing Contract
- **Typed inputs** — a screen receives a typed arguments object or its entities, never a `Map<String, dynamic>` or a bare `dynamic`.
- **Single source of state** — the screen widget is stateless over injected state; mutable view state lives in the state holder.
- **Explicit transitions** — navigation is triggered from the state holder or a callback, not from deep inside a leaf widget.
- **Absence is a state** — an empty result renders the empty state; it is never `null` layout.

```dart
class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key, required this.state});
  final BookingState state;
}
```

## Repository Conformance Gate
- `oaef doctor` — structural, skill and entrypoint conformance.
- `oaef lint` — `CC-*` advisory sweep plus `SK-01`…`SK-06` and secret detection.
- `oaef clean-code` (native: `dart run tool/governance.dart clean-code`) — blocking under the `strict` profile.
- Unresolved findings are recorded in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The slice owns `presentation`, `domain` and `data`; no dependency reaches into another feature.
- Every screen file is at or under 300 lines and every method at or under 50 lines.
- Loading, success, empty and error paths each render a distinct, tested state.
- Routing arguments are typed and the screen is previewable in isolation.

## Anti-Patterns
- A 600-line screen mixing network parsing, layout and navigation.
- Passing raw `Map<String, dynamic>` route arguments and casting at the destination.
- State scattered across `setState` calls in several widgets of the same slice.
- A screen reaching into another feature's `data` or `presentation` layer.
- Shipping without a preview or a test for the error state.
