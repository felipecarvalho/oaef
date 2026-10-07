---
name: screen-builder
description: >-
  Use when building or changing a screen, page, feature or user flow in React Native. Triggers on: "screen", "page", "feature", "flow", "view". Chains into: ui-preview, responsive-layout, test-generator. Constructs vertical feature slices in React Native inside the Clean Sizing bounds: state, presentation and routing arrive together, files stay under 300 lines, and the surface is previewable in isolation before integration.
argument-hint: "[screen or flow name]"
license: MIT
metadata:
  framework: OAEF
  stack: react-native
  version: 1.1.0
---

# Screen Builder (React Native)

> **Stack Profile:** React Native
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Deliver a complete vertical slice for one user flow: state, presentation and navigation arrive together, wired to domain ports but independent of the concrete data implementation. A screen owns rendering and orchestration only.

## Territory
- `src/features/<feature>/presentation/screens/**` — screen components.
- `src/features/<feature>/presentation/hooks/**` — view models and state hooks.
- `src/features/<feature>/presentation/navigation/**` — route registration for the flow.
- `app/**` — application shell and route mounting.
- `__tests__/`, `src/**/*.test.tsx` — screen-level tests.

## Construction Steps
1. Climb the Ponytail Ladder: reuse an existing screen shell or hook before authoring one.
2. Define the screen's view model as a hook returning an immutable state object plus named actions.
3. Derive all display data from state; no computation inside JSX beyond trivial ternaries.
4. Compose the layout from design-system components and tokens.
5. Register the route in the feature navigation module; keep the shell route file thin.
6. Preview loading, success, empty and error states before wiring real navigation.
7. Add a test for the happy path and every error branch.

## State & Routing Contract
- The hook is the single source of truth; the screen component reads it and renders.
- Expose an explicit status union: `idle | loading | success | empty | error` — never infer loading from `data == null`.
- Actions are named verbs (`onSubmit`, `onRetry`), stable via `useCallback`, and never mutate props.
- Navigation parameters are typed; the screen declares its route and required params.
- Screens receive their dependencies through props or context; they never resolve a container (`CC-07`) or construct a client (`CC-10`).
- Keep the screen under 300 lines and each handler under 50 lines; extract subcomponents when exceeded.

## Repository Conformance Gate
- Run `oaef doctor` (native: `node tool/governance.mjs doctor`).
- Run `oaef lint` (native: `npx eslint .`).
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The flow renders end to end from `idle` through `success` and `error`.
- The screen is previewable in isolation and covered by at least one happy-path and one error test.
- No file in the slice exceeds 300 lines.

## Anti-Patterns
- Business logic embedded in the screen component.
- A screen that fetches directly instead of calling a port.
- Unnamed inline styles duplicated across subcomponents.
- Navigation parameters typed as `any`.
