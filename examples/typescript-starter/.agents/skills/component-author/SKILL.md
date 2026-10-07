---
name: component-author
description: >-
  Use when authoring or extracting a reusable component, widget, button, card or modal in TypeScript & Web. Triggers on: "component", "widget", "button", "card", "modal". Chains into: ui-preview, responsive-layout, test-generator. Authors reusable TypeScript & Web surfaces from design-system tokens: one responsibility per component, tokens instead of literals, and a contract that serves every consumer without a bespoke variant.
argument-hint: "[component name]"
license: MIT
metadata:
  framework: OAEF
  stack: typescript-web
  version: 1.1.0
---

# Component Author (TypeScript & Web)

> **Stack Profile:** TypeScript & Web
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission

Author one reusable surface with one responsibility, driven by design-system tokens and a
contract that serves every consumer. Extract to `src/components/` only when a second
concrete consumer exists (Rule of Two).

## Territory

- `src/components/**` — shared presentation primitives.
- `src/shared/ui/**` — token-backed primitives and composites.
- `src/features/<feature>/presentation/**` — feature-local components, promoted only when
  reused.
- Design tokens: CSS custom properties in `src/styles/tokens.css` (or the theme module).

## Component Contract

- Props are explicit and typed; a component owns its presentation, not its data fetching.
- Every prop that varies across consumers is a first-class prop; a prop that never varies
  is a constant inside the component, not a dead parameter.
- Composition over configuration: accept `children` or slots instead of a `variant` string
  that switches entire layouts.
- State is local and minimal; lift it only when a sibling truly needs it.
- Accessibility is part of the contract: `aria-*`, focus management, keyboard handling and
  a visible focus ring ship with the component.
- The public surface is the smallest one that works: no exported internal helpers.

## Token Discipline

- Colour, spacing, radius, typography, shadow and motion come from tokens only; a raw
  hex, `px` value or magic number is a violation.
- Prefer CSS custom properties and fluid units: `padding: var(--space-3);`,
  `font-size: clamp(0.875rem, 0.8rem + 0.4vw, 1.125rem);`.
- Respect `@media (prefers-reduced-motion: reduce)` and `prefers-color-scheme`; never
  hardcode a light-only or motion-heavy behaviour.
- Variants map to token sets, not to duplicated style blocks.
- Use `:where()` for low-specificity defaults so consumers can override without `!important`.

## Repository Conformance Gate

- Run `oaef doctor`, `oaef lint`, `oaef clean-code` (native:
  `node tool/governance.mjs doctor|lint|clean-code`).
- Run `npx tsc --noEmit` and `npx eslint src`.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria

- The component has one responsibility and zero dead props.
- No literal colour, spacing or radius value remains; all resolve to tokens.
- Focus, keyboard and reduced-motion behaviour are implemented and previewable.

## Anti-Patterns

- A `variant` prop with a monolithic conditional containing several unrelated layouts.
- A component that fetches data or reads global stores directly.
- Hardcoded `#3b82f6` and `16px` where `var(--color-primary)` and `var(--space-4)` exist.
- Exporting internal sub-components "just in case" with no external consumer.
