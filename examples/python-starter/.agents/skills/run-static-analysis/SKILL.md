---
name: run-static-analysis
description: >-
  Use when the analyzer, linter or type checker reports findings in Python 3. Triggers on: "analyze", "lint", "typecheck", "warnings". Chains into: code-review. Runs the Python 3 analyzer with warnings treated as errors and zero suppressions: every finding is fixed in the code instead of being silenced with an inline ignore directive, and machine-generated files stay the only exemption.
argument-hint: "[scope or analyzer]"
license: MIT
metadata:
  framework: OAEF
  stack: python
  version: 1.1.0
---

# Static Analysis (Python 3)

> **Stack Profile:** Python 3
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Run the native analyzers with warnings promoted to errors and fix every finding in the
code. The build fails on a warning; silence is never a resolution.

## Territory
- `src/` and the repository root — the analyzed source scope.
- `pyproject.toml` — `ruff` and `mypy` configuration.
- `tests/` — analyzed by the same rules as production.
- `tool/governance.py` — the native governance entrypoint.

## Analyzer Invocation
- Lint: `ruff check .` with the full rule set enabled through `pyproject.toml`.
- Format check: `ruff format --check .`.
- Types: `mypy .` under strict optional and disallow-untyped-defs settings.
- Governance: `python3 tool/governance.py clean-code` (portable alias `oaef clean-code`).
- Run all three in sequence; a failure in any stops the gate.
- Analyzer configuration is committed once; per-directory overrides require a reason.

## Zero-Suppression Policy
- No `# noqa`, no `# type: ignore`, no `# pyright: ignore` added to silence a finding;
  fix the code instead.
- If a suppression is genuinely unavoidable, it must name the specific rule and carry a
  one-line justification referencing the reason it cannot be fixed.
- Machine-generated files are the only blanket exemption, declared by path in config.
- Broad rules (`# noqa` with no code) are always rejected.
- A finding resolved by widening a type to `Any` is not resolved.
- Fix the root cause, not the symptom: a lint error about an unused import means the
  import should be removed, not ignored.

## Repository Conformance Gate
- `oaef doctor` — structural conformance.
- `oaef lint` — governance findings.
- `oaef clean-code` (native: `python3 tool/governance.py clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `ruff check .`, `ruff format --check .` and `mypy .` pass with no new suppressions.
- Every prior finding is fixed in the source, not silenced in configuration.
- The governance `clean-code` check reports zero blocking findings.

## Anti-Patterns
- `# type: ignore` on a call whose real signature mismatch should be corrected.
- Disabling a rule globally to fix one local violation.
- Widening to `Any` to satisfy the type checker.
- Excluding a directory from analysis to avoid fixing it.
- Committing a formatting change separately from the logic change that triggered it.
