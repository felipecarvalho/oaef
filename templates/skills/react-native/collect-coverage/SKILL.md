---
name: collect-coverage
description: >-
  Use when measuring, collecting or enforcing coverage for React Native. Triggers on: "coverage", "lcov", "jacoco", "cobertura", "branches". Chains into: run-static-analysis, code-review. Extracts native React Native coverage (LCOV, JaCoCo, Cobertura or Coverlet), compares the result with the baseline floors of the repository, and applies the Monotonic Ratchet so quality can only move up.
argument-hint: "[coverage artifact or scope]"
license: MIT
metadata:
  framework: OAEF
  stack: react-native
  version: 1.1.0
---

# Collect Coverage (React Native)

> **Stack Profile:** React Native
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Measure the real statement and branch coverage of the React Native test suite, compare it with the repository floors, and enforce the Monotonic Ratchet.

## Territory
- `coverage/lcov.info` — Jest LCOV report.
- `coverage/coverage-final.json` — raw Istanbul data.
- `jest.config.*` — `collectCoverage` configuration and thresholds.
- `docs/wiki/metrics/baseline.json` — declared floors.

## Coverage Extraction
- Collect with `npm test -- --coverage`, which emits `coverage/lcov.info`.
- Restrict collection to `src/**` and exclude generated, preview and story files.
- Run the governance aggregation: `oaef metrics` (native: `node tool/governance.mjs metrics`).
- Read both lines and branches; a high line ratio with low branch coverage signals untested error paths.
- Report the exact artifact path and the aggregated totals.

## Monotonic Ratchet
- Compare aggregated coverage with the floors in `docs/wiki/metrics/baseline.json`; lines and branches are separate floors.
- If coverage rises, update the floor to the new value; the ratchet never lowers a floor automatically.
- If coverage falls below a floor, the run fails in the strict profile and warns in standard.
- New code must not lower global coverage; a deleted test is never a path to green.
- Record the measurement in `docs/wiki/metrics/history.json`.

## Repository Conformance Gate
- Run `oaef doctor` (native: `node tool/governance.mjs doctor`).
- Run `oaef lint` (native: `npx eslint .`).
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `coverage/lcov.info` exists and aggregates cleanly.
- Totals meet or exceed every baseline floor.
- The floors were raised when coverage improved; no floor was lowered.

## Anti-Patterns
- Committing coverage output as source.
- Excluding difficult modules from collection to lift the ratio.
- Reporting a number with no comparison against the floors.
- Deleting a failing test to fix a coverage gate.
