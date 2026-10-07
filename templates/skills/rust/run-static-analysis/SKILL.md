---
name: run-static-analysis
description: >-
  Use when the analyzer, linter or type checker reports findings in Rust. Triggers on: "analyze", "lint",
  "typecheck", "warnings". Chains into: code-review. Runs the Rust analyzer with warnings treated as
  errors and zero suppressions: every finding is fixed in the code instead of being silenced with an
  inline ignore directive, and machine-generated files stay the only exemption.
argument-hint: "[scope or analyzer]"
license: MIT
metadata:
  framework: OAEF
  stack: rust
  version: 1.1.0
---

# Static Analysis (Rust)

> **Stack Profile:** Rust
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Run the Rust analyzer with warnings as errors and zero suppressions, so every diagnostic is answered by
a code change instead of an inline `#[allow]`.

## Territory
- `src/**/*.rs` — the analyzed production code.
- `tests/**/*.rs` — integration tests, analyzed for correctness but not for production checks.
- `examples/**` — preview binaries, kept warning-free.
- `tool/` — the governance binary; the only region allowed a documented exemption.

## Analyzer Invocation
- `cargo clippy --all-targets -- -D warnings` — the primary gate; warnings fail the build.
- `cargo check --all-targets` — fast type checking before the full lint pass.
- `cargo fmt --check` — formatting parity; apply with `cargo fmt` rather than editing by hand.
- `oaef lint` runs the governance checks (`SK-*`, secrets) alongside the native analyzer.
- Run the analyzer over the whole workspace after any change, not only the touched module.

## Zero-Suppression Policy
- No inline `#[allow(...)]` or `#![allow(...)]` in production code; fix the underlying finding.
- No `--cap-lints allow`, no `[lints]` table that downgrades a lint to silence it.
- When a generated file genuinely cannot be fixed, the exemption is declared once, scoped as narrowly as
  possible, and noted in `docs/wiki/log.md`; generated code is the only valid exemption.
- Deprecation warnings are fixed by migrating to the replacement, never by suppressing the warning.
- Treat a newly added suppression as a review blocker in the strict profile.

## Repository Conformance Gate
- `cargo run --bin governance -- clean-code`
- `oaef lint`, `oaef doctor`
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `cargo clippy --all-targets -- -D warnings` is clean across the workspace.
- No unsanctioned suppression directive remains in production code.

## Anti-Patterns
- `#[allow(dead_code)]` used to keep unused code compiling.
- Downgrading a lint in `Cargo.toml` or `clippy.toml` to hide findings.
- Fixing only the touched file while the workspace stays warning-ridden.
- Applying `cargo fmt` and committing unrelated reformatting churn.
