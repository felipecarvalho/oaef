---
name: test-generator
description: >-
  Use when writing or expanding automated tests, mocks or fixtures for Python 3. Triggers on: "test", "coverage", "mock", "fixture". Chains into: collect-coverage, run-static-analysis. Generates Python 3 tests with the AAA pattern and one DRY factory per entity: unit, component and integration coverage of the happy path and of every error branch, with deterministic data and no dead parameters.
argument-hint: "[target class or module]"
license: MIT
metadata:
  framework: OAEF
  stack: python
  version: 1.1.0
---

# Test Generator (Python 3)

> **Stack Profile:** Python 3
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Produce deterministic, hermetic tests that cover the happy path and every error branch,
using one factory per entity and fakes instead of live dependencies.

## Territory
- `tests/` — the test tree root.
- `tests/features/<feature>/` — slice-scoped test modules.
- `tests/conftest.py` — shared fixtures and factory fixtures.
- Test files are named `test_<unit>.py`; the governed native runner is `pytest --cov`.

## Testing Pyramid
- Unit — pure domain logic: fast, no I/O, exercised with plain values and fakes.
- Component — one adapter or serializer against an in-memory or recorded double.
- Integration — the slice wired through the composition root against a sandbox,
  covering the contract between layers.
- Every branch and every exception path gets at least one test; the `else` and the
  error return are not optional.
- Assertions target observable behavior, not private internals.

## DRY Test Factories (make*)
- One factory per entity, named `make_<entity>` or `make<Entity>`, returning a valid
  instance with sensible defaults.
- Parameters expose only the fields a test actually varies; every parameter must be
  used by at least one test.
- Never add a dead parameter or a parameter permanently `None`; delete it.
- Collection parameters default to a constant empty collection, never `None`.
- Prefer keyword-only arguments after the first positional so call sites stay readable.
- The factory lives once per entity; duplicating a builder across test modules is a defect.
- Use `@pytest.fixture` to expose factories as fixtures when both arrange and act are
  concise.

```python
def make_booking(*, booking_id: str = "booking-1", items: Sequence[Item] = ()) -> Booking:
    return Booking(booking_id=booking_id, items=tuple(items))
```

## Repository Conformance Gate
- `oaef doctor` — structural conformance.
- `oaef lint` — governance findings.
- `oaef clean-code` (native: `python3 tool/governance.py clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Happy path and every error branch are covered by at least one test.
- Every entity has exactly one factory with no dead parameters.
- `pytest` passes with no real network, filesystem or clock dependency.

## Anti-Patterns
- Tests asserting private attributes instead of the public contract.
- A factory with a parameter no test ever overrides.
- Sleeping for timing instead of injecting a clock or controlling time.
- A shared mutable fixture leaking state across tests.
- Mocking the unit under test instead of its dependencies.
