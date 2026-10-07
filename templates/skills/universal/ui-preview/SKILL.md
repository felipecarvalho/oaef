---
name: ui-preview
description: >-
  Use when a component or screen must be inspected in isolation before it is wired into the application in Universal / Polyglot. Triggers on: "preview", "storybook", "isolated render". Chains into: test-generator, run-static-analysis. Provides isolated preview harnesses for Universal / Polyglot: loading, success, empty and error states are rendered without booting the full runtime, so layout, tokens and typography are validated before integration.
argument-hint: "[component or screen name]"
license: MIT
metadata:
  framework: OAEF
  stack: universal
  version: 1.1.0
---

# UI Preview (Universal / Polyglot)

> **Stack Profile:** Universal / Polyglot
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Render a surface in isolation, with deterministic data, so layout, tokens and typography are proven before the surface is wired into the running application.

## Territory
- Preview harnesses co-located with components or under a dedicated preview directory.
- Framework equivalents: Storybook stories (`.tsx`/`.jsx`), Compose `@Preview` (`.kt`), SwiftUI `#Preview` (`.swift`), Flutter `Widgetbook`/widget-preview (`.dart`).
- Headless equivalents render a payload fixture through its serializer and assert the shape without a live dependency.

## Preview Harness
- One harness per meaningful state: loading, success, empty, error.
- Fixtures are constants or factories, never calls to a live service.
- The harness renders without the application entrypoint, the router and the global container.
- The harness is committed next to the surface; a preview that lives only on a branch is not a preview.
- A headless counterpart renders the serialized fixture directly and asserts its shape, so no surface depends on a live transport.
- Each harness names the state it renders (`loading`, `success`, `empty`, `error`) and references the token set it exercises.
- Snapshots are optional; a deterministic fixture plus an assertion on structure is preferred over a brittle pixel diff.
- Fixtures are typed with the same contract the real surface consumes, so a schema change breaks the harness loudly.

## Repository Conformance Gate
- `oaef doctor` and `oaef lint` clean for the touched repository.
- `oaef clean-code` (native: `bash tool/governance.sh clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every declared state renders in the harness without network access.
- Layout holds at the smallest and largest declared breakpoints.
- The harness is deterministic across two consecutive runs.
- The harness is referenced by the test suite that covers the same states.

## Anti-Patterns
- A preview that boots the whole application to render one widget.
- Fixtures fetched from a live endpoint.
- Previewing only the happy path.
- A harness that reaches network or filesystem state to build its fixture.
- A preview directory excluded from static analysis or the build.
- A harness that mutates a global singleton while rendering.
- A preview that duplicates the real fixture instead of importing it from the suite.
