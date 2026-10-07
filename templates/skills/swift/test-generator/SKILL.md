---
name: test-generator
description: >-
  Use when writing or expanding automated tests, mocks or fixtures for Swift. Triggers on: "test", "coverage", "mock", "fixture". Chains into: collect-coverage, run-static-analysis. Generates Swift tests with the AAA pattern and one DRY factory per entity: unit, component and integration coverage of the happy path and of every error branch, with deterministic data and no dead parameters.
argument-hint: "[target class or module]"
license: MIT
metadata:
  framework: OAEF
  stack: swift
  version: 1.1.0
---

# Test Generator (Swift)

> **Stack Profile:** Swift
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Generate Swift tests that lock behavior at unit, component and integration level. Every test states its intent in the name, follows Arrange-Act-Assert, and receives deterministic data from a shared factory.

## Territory
- `Tests/<Module>Tests/` — unit and integration suites.
- `Tests/<Module>Tests/Fixtures/` — shared factories and fakes.
- `Sources/<Module>/Domain/` — the behavior under test.
- `Sources/<Module>/Presentation/` — component tests when a surface is non-trivial.

## Testing Pyramid
- Unit: pure domain logic, no I/O, the majority of the suite.
- Component: a view or view model rendered with injected fakes.
- Integration: repository and boundary behavior against a controlled collaborator.
- Doubles conform to the protocol, hand-written or from a mocking facility.
- `XCTest` or `swift-testing`; `runTest`-style async suites for `async/await` code.
- One assertion focus per test; a failing test names the broken invariant.

## DRY Test Factories (make*)
- One factory per entity, named `make<Entity>`, living in `Fixtures/`.
- The factory takes only parameters that actually vary between cases.
- Invalid or dead parameters are removed, not defaulted to `nil`.
- Optional collection parameters default to a constant empty collection.
- A test overrides exactly the fields it is about; everything else is the factory default.
- Duplicated literal setup across tests is a `[SHRINK]` finding.

## Repository Conformance Gate
- `oaef doctor`
- `oaef lint`
- `oaef clean-code` (native: `swift tool/governance.swift clean-code`)
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every new branch has at least one test that exercises it.
- Every entity has exactly one factory used by all its tests.
- Tests are deterministic and order-independent.
- `swift test` passes and coverage does not regress.

## Anti-Patterns
- A test that builds its whole fixture inline and duplicates a sibling test.
- A factory with parameters no test ever overrides.
- Sleeping on wall-clock time to await an async result instead of awaiting it.
- Asserting on a mock's call count instead of observable behavior.
- A test that only covers the happy path of a branchy type.
