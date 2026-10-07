---
name: component-author
description: >-
  Use when authoring or extracting a reusable component, widget, button, card or modal in Expo. Triggers on:
  "component", "widget", "button", "card", "modal". Chains into: ui-preview, responsive-layout, test-generator.
  Authors reusable Expo surfaces from design-system tokens: one responsibility per component, tokens instead of
  literals, and a contract that serves every consumer without a bespoke variant.
argument-hint: "[component name]"
license: MIT
metadata:
  framework: OAEF
  stack: expo
  version: 1.1.0
---

# Component Author (Expo)

> **Stack Profile:** Expo
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Author reusable React Native surfaces that every consumer can use without a bespoke variant. One responsibility per component, design-system tokens instead of literals, and tests that pin the contract before the component spreads through the app.

## Territory
- `src/components/` - shared, presentation-only surfaces (buttons, cards, modals, inputs).
- `src/shared/` - cross-cutting hooks and pure helpers a component depends on.
- `src/features/<feature>/presentation/` - feature-local components extracted from screens.

## Component Contract
- Props are a single typed interface; no positional booleans that silently switch behavior.
- The component renders a pure function of props and context, with no ambient data fetching.
- Callbacks are named for intent (`onSubmit`, `onDismiss`), never `onPress` reused for several meanings.
- Accessibility is part of the contract: `accessibilityRole`, `accessibilityLabel`, and a minimum touch target.
- Controlled by default; uncontrolled only when the contained state is genuinely internal.
- No `any` props; each prop is a narrow, documented type.

## Token Discipline
- Colors, spacing, radii, and typography come from the design-system theme; literals are banned in components.
- Reach theme values through one accessor (context or token module), never ad-hoc hex strings.
- Variants are declared as data (`variant: 'primary' | 'secondary'`), not as duplicated components.
- Platform differences go through `Platform.select`, not through a fork of the component.

```tsx
type CardProps = { title: string; children: ReactNode; onDismiss?: () => void };
```

## Repository Conformance Gate
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`) and fix every blocking finding.
- Run `oaef lint` and `oaef doctor`; keep `tsc --noEmit` clean.
- Record unresolved contract questions in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The component renders correctly across its declared variants and sizes.
- Zero literal color, spacing, or font values remain in the component.
- A test pins the contract: props, states, and accessibility labels.

## Anti-Patterns
- Boolean flag props that make one component do two unrelated things.
- Hex colors and magic numbers instead of theme tokens.
- Extracting a component that only one caller uses without a mock need.
