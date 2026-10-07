---
name: responsive-layout
description: >-
  Use when a surface must adapt to another screen size, form factor or payload shape in Expo. Triggers on:
  "responsive", "adaptive", "breakpoint", "tablet", "foldable", "viewport". Chains into: ui-preview, test-generator.
  Owns adaptive design in Expo: breakpoints, safe areas, dynamic type and foldables for interactive surfaces, and
  payload shaping, pagination, content negotiation and streaming backpressure for headless ones.
argument-hint: "[breakpoint or surface name]"
license: MIT
metadata:
  framework: OAEF
  stack: expo
  version: 1.1.0
---

# Responsive Layout (Expo)

> **Stack Profile:** Expo
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Make every surface adapt to the size it is actually given. Expo targets phones, tablets, foldables, and the web, so a single fixed layout is a defect. Layout reacts to the measured viewport, not to a device name, and safe areas and dynamic type are honored by default.

## Territory
- `app/` - Expo Router layouts and route groups that reorganize across breakpoints.
- `src/features/<feature>/presentation/` - screens and hooks consuming adaptive signals.
- `src/components/`, `src/shared/` - surfaces whose props carry size and orientation.

## Adaptive Surface Design
- Read the viewport with `useWindowDimensions()` rather than caching `Dimensions.get()` at module load.
- React to the measured container, not the device: prefer layout-driven decisions over brand checks.
- Respect safe areas with `react-native-safe-area-context` insets on every edge-cut surface.
- Support dynamic type: never fix `fontSize` without `allowFontScaling`; verify at large text scale.
- Form factors (`expo-device`) inform defaults, never hard branches that break a resize.
- Foldables and split view: treat the hinge and the resize as a viewport change, not an edge case.

## Breakpoint Strategy
- Define a small, named breakpoint set once in `src/shared/` and import it everywhere.

```ts
const BREAKPOINTS = { compact: 0, medium: 600, expanded: 900 } as const;
```

- Map the width to a breakpoint category, then select layout via a lookup, not nested ternaries.
- On compact widths, stack and virtualize with `FlatList`/`FlashList`; on expanded widths, use a grid or a side-by-side split.
- Expo Router route groups reorganize navigation per category (tabs on compact, sidebar layout on expanded).
- Validate each breakpoint by resizing the preview (`ui-preview`), not by trusting device names.

## Repository Conformance Gate
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`) and fix every blocking finding.
- Run `oaef lint` and `oaef doctor`.
- Record any deferred breakpoint or form factor in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The surface adapts across the declared breakpoints without overflow or clipping.
- Safe areas and dynamic type are respected on every edge and at large text scales.
- A test asserts the layout category resolved for at least compact and expanded widths.

## Anti-Patterns
- Hard-coding pixel dimensions from a single device.
- Branching on device brand instead of measured width.
- Ignoring safe areas on notched or edge-to-edge surfaces.
