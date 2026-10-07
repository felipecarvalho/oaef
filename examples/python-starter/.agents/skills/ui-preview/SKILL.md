---
name: ui-preview
description: >-
  Use when a component or screen must be inspected in isolation before it is wired into the application in Python 3. Triggers on: "preview", "storybook", "isolated render". Chains into: test-generator, run-static-analysis. Provides isolated preview harnesses for Python 3: loading, success, empty and error states are rendered without booting the full runtime, so layout, tokens and typography are validated before integration.
argument-hint: "[component or screen name]"
license: MIT
metadata:
  framework: OAEF
  stack: python
  version: 1.1.0
---

# Isolated Preview Harness (Python 3)

> **Stack Profile:** Python 3
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Inspect a unit without booting the whole application. For a headless stack, a preview
renders the observable output — serialized payload, response object, CLI output — across
the four canonical states, using fakes instead of live dependencies.

## Territory
- `tests/preview/` or `tests/<feature>/preview_*.py` — preview modules.
- `<package>/features/<feature>/presentation/` — the surface being previewed.
- `src/<package>/shared/` — shared serializers and fakes used by previews.
- No preview code in production directories; previews never ship.

## Preview Harness
- One preview module per surface, invoked directly with `python -m <module>` or a pytest
  case tagged `preview`.
- Provide deterministic fake adapters and fixtures; the harness must not open sockets,
  touch the filesystem outside a temp dir, or read real credentials.
- Render the four canonical states for each surface:
  - loading — the pending state before the dependency resolves.
  - success — a populated, representative payload.
  - empty — a valid but empty result, exercising the empty-collection default.
  - error — a typed domain error and the resulting error representation.
- Print the serialized representation through the logging interface or return it for
  assertion; never leave `print` in production paths.
- Compare against a stored snapshot only when the snapshot is checked in and reviewed.
- Keep the harness fast: no network, no database, no sleep-based timing.

## Repository Conformance Gate
- `oaef doctor` — structural conformance.
- `oaef lint` — governance findings.
- `oaef clean-code` (native: `python3 tool/governance.py clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Each previewed surface exercises loading, success, empty and error deterministically.
- The harness runs standalone without the full application or external services.
- No preview artifact leaks into a production directory.

## Anti-Patterns
- A preview that calls the real network or the real database.
- Rendering only the success state and calling the surface "previewed".
- Leaving a `print`-based debug path in production code to support the preview.
- Snapshot files committed without review, masking a regression.
- A preview that boots the whole app or a container just to reach one function.
