---
name: test-generator
description: >-
  Use when writing or expanding automated tests, mocks or fixtures for Kotlin & JVM. Triggers on: "test", "coverage", "mock", "fixture". Chains into: collect-coverage, run-static-analysis. Generates Kotlin & JVM tests with the AAA pattern and one DRY factory per entity: unit, component and integration coverage of the happy path and of every error branch, with deterministic data and no dead parameters.
argument-hint: "[target class or module]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin
  version: 1.1.0
---

# Test Generator (Kotlin & JVM)

> **Stack Profile:** Kotlin & JVM
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Produce tests that are deterministic, expressive and redundant-free. Arrange-Act-Assert,
one behaviour per test, one factory per entity, and explicit assertions on every branch.
Tests are production code: they follow the same naming and Clean Code rules.

## Territory
- `src/test/`, `app/src/test/` — unit and component tests.
- `src/androidTest/` — instrumented tests where the platform is required.
- `**/testing/**` — shared factories, fakes and fixtures.
- `build.gradle.kts` — test dependencies (JUnit 5, `kotlin.test`, MockK, flow-testing utilities).

## Testing Pyramid
- **Unit** — domain logic, reducers, mappers. Fast, no framework, no I/O.
- **Component** — Compose UI via `createComposeRule`; assert semantics, not pixels.
- **Integration** — ViewModel plus repository against fakes or a controlled harness.
- Cover the happy path and every error branch; a branch without a test is a defect.
- Prefer fakes over mocks; mock only true boundaries (network, clock, storage).

## DRY Test Factories (make*)
- One factory per entity, colocated with the tests that use it.
- Every parameter has a sensible default; tests override only what they assert on.
- No dead parameters, no `null` defaults standing in for "unused", no optional collections as `null`.
- Optional collections default to `emptyList()`/`emptyMap()` constants.

```kotlin
fun makeBooking(
    id: BookingId = BookingId("b-1"),
    status: BookingStatus = BookingStatus.Confirmed,
    notes: List<Note> = emptyList(),
): Booking = Booking(id = id, status = status, notes = notes)
```

## Repository Conformance Gate
- Run `oaef doctor` (native: `kotlinc -script tool/governance.main.kts doctor`).
- Run `oaef lint` and `oaef clean-code`; test code still obeys naming and swallowing rules.
- Record flaky or deferred tests in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every new behaviour and error branch has a deterministic passing test.
- Tests use `make*` factories; no duplicated literal fixtures.
- Assertions are explicit; no `assertNotNull` standing in for a real check.
- No `@Ignore` or skipped test without a documented reason.

## Anti-Patterns
- Over-parameterized factories with parameters no test ever sets.
- A single test asserting ten unrelated behaviours.
- Sleeping or polling instead of awaiting state with `runTest` and flow assertions.
- Mocking a class instead of implementing a small interface fake.
