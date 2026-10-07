---
name: test-generator
description: >-
  Use when writing or expanding automated tests, mocks or fixtures for Expo. Triggers on: "test", "coverage",
  "mock", "fixture". Chains into: collect-coverage, run-static-analysis. Generates Expo tests with the AAA pattern
  and one DRY factory per entity: unit, component and integration coverage of the happy path and of every error
  branch, with deterministic data and no dead parameters.
argument-hint: "[target class or module]"
license: MIT
metadata:
  framework: OAEF
  stack: expo
  version: 1.1.0
---

# Test Generator (Expo)

> **Stack Profile:** Expo
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Generate tests that pin behavior and contracts. Every module gets unit coverage, every component gets a render test, every flow gets an integration test. Arrange-Act-Assert, one DRY factory per entity, and deterministic data throughout.

## Territory
- `__tests__/` - component and integration suites.
- `test/` - unit suites for hooks, domain, and data.
- `src/features/<feature>/` - the code under test.
- Jest configuration via the `jest-expo` preset.

## Testing Pyramid
- **Unit** - pure domain functions, validators, and reducers; no rendering.
- **Component** - render a surface with `@testing-library/react-native`; assert visible output and accessibility.
- **Integration** - drive a feature hook or flow with mocked dependencies and assert the state union transitions.
- Use `jest.fn()` doubles for collaborators; fake the network and storage at the boundary.
- Cover the happy path and every error branch; a branch with no test is uncovered by definition.

## DRY Test Factories (make*)
Each suite declares one local factory per entity, with only the parameters that actually vary:

```ts
function makeSession(overrides: Partial<Session> = {}): Session {
  return { id: 'session-1', displayName: 'Ada', status: 'active', ...overrides };
}
```

- Name the factory `make<Entity>` (`makeSession`, `makeBooking`).
- Delete dead parameters (always `null`, always default, never read).
- An optional collection parameter defaults to a constant empty collection, never `undefined`.
- Fixtures are deterministic: no ambient clock, no random values, no network.
- Reset mocks between tests with `beforeEach(() => jest.clearAllMocks())`.

## Repository Conformance Gate
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`) and fix every blocking finding.
- Run `oaef lint` and `oaef doctor`.
- Record any deliberately skipped case, with the reason, in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `npx jest` passes with the new suites green.
- Happy path and every error branch have an explicit assertion.
- No literal fixture duplication remains where a `make<Entity>` factory applies.

## Anti-Patterns
- Factories with dead parameters and always-default arguments.
- Tests depending on the clock, randomness, or the network.
- Asserting implementation details instead of observable behavior.
