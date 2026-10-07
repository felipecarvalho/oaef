---
name: collect-coverage
description: >-
  Use when measuring, collecting or enforcing coverage for Kotlin Multiplatform. Triggers on: "coverage", "lcov", "jacoco", "cobertura", "branches". Chains into: run-static-analysis, code-review. Extracts native Kotlin Multiplatform coverage (LCOV, JaCoCo, Cobertura or Coverlet), compares the result with the baseline floors of the repository, and applies the Monotonic Ratchet so quality can only move up.
argument-hint: "[coverage artifact or scope]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.1.0
---

# Collect Coverage (Kotlin Multiplatform)

> **Stack Profile:** Kotlin Multiplatform
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Report the real coverage of the shared code across targets and enforce that the floor never drops. Coverage is a ratchet, not a dashboard.

## Territory
- `build/reports/kover/**` - Kover XML and HTML reports.
- `build/reports/jacoco/**` - JaCoCo XML when the project uses it.
- `docs/wiki/metrics/baseline.json` - the committed floors per metric.
- `docs/wiki/metrics/history.json` - append-only coverage history.

## Coverage Extraction
- Run `./gradlew koverXmlReport` (or `./gradlew jacocoTestReport`) to produce the XML report; do not parse HTML.
- Shared code coverage aggregates every target; inspect the per-target breakdown before trusting the total, because a target with no test inflates or deflates the ratio.
- Always report branch coverage next to line coverage; a covered line with an untested error branch is not covered.
- Run `oaef metrics` to fold the extraction into the repository metrics and `oaef quality-gate` to enforce it.
- Coverage artifacts are read, never hand-edited; a manual edit is rejected in review.
- Compare against `docs/wiki/metrics/baseline.json`; the baseline is the source of truth, not a badge.
- Exclude generated code, mappers without logic and `expect` declarations with no body from the ratio; document every exclusion.

## Monotonic Ratchet
- A floor may stay the same or rise; it never falls. Lowering a floor requires an explicit human decision recorded in the PR.
- A new module enters the baseline with the coverage measured on the day it is added, not with a convenient lower number.
- A change that adds an untested branch must also add the test that covers it; otherwise the branch coverage floor is breached.
- When the measured value exceeds the floor, update the floor upward in the same change.
- The ratchet is evaluated by `oaef quality-gate`; the report is appended to `docs/wiki/metrics/history.json`.

## Repository Conformance Gate
- Run `oaef metrics` and `oaef quality-gate` after extraction.
- Run `./gradlew allTests` so the report reflects the current tests.
- Record any unreachable code keeping the ratio down in `docs/wiki/memory/handoff.md` for deletion under `ponytail`.

## Exit Criteria
- The coverage report is regenerated and committed for the current change.
- No floor in `baseline.json` was lowered.
- Every new error branch is covered or explicitly deleted as unreachable.

## Anti-Patterns
- Lowering a floor "temporarily" without a recorded decision.
- Reading a stale report from a previous run instead of regenerating.
- Chasing a line-coverage number while branch coverage regresses.
