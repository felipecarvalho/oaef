---
name: ui-preview
description: >-
  Use when a component or screen must be inspected in isolation before it is wired into the application in Dart & Flutter. Triggers on: "preview", "storybook", "isolated render".
  Chains into: test-generator, run-static-analysis. Provides isolated preview harnesses for Dart & Flutter: loading, success, empty and error states are rendered without booting the full runtime, so layout, tokens and typography are validated before integration.
argument-hint: "[component or screen name]"
license: MIT
metadata:
  framework: OAEF
  stack: dart-flutter
  version: 1.1.0
---

# UI Preview (Dart & Flutter)

> **Stack Profile:** Dart & Flutter
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Render a widget in isolation so its states can be judged before integration. The harness mounts the real widget with injected dependencies and fixed data, exposing loading, success, empty and error variants without starting the application runtime or performing real I/O.

## Territory
- `lib/features/<feature>/presentation/**` — screens and feature widgets with a preview entry point.
- `lib/ui/**`, `lib/shared/**` — reusable components previewed across themes and text scales.
- `test/**` — preview widgets mounted inside widget tests for regression coverage.
- `lib/main.dart` — the theme and locale the preview harness reuses, never bypasses.

## Preview Harness
- **Real widget, fake data** — mount the production widget; inject fakes or fixtures for its contracts. Never fork the widget into a preview-only copy.
- **One harness per surface** — a preview entry point (a `@Preview`-style widget, a `story` widget or a dedicated test) lives next to the component it renders.
- **State matrix** — render loading, success, empty and error; the empty and error states are mandatory, not optional.
- **Theme and scale** — render under the app `ThemeData` and at least one enlarged text scale to expose overflow and token drift.
- **No runtime boot** — the harness must not require the real composition root, a network client or persisted storage; inject fixtures instead.

```dart
class BookingCardPreview extends StatelessWidget {
  const BookingCardPreview({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: BookingCard(booking: makeBooking())),
      );
}
```

- A preview that needs a real container (`getIt<`) is a signal to inject the dependency instead (`CC-07`).
- Keep the harness free of business rules; it exercises layout, tokens and typography only.

## Repository Conformance Gate
- `oaef doctor` — structural, skill and entrypoint conformance.
- `oaef lint` — `CC-*` advisory sweep plus `SK-01`…`SK-06` and secret detection.
- `oaef clean-code` (native: `dart run tool/governance.dart clean-code`) — blocking under the `strict` profile.
- Unresolved findings are recorded in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The surface renders in isolation with no application runtime, network call or persisted state.
- All four states (loading, success, empty, error) are covered by the harness.
- Layout and typography are validated under the app theme and an enlarged text scale.
- The preview is retained as a regression test or story alongside the component.

## Anti-Patterns
- Copy-pasting the widget into a preview file so the preview diverges from production.
- Previewing only the success state and discovering the error layout in production.
- A preview that boots the real container and performs network I/O.
- Hardcoding a light theme when the app ships dark mode and dynamic type.
- Deleting the harness after the review, losing the regression surface.
