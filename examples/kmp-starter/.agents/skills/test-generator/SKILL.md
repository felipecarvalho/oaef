---
name: test-generator
description: >-
  Use when writing or expanding automated tests, mocks or fixtures for Kotlin Multiplatform. Triggers on: "test", "coverage", "mock", "fixture". Chains into: collect-coverage, run-static-analysis. Generates Kotlin Multiplatform tests with the AAA pattern and one DRY factory per entity: unit, component and integration coverage of the happy path and of every error branch, with deterministic data and no dead parameters.
argument-hint: "[target class or module]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.1.0
---

# Test Generator (Kotlin Multiplatform)

> **Stack Profile:** Kotlin Multiplatform
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Produce deterministic tests that run on every target with the fewest possible fixtures, covering the happy path and every error branch of the unit under test.

## Territory
- `src/commonTest/kotlin/**` - shared unit and component tests; the default home.
- `src/androidUnitTest/kotlin/**`, `src/iosTest/kotlin/**` - platform-specific behavior only.
- `**/features/<feature>/**` - the code under test, mirrored by package in the test source set.
- `build.gradle.kts` - test dependencies and coroutine test dispatchers.

## Testing Pyramid
- **Unit** - pure `kotlin.test` for domain logic, mappers and state reducers; the largest tier.
- **Component** - Compose UI tests for a stateless component's contract (renders, emits events, exposes semantics).
- **Integration** - one test per repository against a fake or in-memory backing, exercising error and retry paths.
- Use `runTest` from `kotlinx-coroutines-test`; inject a `TestDispatcher` into the ViewModel under test.
- Prefer hand-written fakes over mocking frameworks; a fake implementing the `domain` interface is testable on every target.
- Structure every test with the AAA pattern: arrange, act, assert, separated by a blank line.
- Name tests by behavior: `state is Failed when the repository throws`.
- Every error branch in production code has a corresponding test; a branch with no test is a gap, not an exemption.

## DRY Test Factories (make*)
- One factory per entity, in a shared test fixture file: `fun makeAccount(id: String = "a-1", balance: Long = 0L): Account`.
- Every parameter defaults to a valid value; a test overrides only what it asserts on.
- No dead parameters: a parameter that no test ever overrides is removed.
- No `null` defaults standing in for a real value; optional collections default to `emptyList()`.
- Factories are pure and deterministic: no clock, no random, no network; inject a fixed `Clock` or id when needed.
- Factory composition is allowed (`makeAccount()` inside `makeBooking()`); copy-pasted literals across tests are not.
- Reuse the same factory across the affected test files; a second factory for the same entity is rejected.

## Repository Conformance Gate
- Run `oaef clean-code` (native: `kotlinc -script tool/governance.main.kts clean-code`); tests are exempt from production-only checks but `CC-11` still applies.
- Run `./gradlew allTests` and confirm the new tests execute on every declared target.
- Record untested modules still missing a suite in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every new production behavior has at least one passing test on all targets.
- Each entity has exactly one `make<Entity>` factory with no dead parameters.
- No test depends on wall-clock time, network access or execution order.

## Anti-Patterns
- A test that asserts the mock was called instead of asserting the observable result.
- Over-parameterized factories with fields no test ever touches.
- Platform tests duplicating a `commonTest` that already covers the behavior.
