---
name: screen-builder
description: >-
  Use when building or changing a screen, page, feature or user flow in Python 3. Triggers on: "screen", "page", "feature", "flow", "view". Chains into: ui-preview, responsive-layout, test-generator. Constructs vertical feature slices in Python 3 inside the Clean Sizing bounds: state, presentation and routing arrive together, files stay under 300 lines, and the surface is previewable in isolation before integration.
argument-hint: "[screen or flow name]"
license: MIT
metadata:
  framework: OAEF
  stack: python
  version: 1.1.0
---

# Feature Slice Builder (Python 3)

> **Stack Profile:** Python 3
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Build a vertical feature slice end to end: routing, request/response mapping, domain logic
and data access delivered together as one reviewable unit. A "screen" in a headless stack
is a routed endpoint, a CLI command or a job entrypoint that renders a page of behavior.

## Territory
- `<package>/features/<feature>/presentation/` — routes, handlers, serializers.
- `<package>/features/<feature>/domain/` — use cases and business rules.
- `<package>/features/<feature>/data/` — repositories and external adapters.
- `main.py`, `src/<package>/di/` — composition root wiring the slice.
- `tests/features/<feature>/` — slice-scoped tests.

## Construction Steps
1. Declare the slice contract: the route or command, its inputs, outputs and error states.
2. Define domain types first (`dataclasses`, `enum`, `Protocol`) with no adapter imports.
3. Implement the use case as a plain callable receiving its dependencies by constructor
   or explicit parameter, never resolving a container.
4. Implement the data adapter behind the domain contract; keep the transport library
   confined to this module.
5. Map transport to domain in `presentation/`; return typed response models.
6. Wire the slice in the composition root only; register routes and dependencies there.
7. Add one slice-level test per state before moving on.
Keep each file under 300 lines and each function under 50 lines.

## State & Routing Contract
- State is explicit: a request-scoped context object or task object, never module globals.
- Routing is declarative and centralized per app (framework router or `argparse`
  subcommands); handlers stay thin and delegate to use cases.
- Error mapping is defined once: domain errors map to a status/serialization at the
  presentation boundary, not in every handler.
- Idempotency and validation happen at the boundary; the domain assumes valid input.
- No presentation import reaches into another feature's `data/` package.
- Async handlers await only awaited work; no blocking I/O inside an event loop.

## Repository Conformance Gate
- `oaef doctor` — structural conformance.
- `oaef lint` — governance findings.
- `oaef clean-code` (native: `python3 tool/governance.py clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Routes resolve to the new slice and every declared state has a test.
- The slice has no container resolution outside the composition root.
- `mypy .` and `ruff check .` pass for the slice.

## Anti-Patterns
- A handler containing business rules instead of delegating to a use case.
- Slice state stored in module-level mutable variables.
- Reaching into another feature's data package instead of its domain contract.
- Registering routes from inside the feature module at import time.
- A handler that catches all exceptions and returns a bare success response.
