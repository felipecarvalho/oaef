---
name: component-author
description: >-
  Use when authoring or extracting a reusable component, widget, button, card or modal in Python 3. Triggers on: "component", "widget", "button", "card", "modal". Chains into: ui-preview, responsive-layout, test-generator. Authors reusable Python 3 surfaces from design-system tokens: one responsibility per component, tokens instead of literals, and a contract that serves every consumer without a bespoke variant.
argument-hint: "[component name]"
license: MIT
metadata:
  framework: OAEF
  stack: python
  version: 1.1.0
---

# Component Author (Python 3)

> **Stack Profile:** Python 3
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Author reusable units — domain services, adapters, DTOs, CLI subcommands, serializers — with
a single responsibility and a contract that every consumer can use unchanged. In a headless
stack a "component" is a composable callable or class, not a rendered widget.

## Territory
- `<package>/features/<feature>/domain/` — reusable domain services and value objects.
- `src/<package>/shared/` — cross-feature utilities and contracts.
- `<package>/features/<feature>/data/` — reusable adapters and mappers.
- `tests/shared/` — component-level tests.

## Component Contract
- One class or callable, one responsibility, expressed in its name.
- Depend on abstractions: accept a `Protocol` or callable, never a concrete client.
- Inputs and outputs are typed with `dataclasses`, `NamedTuple` or `TypedDict`.
- No container or global resolution inside the component; dependencies arrive by argument.
- Errors are typed domain errors; never return `None` to signal failure.
- No side effects at import time; construction is cheap and side-effect free.
- The contract serves every consumer as-is; a per-consumer variant means the boundary is wrong.
- Document the contract once in the docstring; keep examples to a short usage line.

## Token Discipline
- Shared constants live in a single module (`shared/config.py` or a `Constants` enum);
  magic strings, color codes, timeouts and limits are tokens, not literals.
- Read environment-driven values through one settings object, never `os.environ` scattered.
- Reuse existing tokens before minting one; duplicate token sets are the same anti-pattern
  as duplicated components.
- Defaults are declared once at the contract, not repeated at each call site.
- Numeric limits (page size, retry count, timeout) are named constants with units.

## Repository Conformance Gate
- `oaef doctor` — structural conformance.
- `oaef lint` — governance findings.
- `oaef clean-code` (native: `python3 tool/governance.py clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Each component has exactly one responsibility and a fully typed contract.
- No literal token duplicates an existing constant.
- `mypy .` and `ruff check .` pass with zero new suppressions.

## Anti-Patterns
- A helper class with a single `run()` method that only forwards to another function.
- Hardcoding a timeout or limit instead of referencing the shared constant.
- A component that resolves the service container to fetch its own dependencies.
- Adding a boolean parameter to serve one caller instead of extending the contract cleanly.
- Returning `None` to signal a failure the caller must interpret.
