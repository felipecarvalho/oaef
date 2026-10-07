---
name: run-static-analysis
description: >-
  Use when the analyzer, linter or type checker reports findings in Kotlin Multiplatform. Triggers on: "analyze", "lint", "typecheck", "warnings". Chains into: code-review. Runs the Kotlin Multiplatform analyzer with warnings treated as errors and zero suppressions: every finding is fixed in the code instead of being silenced with an inline ignore directive, and machine-generated files stay the only exemption.
argument-hint: "[scope or analyzer]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.1.0
---

# Run Static Analysis (Kotlin Multiplatform)

> **Stack Profile:** Kotlin Multiplatform
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Drive the analyzer to zero findings and keep it there. A suppression is a hidden defect with a shorter lifetime than the bug it hides.

## Territory
- `src/commonMain/kotlin/**`, `src/androidMain/kotlin/**`, `src/iosMain/kotlin/**`, `src/desktopMain/kotlin/**` - analyzed production sources.
- `src/commonTest/kotlin/**` - test sources, held to the same lint rules.
- `detekt.yml`, `build.gradle.kts` - analyzer configuration and baselines.
- `tool/governance.main.kts` - the OAEF governance entrypoint.

## Analyzer Invocation
- Run `./gradlew detekt` as the primary analyzer; treat warnings as errors (`allWarningsAsErrors` in the compiler options where available).
- Run `./gradlew ktlintCheck` when the project adopts it, for formatting parity.
- Run `oaef clean-code` (native: `kotlinc -script tool/governance.main.kts clean-code`) for the `CC-*` barrier.
- Run `oaef lint` for the `SK-*` and secret checks; `oaef quality-gate` aggregates the totals against the baseline.
- Inspect the report file under `build/reports/detekt/` for the full rule, file and line, not just the console summary.
- Fix findings in the current change; never defer a new finding into a baseline file.

## Zero-Suppression Policy
- `@Suppress("RuleName")` is forbidden unless it carries a one-line justification and an owner in a `// ponytail:`-style comment; an unexplained suppression is a review blocker.
- Never edit `detekt-baseline.xml` to absorb new findings; a baseline entry is legacy debt to burn down, not a gate to weaken.
- Generated code is the only exemption; it lives under `build/` or a `*.generated.kt` name and is excluded by configuration, not by suppression.
- The `CC-*` checks (`CC-01` to `CC-11`) are never suppressible; fix the code.
- Warnings that only appear on one target must be fixed for all targets; a per-target exemption is forbidden.
- Re-run the analyzer after the fix and confirm the finding count dropped by exactly the number fixed.

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint` and `oaef clean-code` (native: `kotlinc -script tool/governance.main.kts clean-code`).
- Run `./gradlew detekt` with zero new findings.
- Record any legacy suppression still queued for removal in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `./gradlew detekt` reports zero findings on the changed sources.
- No new suppression or baseline entry was added.
- `oaef quality-gate` passes against the current baseline.

## Anti-Patterns
- Adding `@Suppress` to silence a real defect.
- Growing `detekt-baseline.xml` so the build turns green.
- Fixing a finding on one target and leaving the sibling source set broken.
