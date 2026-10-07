---
name: collect-coverage
description: >-
  Use when measuring, collecting or enforcing coverage for TypeScript & Web. Triggers on: "coverage", "lcov", "jacoco", "cobertura", "branches". Chains into: run-static-analysis, code-review. Extracts native TypeScript & Web coverage (LCOV, JaCoCo, Cobertura or Coverlet), compares the result with the baseline floors of the repository, and applies the Monotonic Ratchet so quality can only move up.
argument-hint: "[coverage artifact or scope]"
license: MIT
metadata:
  framework: OAEF
  stack: typescript-web
  version: 1.1.0
---

# Collect Coverage (TypeScript & Web)

> **Stack Profile:** TypeScript & Web
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission

Measure real coverage, compare it with the repository floors, and enforce the Monotonic
Ratchet: floors rise, never fall. Coverage is evidence, not a target to game.

## Territory

- `coverage/lcov.info` — the LCOV artifact produced by the test runner.
- `coverage/` — HTML reports and intermediate output; generated, never committed.
- `docs/wiki/metrics/baseline.json` — the coverage floors of the repository.
- `docs/wiki/metrics/history.json` — the append-only trend.
- `vitest.config.ts`, `jest.config.ts`, `nyc` config — the collector settings.

## Coverage Extraction

1. Run the suite with coverage: `npm test -- --coverage` (native artifact
   `coverage/lcov.info`).
2. Confirm the artifact exists and is non-empty; a missing LCOV is a failure, not a zero.
3. Read the summary: lines, statements, functions and branches. Branches are the
   meaningful signal, not the global percentage.
4. Compare each metric with `docs/wiki/metrics/baseline.json`.
5. Exclude only machine-generated files and true entry shims; never exclude a file to
   raise the average.
6. Record the run in `docs/wiki/metrics/history.json` via `oaef metrics`.

## Monotonic Ratchet

- If coverage is at or above the floor, update the floor upward to the new value when it
  improved; never lower it.
- If coverage dropped, the change fails until either tests restore it or the reduction is
  justified and the floor is adjusted explicitly, with a recorded reason.
- `oaef quality-gate` performs this comparison; under the strict profile a drop blocks.
- The ratchet is monotonic across the whole repository: a green slice never excuses a red
  one.
- Treat branch coverage floors as the primary gate; line coverage alone can hide untested
  error paths.

## Repository Conformance Gate

- Run `oaef doctor`, `oaef lint`, `oaef clean-code` (native:
  `node tool/governance.mjs doctor|lint|clean-code`).
- Run `oaef quality-gate` and `npm test -- --coverage`.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria

- `coverage/lcov.info` is freshly generated and parsed.
- Every metric is at or above its baseline floor, and improved floors are committed.
- No file was excluded to inflate the number.

## Anti-Patterns

- Lowering a baseline floor to make the gate pass.
- Reporting a global percentage while branch coverage silently regresses.
- Committing `coverage/` output to the repository.
- Excluding the files with the most complex branches from the collector.
