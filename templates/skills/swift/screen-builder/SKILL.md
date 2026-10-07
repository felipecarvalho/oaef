---
name: screen-builder
description: >-
  Use when building or changing a screen, page, feature or user flow in Swift. Triggers on: "screen", "page", "feature", "flow", "view". Chains into: ui-preview, responsive-layout, test-generator. Constructs vertical feature slices in Swift inside the Clean Sizing bounds: state, presentation and routing arrive together, files stay under 300 lines, and the surface is previewable in isolation before integration.
argument-hint: "[screen or flow name]"
license: MIT
metadata:
  framework: OAEF
  stack: swift
  version: 1.1.0
---

# Screen Builder (Swift)

> **Stack Profile:** Swift
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Construct or refactor a vertical screen slice in Swift where state, presentation and routing ship together. The screen is previewable in isolation and stays within the Clean Sizing bounds before it is wired into the navigation graph.

## Territory
- `Sources/<Module>/Presentation/<Feature>/` — the screen and its view models.
- `Sources/<Module>/Domain/<Feature>/` — use cases and models the screen consumes.
- `Sources/<Module>/Data/<Feature>/` — repositories behind domain-owned protocols.
- `Sources/<Module>/App*/` — routing and composition root.
- `Tests/` — state and router tests for the slice.

## Construction Steps
1. Define the domain models and the use case the screen drives.
2. Define one `@Observable` state holder for the slice; no logic in the `View`.
3. Build the `View` from design-system tokens and shared components.
4. Wire routing through the composition root, not through a global resolver.
5. Extract sub-views above roughly 80 lines into their own files.
6. Prove loading, empty, success and error states with a preview and a test.

## State & Routing Contract
- One observable state holder per screen; the `View` reads and dispatches only.
- State transitions are explicit enum cases, not a web of booleans.
- Navigation is declarative and typed; no stringly-typed routes.
- The screen receives its dependencies through its initializer.
- Files stay under 300 lines; a screen that grows splits into sub-views.
- User-facing strings are localized or externalized, never inlined literals.

## Repository Conformance Gate
- `oaef doctor`
- `oaef lint`
- `oaef clean-code` (native: `swift tool/governance.swift clean-code`)
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The slice renders in an isolated preview without booting the app.
- Every state (loading, empty, success, error) is reachable and tested.
- No file exceeds 300 lines and no view mixes routing with business logic.
- `swift build` and `swift test` pass for the target.

## Anti-Patterns
- Business logic in a `body` or `onAppear` closure.
- Multiple `@State` booleans emulating one state machine.
- Screen resolving a service through `Resolver.resolve(` outside the composition root.
- A screen reaching directly into `URLSession.shared`.
- Helper sub-views left inline until the file crosses 300 lines.
