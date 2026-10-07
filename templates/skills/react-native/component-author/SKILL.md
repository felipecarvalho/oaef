---
name: component-author
description: >-
  Use when authoring or extracting a reusable component, widget, button, card or modal in React Native. Triggers on: "component", "widget", "button", "card", "modal". Chains into: ui-preview, responsive-layout, test-generator. Authors reusable React Native surfaces from design-system tokens: one responsibility per component, tokens instead of literals, and a contract that serves every consumer without a bespoke variant.
argument-hint: "[component name]"
license: MIT
metadata:
  framework: OAEF
  stack: react-native
  version: 1.1.0
---

# Component Author (React Native)

> **Stack Profile:** React Native
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Produce reusable surfaces that any feature can consume unchanged. A component hides one decision and exposes a typed, token-driven contract; it never reaches into a feature or a network client.

## Territory
- `src/components/**` — design-system surfaces.
- `src/shared/ui/**` — cross-cutting presentational primitives.
- `src/features/<feature>/presentation/components/**` — feature-scoped components.
- `__tests__/` — component tests and previews.

## Component Contract
- Props are a single typed interface; no untyped index or `any` in the public surface.
- Optional collections default to a frozen constant empty array (see `nullable-types`).
- Variant is a discriminated union (`variant: 'primary' | 'secondary' | 'ghost'`), not a set of booleans.
- Every callback is optional and named as an event (`onPress`, `onChange`).
- Forward `style` and platform props so consumers can extend without a bespoke variant.
- Accessibility: label every interactive element, expose `accessibilityRole` and `accessibilityState`, respect reduce-motion.
- One responsibility per component; extract subcomponents past 300 lines.

## Token Discipline
- Colours, spacing, radii, typography and elevation come from design-system tokens; never a literal hex, magic number or font string.
- Build styles with `StyleSheet.create` at module scope; never an inline style object inside a render loop.
- Variants map to token sets; do not fork a component for a spacing difference.
- Prefer the platform primitive (`Pressable`, `Text`, `Image`) before a wrapper; use `Platform.select` for platform differences rather than duplicated components.
- Use `FlatList` virtualization for lists; never map a large array into the tree.

## Repository Conformance Gate
- Run `oaef doctor` (native: `node tool/governance.mjs doctor`).
- Run `oaef lint` (native: `npx eslint .`).
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The component renders every variant and state from props alone.
- No literal token values and no inline style in render loops.
- The contract serves every existing consumer without special-casing.

## Anti-Patterns
- Booleans multiplying a combinatorial variant space.
- A `style` prop object rebuilt on every render without `StyleSheet.create`.
- A component that fetches its own data.
- A wrapper that only re-exports a platform primitive unchanged.
