---
name: fix-layout-issues
description: >-
  Use when a layout overflows, a constraint is unbounded or a render error breaks a surface in Dart & Flutter. Triggers on: "overflow", "unbounded", "layout", "layout broken", "render error".
  Chains into: test-generator, run-static-analysis. Diagnoses structural render defects in Dart & Flutter: it isolates the offending constraint, state or data shape, fixes the shared root cause instead of clipping the symptom, and proves the correction with a regression test.
argument-hint: "[symptom or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: dart-flutter
  version: 1.1.0
---

# Fix Layout Issues (Dart & Flutter)

> **Stack Profile:** Dart & Flutter
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Diagnose and repair structural render defects: overflow, unbounded constraints, intrinsic-size errors and assertion failures during layout. The fix targets the shared root cause in the layout tree or data shape, not the visible symptom, and is locked in by a regression test.

## Territory
- `lib/features/<feature>/presentation/**` — screens and widgets raising the overflow or render assertion.
- `lib/ui/**`, `lib/shared/**` — reusable layout primitives that propagate a bad constraint.
- `lib/features/<feature>/domain/**` — the data shape when an unexpected string or collection length drives the defect.
- `test/**` — the regression test reproducing the failing size, data or text scale.

## Triage Procedure
1. **Read the error verbatim** — a Flutter overflow logs the offending widget and the constraint (`RenderFlex overflowed by N pixels on the right`); capture the widget path, not just the exception type.
2. **Locate the constraint boundary** — walk from the reported widget upward to the nearest bounded box (`SizedBox`, `Expanded`, `Flexible`, `ConstrainedBox`). The defect lives where the bound is missing or wrong.
3. **Classify the cause**:
   - *Unbounded* — a scrollable or `Flex` child under an unbounded parent without `Expanded`/`Flexible`.
   - *Intrinsic* — a widget needing intrinsic dimensions inside a lazy list or an unbounded axis.
   - *Content-driven* — text or a list from data longer than the layout anticipated; fix the layout to adapt, not the data.
   - *Text-scale* — the defect only appears at a large `TextScaler`; fix wrapping and scrolling.
4. **Fix the root** — add the missing bound or the shared adaptive wrapper once, in the layout primitive, so every consumer inherits the fix. Do not clip with `ClipRect` or shrink the font to hide the symptom.
5. **Verify across sizes** — reproduce at the failing size, a smaller one and a large text scale before closing.
6. **Lock the regression** — add a widget test that pumps the failing configuration and asserts the corrected structure.

```dart
// Unbounded: wrap the flexible child so the row can distribute space.
Row(children: [Expanded(child: BookingSummary(booking: booking))]);
```

## Repository Conformance Gate
- `oaef doctor` — structural, skill and entrypoint conformance.
- `oaef lint` — `CC-*` advisory sweep plus `SK-01`…`SK-06` and secret detection.
- `oaef clean-code` (native: `dart run tool/governance.dart clean-code`) — blocking under the `strict` profile.
- Unresolved findings are recorded in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The reported overflow or render assertion no longer reproduces at the failing size.
- The fix is applied at the shared layout primitive, not per call site.
- A regression test reproduces the original configuration and passes after the fix.
- The surface holds at a large text scale and across compact and expanded widths.

## Anti-Patterns
- Wrapping the surface in `SingleChildScrollView` to mask an unbounded constraint.
- `ClipRect` or `overflow: TextOverflow.clip` on text that should wrap.
- Shrinking a font size to fit instead of letting the layout adapt.
- Patching one call site while equivalent widgets keep the same defect instead of the shared root.
- Deleting the failing test instead of fixing the constraint.
