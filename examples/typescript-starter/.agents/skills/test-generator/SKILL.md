---
name: test-generator
description: >-
  Use when writing or expanding automated tests, mocks or fixtures for TypeScript & Web. Triggers on: "test", "coverage", "mock", "fixture". Chains into: collect-coverage, run-static-analysis. Generates TypeScript & Web tests with the AAA pattern and one DRY factory per entity: unit, component and integration coverage of the happy path and of every error branch, with deterministic data and no dead parameters.
argument-hint: "[target class or module]"
license: MIT
metadata:
  framework: OAEF
  stack: typescript-web
  version: 1.1.0
---

# Test Generator (TypeScript & Web)

> **Stack Profile:** TypeScript & Web
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission

Produce deterministic, behaviour-focused tests with Vitest or Jest, one DRY factory per
entity, and full branch coverage. Every error branch has a test; no test asserts the
implementation instead of the behaviour.

## Territory

- `src/**/*.spec.ts`, `src/**/*.test.ts(x)` — unit and component tests beside the source.
- `test/**` — integration and cross-slice tests.
- `src/**/__mocks__/**` — shared manual mocks.
- Coverage artifact `coverage/lcov.info` consumed by `collect-coverage`.

## Testing Pyramid

- **Unit** (fastest, most numerous) — pure functions, domain logic, reducers, selectors,
  data mappers. No DOM, no network.
- **Component** — render one surface with `jsdom` and testing-library; assert user-visible
  behaviour, query by role and label, never by implementation class.
- **Integration** — the slice end to end against a fake transport; assert the observable
  flow, not internal calls.
- **End-to-end** — reserved for critical journeys only; kept thin.

Rules: AAA structure (Arrange, Act, Assert) with a blank line between phases; one
behaviour per test; descriptive `it("…")` naming; deterministic clock and random source.
Mock only at process boundaries (network, storage, time); do not mock your own domain.

## DRY Test Factories (make*)

- One factory per entity, named `make<Entity>`, defined locally in the suite that uses it:

  ```ts
  function makeSession(overrides: Partial<Session> = {}): Session {
    return { id: "session-1", isActive: true, displayName: "Ada", ...overrides };
  }
  ```

- Only parameters that actually vary across tests become factory parameters; a parameter
  passed the same value everywhere is a dead parameter — remove it.
- Never pass `null` for a field that the domain guarantees; encode the real default.
- Optional collections default to a frozen empty collection (`Object.freeze([])`).
- Overrides merge last, so each test declares only what matters to it.
- A factory that grows a bespoke parameter for one caller is a design smell: split it or
  reuse the domain constructor.

## Repository Conformance Gate

- Run `oaef doctor`, `oaef lint`, `oaef clean-code` (native:
  `node tool/governance.mjs doctor|lint|clean-code`).
- Run `npm test -- --coverage` and `npx tsc --noEmit`.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria

- Every touched behaviour and every error branch has a test.
- One `make<Entity>` factory per entity, with zero dead parameters.
- Tests are deterministic and pass in isolation and in the full suite.

## Anti-Patterns

- Asserting on mocks (`expect(spy).toHaveBeenCalledTimes(1)`) instead of behaviour.
- A factory with a parameter every caller sets to the same value.
- Snapshots that pin unrelated markup and break on any styling change.
- Mocking the module under test, so the test proves nothing.
