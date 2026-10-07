---
name: collect-coverage
description: >-
  Use when measuring, collecting or enforcing coverage for Rust. Triggers on: "coverage", "lcov",
  "jacoco", "cobertura", "branches". Chains into: run-static-analysis, code-review. Extracts native Rust
  coverage (LCOV, JaCoCo, Cobertura or Coverlet), compares the result with the baseline floors of the
  repository, and applies the Monotonic Ratchet so quality can only move up.
argument-hint: "[coverage artifact or scope]"
license: MIT
metadata:
  framework: OAEF
  stack: rust
  version: 1.1.0
---

# Coverage Collection (Rust)

> **Stack Profile:** Rust
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Measure native Rust coverage, compare it with the repository baseline floors, and enforce the Monotonic
Ratchet: a floor never decreases, and new code must meet the same standard as existing code.

## Territory
- `src/**/*.rs` — the instrumented production code.
- `coverage/` — generated artifacts (`lcov.info`, `cobertura.xml`); never hand-edited.
- `docs/wiki/metrics/baseline.json` — declared floors consumed by `oaef quality-gate`.
- `tests/` — the suites whose execution produces the coverage profile.

## Coverage Extraction
- Line and branch coverage from `cargo llvm-cov --lcov --output-path coverage/lcov.info`, or
  `cargo tarpaulin --out Lcov` when chosen by the repository.
- Export Cobertura with `cargo llvm-cov --cobertura --output-path coverage/cobertura.xml` for tools that
  consume that format.
- Exclude generated code and `tool/` from the report; never exclude production modules to inflate the
  number.
- Read the floors from `docs/wiki/metrics/baseline.json` and compare line and branch percentages.
- Run `oaef quality-gate` to apply the comparison in one step.

## Monotonic Ratchet
- A floor recorded in the baseline is never lowered; a decrease is a blocking finding.
- Legacy or adoption projects may record the measured value today as the initial floor; from then on the
  ratchet only moves up.
- New modules meet the repository-wide floor, not a relaxed per-module exception.
- When a coverage run drops, identify the uncovered diff lines and add the missing branch tests rather
  than editing the baseline.

## Repository Conformance Gate
- `cargo run --bin governance -- clean-code`
- `oaef quality-gate` and `oaef metrics`
- `oaef lint`, `oaef doctor`
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Coverage artifacts are regenerated from the current suite and compared with the baseline.
- No floor decreased, and every uncovered diff line is either tested or explicitly justified.

## Anti-Patterns
- Editing the baseline to make the gate pass.
- Excluding a production module from measurement to raise the percentage.
- Chasing a global number while the changed lines stay untested.
- Committing hand-modified coverage artifacts.
