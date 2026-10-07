---
name: responsive-layout
description: >-
  Use when a surface must adapt to another screen size, form factor or payload shape in Dart & Flutter. Triggers on: "responsive", "adaptive", "breakpoint", "tablet", "foldable", "viewport".
  Chains into: ui-preview, test-generator. Owns adaptive design in Dart & Flutter: breakpoints, safe areas, dynamic type and foldables for interactive surfaces, and payload shaping, pagination, content negotiation and streaming backpressure for headless ones.
argument-hint: "[breakpoint or surface name]"
license: MIT
metadata:
  framework: OAEF
  stack: dart-flutter
  version: 1.1.0
---

# Responsive Layout (Dart & Flutter)

> **Stack Profile:** Dart & Flutter
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Make an interactive surface adapt to the actual viewport: compact phones, large tablets, foldable postures and desktop windows. Adaptation is driven by layout constraints and device metrics, never by device-name checks, and it stays inside the safe area and the user's text-scale preference.

## Territory
- `lib/features/<feature>/presentation/**` — screens and widgets that change shape across sizes.
- `lib/ui/**`, `lib/shared/**` — adaptive layout widgets and breakpoint helpers.
- `lib/main.dart` — `MaterialApp`/`ThemeData` text scaling and `builder` hooks for safe areas.
- `test/**` — widget tests parameterized over multiple `Size` and `TextScaler` values.

## Adaptive Surface Design
- **Constraints, not devices** — read the incoming constraints with `LayoutBuilder`, or the window size with `MediaQuery.sizeOf(context)`; never branch on `Platform.isX` or a device model string.
- **Breakpoints** — classify width into compact (< 600), medium (600–1023) and expanded (>= 1024) and pick one layout primitive per class.
- **Safe areas** — wrap adaptive surfaces in `SafeArea` or consume `MediaQuery.paddingOf(context)` so notches, gesture bars and foldable hinges never clip content.
- **Dynamic type** — respect `TextScaler` from the context; never clamp, ignore or hardcode a text scale. Layouts must survive a scaled-up font without overflow (`TextScaler.of(context)`).
- **Foldables and hinges** — read `MediaQuery.displayFeaturesOf(context)` and split the content across the hinge instead of rendering under it.
- **Orientation** — treat landscape and portrait as two sizes of the same surface, reusing the same sub-widgets.
- **Semantics** — adaptation never removes accessible targets or reorders focus unexpectedly.

## Breakpoint Strategy
1. Choose the container, not the screen, as the source of truth: `LayoutBuilder` makes a widget adaptive wherever it is mounted.
2. Map each breakpoint class to a layout family: single column, two-pane (list + detail), or navigation rail plus content.
3. Extract one sub-widget per pane and let the breakpoint only choose the arrangement; the panes never know the width themselves.
4. Bound content with `ConstrainedBox`/`Center` on expanded widths so text lines stay readable.
5. Verify each class with a widget test that pumps a fixed `Size` and asserts the expected layout structure.

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth >= 1024) return const BookingTwoPaneLayout();
    return const BookingSingleColumnLayout();
  },
)
```

## Repository Conformance Gate
- `oaef doctor` — structural, skill and entrypoint conformance.
- `oaef lint` — `CC-*` advisory sweep plus `SK-01`…`SK-06` and secret detection.
- `oaef clean-code` (native: `dart run tool/governance.dart clean-code`) — blocking under the `strict` profile.
- Unresolved findings are recorded in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The surface renders correctly at compact, medium and expanded widths with no overflow.
- Safe areas and foldable hinges are respected; no content renders under a system inset.
- Dynamic type scaling up to a large factor does not break or clip the layout.
- Widget tests cover each breakpoint class and the scaled-font case.

## Anti-Patterns
- Branching on `Platform.isAndroid` or a device model to choose a layout.
- A hardcoded `MediaQuery.textScaleFactor` reset that ignores the user preference.
- Fixed pixel widths that overflow at large text scales.
- Assuming a single pane on every tablet or desktop window.
- Reading `MediaQuery.of(context)` broadly and rebuilding the whole tree on every size change.
