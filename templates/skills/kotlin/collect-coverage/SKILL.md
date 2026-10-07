---
name: collect-coverage
description: >-
  Use when measuring, collecting or enforcing coverage for Kotlin & JVM. Triggers on: "coverage", "lcov", "jacoco", "cobertura", "branches". Chains into: run-static-analysis, code-review. Extracts native Kotlin & JVM coverage (LCOV, JaCoCo, Cobertura or Coverlet), compares the result with the baseline floors of the repository, and applies the Monotonic Ratchet so quality can only move up.
argument-hint: "[coverage artifact or scope]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin
  version: 1.1.0
---

# Collect Coverage (Kotlin & JVM)

> **Stack Profile:** Kotlin & JVM
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Measure what the tests actually execute, compare it against the repository floors, and
raise the floor when coverage improves. Coverage is a ratchet, not a trophy: it never
regresses and never drops below the recorded baseline.

## Territory
- `build/reports/jacoco/test/jacocoTestReport.xml` — JaCoCo report.
- `build/reports/jacoco/test/html/` — human-readable report.
- `build.gradle.kts` — the `jacocoTestReport` and verification tasks.
- `docs/wiki/metrics/baseline.json` — recorded floors.

## Coverage Extraction
- Run tests with coverage: `./gradlew test jacocoTestReport`.
- Enable branch coverage; line-only coverage hides untested branches.
- Parse the XML report; read `line` and `branch` counters, not the HTML.
- Exclude generated sources, ViewBinding output and DI-generated modules explicitly.
- Report per-module and per-package, not one aggregate number that hides dead zones.

```bash
./gradlew test jacocoTestReport
python3 tool/coverage_gate.py build/reports/jacoco/test/jacocoTestReport.xml
```

## Monotonic Ratchet
- Compare measured line and branch coverage with `baseline.json` floors.
- If coverage improved, update the floor to the new measured value.
- If coverage dropped, fail the gate; the change must add tests before merge.
- New modules start at the repository default floor, never at zero.
- Never lower a floor to accommodate a regression; fix the test gap instead.

## Repository Conformance Gate
- Run `oaef doctor` (native: `kotlinc -script tool/governance.main.kts doctor`).
- Run `oaef metrics` to compare against the baseline, plus `oaef lint`.
- Record measured deltas and any justified exclusions in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Coverage report generated with branch counters enabled.
- Measured coverage is at or above every recorded floor.
- Floors updated upward when coverage improved.
- Exclusions are explicit and justified in the build configuration.

## Anti-Patterns
- Reporting a single aggregate percentage that hides untested modules.
- Lowering a baseline floor to make a pipeline green.
- Line-only coverage masking untested error branches.
- Excluding packages silently to inflate the number.
