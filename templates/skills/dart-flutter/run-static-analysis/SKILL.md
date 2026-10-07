---
name: run-static-analysis
description: >-
  Use when the analyzer, linter or type checker reports findings in Dart & Flutter. Triggers on: "analyze", "lint", "typecheck", "warnings".
  Chains into: code-review. Runs the Dart & Flutter analyzer with warnings treated as errors and zero suppressions: every finding is fixed in the code instead of being silenced with an inline ignore directive, and machine-generated files stay the only exemption.
argument-hint: "[scope or analyzer]"
license: MIT
metadata:
  framework: OAEF
  stack: dart-flutter
  version: 1.1.0
---

# Run Static Analysis (Dart & Flutter)

> **Stack Profile:** Dart & Flutter
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Drive the Dart analyzer and the Flutter analyzer to a clean, warning-free state and keep them there. Findings are corrected in the source, never silenced, and the analysis runs as a blocking gate before review.

## Territory
- `lib/**` — every production source analyzed by `dart analyze`.
- `test/**` — test sources analyzed with the same ruleset.
- `analysis_options.yaml` — the lint configuration; the single source of analyzer policy.
- `tool/**` — the governance engine, excluded from production analysis but kept warning-free.

## Analyzer Invocation
- Run `dart analyze --fatal-infos` for a pure Dart package and `flutter analyze` for an application; both must exit clean.
- Treat infos and warnings as errors: `--fatal-infos` and `--fatal-warnings` are the working defaults.
- Analyze the whole workspace before review, not only the touched file; a change can introduce findings elsewhere.
- Run the governance sweep in the same pass: `oaef clean-code` (native: `dart run tool/governance.dart clean-code`).
- Re-run the analyzer after every remediation until the output is empty.

## Zero-Suppression Policy
- Inline suppressions are prohibited: `// ignore:`, `// ignore_for_file:` and `// coverage:ignore-line` are findings, not fixes.
- A rule that seems wrong is disabled once, with justification, in `analysis_options.yaml` on a dedicated line, never per call site.
- `part` files that are machine-generated (`*.freezed.dart`, `*.g.dart`) are excluded by configuration; hand-written files are not.
- Fast-fixable findings (`dart fix --apply` for mechanical rules) are applied and reviewed, then re-analyzed.
- Do not weaken a lint severity to clear a finding; fix the code.

```bash
dart analyze --fatal-infos
flutter analyze
dart fix --apply
```

## Repository Conformance Gate
- `oaef doctor` — structural, skill and entrypoint conformance.
- `oaef lint` — `CC-*` advisory sweep plus `SK-01`…`SK-06` and secret detection.
- `oaef clean-code` (native: `dart run tool/governance.dart clean-code`) — blocking under the `strict` profile.
- Unresolved findings are recorded in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `dart analyze --fatal-infos` (or `flutter analyze`) exits with zero findings at every severity.
- No `// ignore:` suppression was added to clear a finding.
- Any rule disabled in `analysis_options.yaml` carries a written justification.
- The analyzer output is recorded for the review handoff.

## Anti-Patterns
- Adding `// ignore: avoid_print` instead of routing output through the logger (`CC-05`).
- Downgrading a warning to a hint to clear the gate.
- Analyzing only the changed file and shipping findings elsewhere.
- Leaving `dart fix` suggestions unapplied while closing the task.
- Disabling a whole lint family to silence one legitimate warning.
