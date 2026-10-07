---
name: test-generator
description: >-
  Use when writing or expanding automated tests, mocks or fixtures for React Native. Triggers on: "test", "coverage", "mock", "fixture". Chains into: collect-coverage, run-static-analysis. Generates React Native tests with the AAA pattern and one DRY factory per entity: unit, component and integration coverage of the happy path and of every error branch, with deterministic data and no dead parameters.
argument-hint: "[target class or module]"
license: MIT
metadata:
  framework: OAEF
  stack: react-native
  version: 1.1.0
---

# Test Generator (React Native)

> **Stack Profile:** React Native
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Produce deterministic, meaningful tests for the touched slice. Cover the happy path and every error branch; assert observable behaviour, not implementation detail.

## Territory
- `__tests__/**` — suite root.
- `src/**/*.test.tsx`, `src/**/*.test.ts` — colocated tests.
- `src/features/<feature>/**` — unit, component and integration targets.
- `jest.config.*`, `jest.setup.*` — harness configuration.

## Testing Pyramid
- **Unit** — pure functions, mappers and hooks in isolation; fast and numerous.
- **Component** — render with `@testing-library/react-native`; assert via queries and accessibility roles, not snapshots alone.
- **Integration** — a screen or flow wired to fake ports; verify state transitions `idle -> loading -> success|error`.
- Prefer fakes implementing the port over deep mock chains.
- Use `jest.useFakeTimers()` for time-dependent behaviour and always restore in `afterEach`.
- One assertion focus per test; name tests by behaviour (`renders empty state when no items`).

## DRY Test Factories (make*)
- One factory per entity, named `make<Entity>`, with a partial-override parameter:
  `const makeSession = (overrides: Partial<Session> = {}): Session => ({ id: 'session-1', startedAt: 0, ...overrides });`
- Only parameters that actually vary across tests; no dead parameters and no `null` placeholders.
- Optional collection fields default to a frozen constant empty array inside the factory.
- Factories live beside the suite or in `__tests__/factories/`; the same factory is reused, never duplicated.
- HTTP and platform doubles are factories too (`makeHttpClientMock`, `makeMockNavigation`), not hand-rolled objects per test.

## Repository Conformance Gate
- Run `oaef doctor` (native: `node tool/governance.mjs doctor`).
- Run `oaef lint` (native: `npx eslint .`).
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every new branch, including error paths, has at least one test.
- Entities are built through a single `make<Entity>` factory.
- Tests pass deterministically with fake timers and no real network.

## Anti-Patterns
- Snapshot-only tests that assert nothing meaningful.
- Over-parameterised factories with unused flags.
- `jest.mock` chains that re-implement the module under test.
- Tests depending on wall-clock time or a live endpoint.
