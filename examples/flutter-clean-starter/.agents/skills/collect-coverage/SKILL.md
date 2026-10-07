---
name: collect-coverage
description: >-
  Use when measuring, collecting or enforcing coverage for Dart & Flutter. Triggers on: "coverage", "lcov", "jacoco", "cobertura", "branches".
  Chains into: run-static-analysis, code-review. Extracts native Dart & Flutter coverage (LCOV, JaCoCo, Cobertura or Coverlet), compares the result with the baseline floors of the repository, and applies the Monotonic Ratchet so quality can only move up.
argument-hint: "[coverage artifact or scope]"
license: MIT
metadata:
  framework: OAEF
  stack: dart-flutter
  version: 1.1.0
---

# Collect Coverage (Dart & Flutter)

> **Stack Profile:** Dart & Flutter
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Measure real coverage, compare it against the repository floors and enforce the Monotonic Ratchet. Coverage is produced by the native test runner, parsed from the canonical artifact, and never inflated by excluding production files.

## Territory
- `coverage/lcov.info` — the canonical Dart/Flutter coverage artifact.
- `test/**`, `test/features/<feature>/**` — the sources that produce the artifact.
- `lib/**` — the production scope that coverage must reflect.
- `docs/wiki/metrics/baseline.json` — the declared line and branch floors.

## Coverage Extraction
- Produce the artifact with the native runner: `flutter test --coverage` (or `dart test --coverage=coverage`); the result is written to `coverage/lcov.info`.
- Confirm the artifact lists real production files under `lib/`; a report covering only `test/` is invalid.
- Aggregate line and branch coverage from `lcov.info` (`genhtml`/`lcov` tooling or the governance engine) and report both.
- Never delete `lcov.info` to hide a regression, and never add production files to an ignore list to raise the percentage.
- Regenerate coverage after any code change before reading the number.

## Monotonic Ratchet
- Compare the measured line and branch coverage against the floors in `docs/wiki/metrics/baseline.json`.
- Coverage may rise freely; it may never fall below the recorded floor. A move upward becomes the new floor once committed.
- A new module inherits the current repository floor, not a lower local target.
- When the floor is missed, `oaef quality-gate` fails; the fix is more tests, never a lowered baseline.
- Record the new floors in the baseline and in `docs/wiki/log.md` when the ratchet advances.

```bash
flutter test --coverage
oaef metrics --coverage coverage/lcov.info
```

## Repository Conformance Gate
- `oaef doctor` — structural, skill and entrypoint conformance.
- `oaef lint` — `CC-*` advisory sweep plus `SK-01`…`SK-06` and secret detection.
- `oaef clean-code` (native: `dart run tool/governance.dart clean-code`) — blocking under the `strict` profile.
- `oaef quality-gate` — fails when lines or branches fall below the floors.
- Unresolved findings are recorded in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `coverage/lcov.info` is regenerated and reflects the current `lib/` scope.
- Line and branch coverage meet or exceed every declared floor.
- The ratchet floor is updated only upward.
- The coverage command and result are recorded for the review handoff.

## Anti-Patterns
- Lowering a baseline floor to make the gate pass.
- Committing a stale `lcov.info` that predates the latest change.
- Excluding production files to inflate the percentage.
- Reporting line coverage while branch coverage silently regressed.
- Adding tests that execute code without asserting its behavior.
