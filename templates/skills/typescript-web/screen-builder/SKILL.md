---
name: screen-builder
description: >-
  Use when building or changing a screen, page, feature or user flow in TypeScript & Web. Triggers on: "screen", "page", "feature", "flow", "view". Chains into: ui-preview, responsive-layout, test-generator. Constructs vertical feature slices in TypeScript & Web inside the Clean Sizing bounds: state, presentation and routing arrive together, files stay under 300 lines, and the surface is previewable in isolation before integration.
argument-hint: "[screen or flow name]"
license: MIT
metadata:
  framework: OAEF
  stack: typescript-web
  version: 1.1.0
---

# Screen Builder (TypeScript & Web)

> **Stack Profile:** TypeScript & Web
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission

Construct a vertical feature slice in one pass: domain types, data access, presentation
and routing land together under `src/features/<feature>/`. The screen ships previewable
and testable without booting the entire application.

## Territory

- `src/features/<feature>/presentation/` — the screen, its view states and route.
- `src/features/<feature>/domain/` — entities and use cases of the flow.
- `src/features/<feature>/data/` — repositories and payload parsing.
- `src/components/`, `src/shared/` — reused surfaces, not feature-local code.
- `app/` or `src/routes/` — routing registration points.

## Construction Steps

1. Name the slice and create the three layer directories.
2. Define the domain types first; absence is explicit (`nullable-types`).
3. Implement data access behind a consumer-owned interface; parse at the boundary.
4. Build the presentation with a single source of truth for state; derive the rest.
5. Wire routing as the last step, injecting dependencies at the composition entry.
6. Keep every file under 300 lines and every function under 50; extract sub-surfaces.
7. Preview each state with `ui-preview` before removing the harness.
8. Add the slice test with `test-generator`; verify branches with `collect-coverage`.

## State & Routing Contract

- State lives in one place: a store slice, a reducer or a hook-owned state machine.
  Never mirror the same value in two stores.
- Derived values are computed, not stored: use `useMemo`, a selector or a pure function
  instead of an `useEffect` that writes a second state variable.
- Loading, empty, error and success are explicit, exhaustive variants, not boolean flags:
  `type Status = { kind: "loading" } | { kind: "empty" } | { kind: "error"; cause: Error } | { kind: "ready"; data: Data };`
- The route receives an id or param and resolves its slice; it must not import sibling
  features.
- Side effects are triggered from the store or the data layer, not scattered across
  render bodies.

## Repository Conformance Gate

- Run `oaef doctor`, `oaef lint`, `oaef clean-code` (native:
  `node tool/governance.mjs doctor|lint|clean-code`).
- Run `npx tsc --noEmit` and `npx eslint src`.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria

- The slice exists under `src/features/<feature>/` with domain, data and presentation.
- Every file is under the Clean Sizing bound; the slice has a preview and a test.
- The route resolves the slice without importing a sibling feature.

## Anti-Patterns

- A screen file that fetches, transforms and renders in one 400-line component.
- Boolean flag soup (`isLoading`, `isEmpty`, `hasError`) instead of an exhaustive status.
- Duplicating feature logic into `src/shared/` on the first use.
- Registering a route that reaches directly into another feature's data layer.
