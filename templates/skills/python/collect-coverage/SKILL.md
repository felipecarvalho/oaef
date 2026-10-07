---
name: collect-coverage
description: >-
  Use when measuring, collecting or enforcing coverage for Python 3. Triggers on: "coverage", "lcov", "jacoco", "cobertura", "branches". Chains into: run-static-analysis, code-review. Extracts native Python 3 coverage (LCOV, JaCoCo, Cobertura or Coverlet), compares the result with the baseline floors of the repository, and applies the Monotonic Ratchet so quality can only move up.
argument-hint: "[coverage artifact or scope]"
license: MIT
metadata:
  framework: OAEF
  stack: python
  version: 1.1.0
---

# Coverage Collection (Python 3)

> **Stack Profile:** Python 3
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Measure real branch coverage, compare it against the baseline floors, and enforce the
Monotonic Ratchet so the floors never move down.

## Territory
- `coverage.xml` — Cobertura artifact written by `pytest-cov`.
- `coverage.lcov` — LCOV artifact when a downstream consumer requires it.
- `tests/` — the tests producing the coverage measurement.
- `docs/wiki/metrics/baseline.json` — the floors this skill compares against.

## Coverage Extraction
- Run `pytest --cov=<package> --cov-branch --cov-report=xml:coverage.xml --cov-report=lcov:coverage.lcov`.
- Always enable branch coverage; line coverage alone is not the gate.
- Exclude only generated and migration paths through one `[tool.coverage]` configuration,
  never with scattered `# pragma: no cover` comments.
- Report the two governed numbers separately: line percentage and branch percentage.
- Compare against the floors in `baseline.json`; a floor is a minimum, not a target to hit.
- Treat a drop as a failure even when the absolute number stays above the floor only if
  the ratchet has previously locked a higher value.

## Monotonic Ratchet
- The ratified value is `max(previous_floor, current_measured)` after a passing run.
- When coverage rises, raise the floor in `baseline.json` in the same change.
- Never lower a floor to make a build pass; instead add the missing tests.
- Track history in `docs/wiki/metrics/history.json` for trend verification.
- A new module starts at zero floor and must ship with its own tests in the same change.
- The ratchet applies to both line and branch floors independently.

## Repository Conformance Gate
- `oaef doctor` — structural conformance.
- `oaef lint` — governance findings.
- `oaef clean-code` (native: `python3 tool/governance.py clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `coverage.xml` exists and reports branch coverage for the measured scope.
- The measured line and branch values are at or above the current floors.
- Any floor increase is committed together with the tests that earned it.

## Anti-Patterns
- Disabling branch coverage to raise the headline percentage.
- Scattering `# pragma: no cover` to hide unreachable branches that are actually reachable.
- Lowering a floor to unblock a failing pipeline.
- Measuring only the happy-path module and ignoring error-handling modules.
- Recording the number without updating the baseline, so the ratchet never advances.
