---
name: test-generator
description: >-
  Use when writing or expanding automated tests, mocks or fixtures for Universal / Polyglot. Triggers on: "test", "coverage", "mock", "fixture". Chains into: collect-coverage, run-static-analysis. Generates Universal / Polyglot tests with the AAA pattern and one DRY factory per entity: unit, component and integration coverage of the happy path and of every error branch, with deterministic data and no dead parameters.
argument-hint: "[target class or module]"
license: MIT
metadata:
  framework: OAEF
  stack: universal
  version: 1.1.0
---

# Test Generator (Universal / Polyglot)

> **Stack Profile:** Universal / Polyglot
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Generate deterministic tests for any embedded language in this repository, each entity built by one dry factory, covering the happy path and every error branch.

## Territory
- Test trees of the embedded languages: `test/`, `tests/`, `__tests__/`, `*_test.go`, `tests/`, `#[cfg(test)]`, `src/**/*.spec.ts`, `src/**/*.test.tsx`.
- Harness commands: `bash test.sh`; per language `pytest`, `go test`, `cargo test`, `npm test`, `./gradlew test`, `dart test`.
- Fixtures and doubles live beside the suite they serve.

## Testing Pyramid
- **Unit** — pure logic, no I/O; the majority of the suite.
- **Component / integration** — one boundary at a time (serializer, widget, handler) with a fake at the seam.
- **End-to-end** — only the critical user or API paths; keep it thin.
- Every branch introduced by a guard clause needs a unit test that reaches it.
- A renamed or deleted behavior deletes its test in the same change; orphaned tests are dead weight.
- The suite for a slice lives beside it so the test tree mirrors production structure.

## DRY Test Factories (make*)
- One factory per entity: `make<Entity>` (Dart/Kotlin/Swift/C#) or `make_<entity>` (Python/Rust), `makeX` in shell `run_case` style.
- The factory takes only the parameters that vary in the suite; everything else is a shared constant.
- No dead parameters: an argument never customized is removed.
- Collection parameters default to a constant empty collection, never `null`.
- Tests use AAA: arrange through the factory, act once, assert one behavior.

## Repository Conformance Gate
- `oaef doctor` and `oaef lint` clean for the touched repository.
- `oaef clean-code` (native: `bash tool/governance.sh clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every new behavior has a test that fails when the behavior is reverted.
- Every `make*` factory has at least two callers or is inlined.
- The suite is deterministic: two consecutive runs report the same result.

## Anti-Patterns
- A factory with a long parameter list where most callers pass the defaults.
- Asserting implementation details instead of observable behavior.
- A mock that re-implements the production logic it stands in for.
