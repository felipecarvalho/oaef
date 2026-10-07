---
name: collect-coverage
description: >-
  Use when measuring, collecting or enforcing coverage for Expo. Triggers on: "coverage", "lcov", "jacoco",
  "cobertura", "branches". Chains into: run-static-analysis, code-review. Extracts native Expo coverage (LCOV,
  JaCoCo, Cobertura or Coverlet), compares the result with the baseline floors of the repository, and applies the
  Monotonic Ratchet so quality can only move up.
argument-hint: "[coverage artifact or scope]"
license: MIT
metadata:
  framework: OAEF
  stack: expo
  version: 1.1.0
---

# Collect Coverage (Expo)

> **Stack Profile:** Expo
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Measure coverage from the real test run and compare it with the repository baseline floors. The Monotonic Ratchet allows quality to move only up: floors may be raised, never lowered. Coverage is evidence, not a vanity number.

## Territory
- `coverage/lcov.info` - the LCOV artifact produced by Jest.
- `__tests__/`, `test/` - the suites that produce coverage.
- `docs/wiki/metrics/baseline.json` - the floors this run is compared against.

## Coverage Extraction
1. Run the suite with coverage enabled:

   ```bash
   npx jest --coverage
   ```

2. Confirm the artifact at `coverage/lcov.info`; the `jest-expo` preset writes LCOV by default.
3. Read lines, statements, functions, and branches; floor targets are 95% lines and statements, 90% branches.
4. Compare against `docs/wiki/metrics/baseline.json`; report every metric below its floor.
5. Coverage is measured on production code only; previews, fixtures, and test helpers are excluded.

## Monotonic Ratchet
- If a metric exceeds its floor, raise the floor in `docs/wiki/metrics/baseline.json` in the same change.
- Never lower a floor to make a build pass; fix the uncovered branch instead.
- A new module enters with its measured coverage as a temporary floor and must ratchet upward.
- The ratchet runs under `oaef quality-gate` (native: `node tool/governance.mjs quality-gate`).
- Record the current metric alongside the artifact path in the pull request evidence.

## Repository Conformance Gate
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`) and fix every blocking finding.
- Run `oaef lint` and `oaef doctor`.
- Record any floor change and its justification in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `coverage/lcov.info` exists and every metric meets or exceeds its baseline floor.
- Any raised floor is committed in the same change as the code that earned it.
- No floor was lowered.

## Anti-Patterns
- Lowering a baseline floor to unblock a failing gate.
- Counting tests, previews, or generated files toward production coverage.
- Reporting a coverage number that does not come from the current test run.
