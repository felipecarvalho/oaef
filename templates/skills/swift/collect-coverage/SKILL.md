---
name: collect-coverage
description: >-
  Use when measuring, collecting or enforcing coverage for Swift. Triggers on: "coverage", "lcov", "jacoco", "cobertura", "branches". Chains into: run-static-analysis, code-review. Extracts native Swift coverage (LCOV, JaCoCo, Cobertura or Coverlet), compares the result with the baseline floors of the repository, and applies the Monotonic Ratchet so quality can only move up.
argument-hint: "[coverage artifact or scope]"
license: MIT
metadata:
  framework: OAEF
  stack: swift
  version: 1.1.0
---

# Collect Coverage (Swift)

> **Stack Profile:** Swift
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Extract native Swift coverage, compare it with the repository baseline floors, and enforce the Monotonic Ratchet so a change can only raise the floor. Coverage is a floor to defend, never a target to game.

## Territory
- `Tests/` — the suites that produce coverage.
- `.build/` — `swift test` build artifacts and profdata.
- `docs/wiki/metrics/baseline.json` — the recorded floors per scope.
- Coverage exports under `coverage/` or the Xcode result bundle.

## Coverage Extraction
- Line coverage from `swift test --enable-code-coverage` and `llvm-cov export`.
- Xcode/iOS targets report through `xccov` from the result bundle.
- Export to LCOV for a language-agnostic artifact when the pipeline requires it.
- Scope coverage to production `Sources/`; exclude `Tests/` and generated files.
- Branch coverage is reported alongside line coverage.
- The artifact is deterministic and committed only where the pipeline expects it.

## Monotonic Ratchet
- Read the floors from `docs/wiki/metrics/baseline.json` before comparing.
- A drop below a recorded floor is a `[BLOCKER]`, not a warning.
- A rise raises the floor and is written back through `oaef metrics`.
- New files without a floor enter at their measured value, never at zero retroactively.
- Compare per scope, not only at the repository total.
- Report uncovered branches, not just uncovered lines.

## Repository Conformance Gate
- `oaef doctor`
- `oaef lint`
- `oaef clean-code` (native: `swift tool/governance.swift clean-code`)
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- A coverage artifact is exported and machine-readable.
- No scope falls below its recorded floor.
- Raised floors are persisted in `baseline.json`.
- Uncovered branches are listed with file and line.

## Anti-Patterns
- Adding tests that assert nothing to inflate the percentage.
- Excluding production files to pass the gate.
- Comparing only the repository total and hiding a regressed scope.
- Lowering a floor to make a failing pipeline green.
- Treating line coverage as a substitute for branch coverage.
