---
name: component-author
description: >-
  Use when authoring or extracting a reusable component, widget, button, card or modal in Dart & Flutter. Triggers on: "component", "widget", "button", "card", "modal".
  Chains into: ui-preview, responsive-layout, test-generator. Authors reusable Dart & Flutter surfaces from design-system tokens: one responsibility per component, tokens instead of literals, and a contract that serves every consumer without a bespoke variant.
argument-hint: "[component name]"
license: MIT
metadata:
  framework: OAEF
  stack: dart-flutter
  version: 1.1.0
---

# Component Author (Dart & Flutter)

> **Stack Profile:** Dart & Flutter
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Author reusable widgets that carry one responsibility and read their visual contract from the design system. A component serves every consumer through a stable API, never through a per-screen variant, and remains previewable in isolation.

## Territory
- `lib/ui/**` — design-system widgets and their tokens.
- `lib/shared/**` — cross-feature widgets that compose design-system primitives.
- `lib/features/<feature>/presentation/**` — feature-local widgets extracted toward reuse.
- `test/**` — widget tests and golden tests for the component contract.
- `pubspec.yaml` — confirms the design-system package before hand-rolling a token.

## Component Contract
- **One responsibility** — a widget renders one surface concept. Split a "card+form+actions" class into composed widgets.
- **Stateless by default** — const-constructible presentational widgets; state belongs to the holder that owns it.
- **Typed parameters** — explicit named parameters with `required`/`final`; never a `Map<String, dynamic>` of options or a `variant` string that toggles unrelated behavior.
- **Callbacks, not coupling** — a component emits intent (`onPressed`), it never calls a repository or a container (`CC-07`).
- **Immutable surface** — no `late final` field assigned after construction (`CC-03`).
- **Defaults that satisfy the contract** — an optional collection defaults to a constant empty collection (`CC-08`).

```dart
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
}
```

## Token Discipline
- Colors, spacing, radii and typography come from `Theme.of(context)` and the project's token extensions; literals such as `Color(0xFF...)` or `EdgeInsets.all(13)` are prohibited.
- Reuse the framework primitive (`TextButton`, `Card`, `Dialog`) as the base and override through the theme; do not reimplement a platform widget from scratch.
- A new token is added to the design system once and consumed everywhere; a one-off value is a defect.
- Prefer `const` constructors and `ThemeData` lookups so the component reacts to theme and text-scale changes.

## Repository Conformance Gate
- `oaef doctor` — structural, skill and entrypoint conformance.
- `oaef lint` — `CC-*` advisory sweep plus `SK-01`…`SK-06` and secret detection.
- `oaef clean-code` (native: `dart run tool/governance.dart clean-code`) — `CC-07`, `CC-08` blockers under the `strict` profile.
- Unresolved findings are recorded in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The widget has one responsibility, one typed contract and a `const` constructor.
- Zero hardcoded color, spacing or typography literals inside the component.
- The component consumes design-system tokens and renders correctly under the active theme.
- A preview and a widget test exist for the contract's default and edge states.

## Anti-Patterns
- A `AppCard` with a `String variant` switch that changes layout, actions and data source.
- `Color(0xFF1F6FEB)` and `EdgeInsets.all(13)` inlined in a shared widget.
- A component resolving `getIt<BookingRepository>()` internally (`CC-07`).
- `late final` controller fields mutated after build (`CC-03`).
- Copying a widget into a feature and tweaking one color instead of parametrizing the token.
