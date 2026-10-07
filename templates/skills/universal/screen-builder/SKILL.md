---
name: screen-builder
description: >-
  Use when building or changing a screen, page, feature or user flow in Universal / Polyglot. Triggers on: "screen", "page", "feature", "flow", "view". Chains into: ui-preview, responsive-layout, test-generator. Constructs vertical feature slices in Universal / Polyglot inside the Clean Sizing bounds: state, presentation and routing arrive together, files stay under 300 lines, and the surface is previewable in isolation before integration.
argument-hint: "[screen or flow name]"
license: MIT
metadata:
  framework: OAEF
  stack: universal
  version: 1.1.0
---

# Screen Builder (Universal / Polyglot)

> **Stack Profile:** Universal / Polyglot
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Ship a complete vertical slice for a user-facing surface in whichever embedded UI language this repository uses, without leaving the Clean Sizing bounds or wiring the surface into the runtime too early.

## Territory
- Interactive feature directories: `src/features/<feature>/**`, `app/**`, `lib/features/<feature>/**`, `Sources/<Module>/Presentation/**`.
- Routing and navigation definitions for the surface.
- This skill applies to UI-bearing files (`.tsx`, `.jsx`, `.kt`, `.dart`, `.swift`); for headless endpoints use `architecture-audit` and the payload guidance in `responsive-layout`.

## Construction Steps
1. Confirm the dispatch rows in `AGENTS.md` §3.3 and read the applicable interface first.
2. Create the slice directories alongside its siblings (presentation, domain, data) when the repository uses that layout.
3. Build state, presentation and routing together; a slice is never half-wired.
4. Keep every file under 300 lines and every method under 50 lines.
5. Render the slice through `ui-preview` before touching the application entrypoint.
6. Add the routing registration last, once the surface renders in isolation across every state.
7. Cover the slice with a factory-driven test before opening the pull request.

## State & Routing Contract
- State has one owner; derived values are computed, not stored twice.
- Routing parameters are typed and validated at the boundary.
- Loading, empty, success and error states are all implemented; a partial state machine is not shippable.
- The screen receives its dependencies through the constructor or the framework's injection point, never through a global lookup.

## Repository Conformance Gate
- `oaef doctor` and `oaef lint` clean for the touched repository.
- `oaef clean-code` (native: `bash tool/governance.sh clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The slice compiles and renders in isolation across its declared states.
- Routing is wired and the back/forward path is proven.
- No file exceeds the Clean Sizing bounds.

## Anti-Patterns
- Building presentation before the domain contract exists.
- A screen that reaches into a global container to resolve its dependencies.
- Shipping only the success state and leaving loading or error unhandled.
