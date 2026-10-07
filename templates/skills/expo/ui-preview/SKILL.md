---
name: ui-preview
description: >-
  Use when a component or screen must be inspected in isolation before it is wired into the application in Expo.
  Triggers on: "preview", "storybook", "isolated render". Chains into: test-generator, run-static-analysis.
  Provides isolated preview harnesses for Expo: loading, success, empty and error states are rendered without
  booting the full runtime, so layout, tokens and typography are validated before integration.
argument-hint: "[component or screen name]"
license: MIT
metadata:
  framework: OAEF
  stack: expo
  version: 1.1.0
---

# UI Preview (Expo)

> **Stack Profile:** Expo
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Inspect every surface in isolation before it is wired into navigation. A preview renders the component with fixed props for loading, success, empty, and error, so layout, tokens, and typography are validated without booting the full app runtime.

## Territory
- `src/components/` and `src/features/<feature>/presentation/` - previewable surfaces.
- `app/` - a development-only preview route when a live harness is required.
- `__tests__/` - render smoke tests that mirror the preview states.

## Preview Harness
- Colocate a preview module next to the component, exporting one named state per scenario.
- Each preview supplies deterministic fixture data; no network, no ambient clock, no random values.
- Render all four states side by side so regressions are visible in one pass.
- Use a development-only route (`app/dev/`) guarded from production builds for interactive checks.
- Preview the surface at compact and expanded widths to confirm adaptive behavior.
- Wrap previews in the same theme provider the app uses so tokens resolve identically.

```tsx
export const CardStates = () => (
  <>
    <Card title="Loaded" items={makeItems(3)} />
    <Card title="Empty" items={[]} />
    <Card title="Error" error="Network unavailable" />
  </>
);
```

## Repository Conformance Gate
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`) and fix every blocking finding.
- Run `oaef lint` and `oaef doctor`.
- Record preview gaps for states that cannot yet be rendered in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every declared state renders without runtime errors in isolation.
- Fixture data is deterministic and typed.
- Preview covers compact and expanded widths and the theme resolves without app boot.

## Anti-Patterns
- Previews that call the real network or depend on global app state.
- Shipping a development preview route into production builds.
- Rendering only the happy path and deferring empty and error states until integration.
