---
name: test-generator
description: >-
  Use when writing or expanding automated tests, mocks or fixtures for Rust. Triggers on: "test",
  "coverage", "mock", "fixture". Chains into: collect-coverage, run-static-analysis. Generates Rust tests
  with the AAA pattern and one DRY factory per entity: unit, component and integration coverage of the
  happy path and of every error branch, with deterministic data and no dead parameters.
argument-hint: "[target class or module]"
license: MIT
metadata:
  framework: OAEF
  stack: rust
  version: 1.1.0
---

# Test Generator (Rust)

> **Stack Profile:** Rust
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Generate deterministic Rust tests that cover the happy path and every error branch, using trait fakes and
one DRY factory per entity so a domain change is reflected in a single place.

## Territory
- `src/**/*.rs` under `#[cfg(test)] mod tests` — unit tests next to the code under test.
- `tests/**/*.rs` — integration tests exercising the public crate API.
- `tests/fixtures/**` — shared deterministic sample data.
- Trait fakes live beside the suite that consumes them.

## Testing Pyramid
- Unit tests (`#[cfg(test)]`) — pure domain logic, exhaustive match arms, guard clauses, error paths.
- Component tests — a module exercised through its public contract with trait fakes for its collaborators.
- Integration tests (`tests/`) — the crate wired end to end against in-process fakes, no network.
- Test the error branch as deliberately as the happy path; an untested `Err` arm is a defect.
- One assertion focus per test; name the test for the behavior and the condition it guards.

## DRY Test Factories (make*)
- One factory per entity, named `make_<entity>()`, returning a fully valid value with sensible defaults:
  ```rust
  fn make_order() -> Order {
      Order { id: OrderId::from(1), status: Status::Draft, items: vec![] }
  }
  ```
- The factory takes only parameters that vary in the suite; delete parameters no caller overrides.
- Compose factories (`make_order_with_items(n)`) instead of duplicating literal construction.
- No dead parameters and no `Option` fields used as unused knobs; defaults are constant and valid.
- Arrange-Act-Assert with blank-line separation; assert on observable output, not on internal calls
  unless the interaction is the contract.

## Repository Conformance Gate
- `cargo run --bin governance -- clean-code`
- `cargo test` plus `oaef lint`, `oaef doctor`
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- New behavior has unit or component tests covering success and failure branches.
- Every entity under test has exactly one factory, with no dead parameters.

## Anti-Patterns
- A test asserting only the happy path while error arms stay untested.
- Hand-built literals duplicated in every test instead of a factory.
- Over-parameterized factories with knobs no caller uses.
- Tests depending on wall-clock time, randomness or external I/O.
