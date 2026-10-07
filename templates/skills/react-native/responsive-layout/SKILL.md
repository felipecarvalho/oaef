---
name: responsive-layout
description: >-
  Use when a surface must adapt to another screen size, form factor or payload shape in React Native. Triggers on: "responsive", "adaptive", "breakpoint", "tablet", "foldable", "viewport". Chains into: ui-preview, test-generator. Owns adaptive design in React Native: breakpoints, safe areas, dynamic type and foldables for interactive surfaces, and payload shaping, pagination, content negotiation and streaming backpressure for headless ones.
argument-hint: "[breakpoint or surface name]"
license: MIT
metadata:
  framework: OAEF
  stack: react-native
  version: 1.1.0
---

# Responsive Layout (React Native)

> **Stack Profile:** React Native
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Make every interactive surface adapt to phone, tablet and foldable form factors without a forked component. Adaptation is driven by measured viewport and platform facts, never by hardcoded device names.

## Territory
- `src/components/**`, `src/shared/ui/**` — responsive primitives.
- `src/features/<feature>/presentation/screens/**` — adaptive screen layouts.
- `app/**` — router groups and root layout.
- `__tests__/` — layout tests across breakpoints.

## Adaptive Surface Design
- Read the viewport with `useWindowDimensions()` (re-renders on rotation and resize) rather than `Dimensions.get()` at module scope.
- Respect safe areas with `useSafeAreaInsets` from `react-native-safe-area-context` when present; fall back to platform pads.
- Honour accessibility scaling: allow font scaling, clamp with `maxFontSizeMultiplier` only where layout demands, and never disable it globally.
- Use `PixelRatio` for hairline borders and pixel-crisp assets.
- Branch platform differences with `Platform.select`, not with device-name checks.
- Foldables: treat a hinge or posture change as a breakpoint, not a separate feature.

## Breakpoint Strategy
- Define a small named set (for example `compact < 600`, `medium 600–1024`, `expanded >= 1024`) in one shared module; every component imports it.
- Derive a boolean or size class from width and pass it down; never scatter raw width comparisons.
- Layout switches, not content forks: the same tree reflows via flex direction, column count and spacing tokens.
- Tablet uses the extra width for master-detail or multi-column, not for larger padding alone.
- Keep list virtualization intact across breakpoints (`FlatList` `numColumns` keyed to the breakpoint).
- Validate each breakpoint in the preview harness before integration.

## Repository Conformance Gate
- Run `oaef doctor` (native: `node tool/governance.mjs doctor`).
- Run `oaef lint` (native: `npx eslint .`).
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The surface renders correctly at compact, medium and expanded widths.
- Breakpoints come from the shared module; no device-name branching remains.
- Safe areas and font scaling are honoured on every form factor.

## Anti-Patterns
- `Dimensions.get('window')` captured once at module scope.
- `Platform.OS === 'ios' ? pad : pad * 1.5` scattered across screens.
- A second component authored only for tablets.
- Disabling font scaling to keep a layout stable.
