---
name: screen-builder
description: >-
  Use when building or changing a screen, page, feature or user flow in Expo. Triggers on: "screen", "page",
  "feature", "flow", "view". Chains into: ui-preview, responsive-layout, test-generator. Constructs vertical feature
  slices in Expo inside the Clean Sizing bounds: state, presentation and routing arrive together, files stay under
  300 lines, and the surface is previewable in isolation before integration.
argument-hint: "[screen or flow name]"
license: MIT
metadata:
  framework: OAEF
  stack: expo
  version: 1.1.0
---

# Screen Builder (Expo)

> **Stack Profile:** Expo
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Build a vertical feature slice that runs end to end: route, screen, state, and data contract arrive together. Keep route files thin, keep business logic in `src/features/`, and keep every surface previewable before it is wired into the application.

## Territory
- `app/` - Expo Router file-based routes (`app/(group)/feature.tsx`, `app/feature/[id].tsx`).
- `src/features/<feature>/presentation/` - screens, hooks, view models.
- `src/features/<feature>/domain/` and `data/` - state contracts and their implementations.
- `src/components/`, `src/shared/` - reusable surfaces consumed by the screen.

## Construction Steps
1. Declare the route in `app/` with a typed screen component re-exported from `src/features/<feature>/presentation/`.
2. Define the state contract in `domain/`: a discriminated union covering loading, success, empty, and error.
3. Implement the hook that produces that state and owns side effects (fetch, storage, subscription).
4. Compose the view from `src/components/` primitives; route file stays under 50 lines.
5. Wire navigation with `expo-router` typed routes: `<Link href="/feature/[id]" />` and `router.push`.
6. Preview loading, success, empty, and error states in isolation (`ui-preview`) before integration.

## State & Routing Contract
- Navigation params are validated at the route boundary and narrowed into domain types.
- Screen options and headers are declared declaratively with `<Stack.Screen options={...} />`.
- Route groups `(group)` organize flows without adding URL segments; layouts own shared chrome.
- Async state is explicit: no bare `useState` driving a fetch; use the feature hook that exposes the union.
- Deep-linkable routes read only validated params; no hidden global state decides the screen.

## Repository Conformance Gate
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`) and clear every blocking finding.
- Run `oaef lint` and `oaef doctor`.
- Record unresolved flow decisions in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The flow navigates from entry to exit with typed routes and no `any` params.
- Route files stay under 50 lines and feature files under 300.
- Preview covers loading, success, empty, and error before the screen is integrated.

## Anti-Patterns
- Business logic or fetching inside an `app/` route file.
- A `useState` soup screen with nested ternaries for loading and error.
- Screens importing another feature's internals instead of shared components.
