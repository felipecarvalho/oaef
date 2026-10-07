---
name: component-author
description: >-
  Use when authoring or extracting a reusable component, widget, button, card or modal in Universal / Polyglot. Triggers on: "component", "widget", "button", "card", "modal". Chains into: ui-preview, responsive-layout, test-generator. Authors reusable Universal / Polyglot surfaces from design-system tokens: one responsibility per component, tokens instead of literals, and a contract that serves every consumer without a bespoke variant.
argument-hint: "[component name]"
license: MIT
metadata:
  framework: OAEF
  stack: universal
  version: 1.1.0
---

# Component Author (Universal / Polyglot)

> **Stack Profile:** Universal / Polyglot
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Author a reusable surface that every consumer can use without a one-off variant, built strictly from the shared design tokens of whichever embedded UI framework this repository uses.

## Territory
- Shared component directories: `src/components/**`, `src/shared/**`, `src/ui/**`, `lib/shared/**`, `Sources/<Module>/Presentation/**`.
- Token and theme definitions.
- Applies to UI files (`.tsx`, `.jsx`, `.kt`, `.dart`, `.swift`); for headless modules prefer a plain function with a documented contract.

## Component Contract
- One responsibility per component: if it needs an "and" to describe it, split it.
- Props are minimal; a prop that only toggles one call site is a signal to extract instead.
- State is lifted or external; the component renders what it is given.
- Accessibility attributes are part of the contract, not an afterthought.

## Token Discipline
- Colors, spacing, radii and typography come from tokens; raw literals are a finding.
- The Rule of Two applies: a shape used twice is elevated to a shared component; a single-use wrapper is deleted.
- Variants are expressed through a closed set (enum or discriminated union), never through free-form strings.
- Spacing and typography scale from the shared tokens; a component never defines its own scale.
- A component that grows past the Clean Sizing bounds is split by responsibility, not by visual section.
- The public prop type is exported and documented; consumers depend on it, not on the implementation.
- Slots replace boolean flags when a consumer needs to inject arbitrary content.

## Repository Conformance Gate
- `oaef doctor` and `oaef lint` clean for the touched repository.
- `oaef clean-code` (native: `bash tool/governance.sh clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The component renders through `ui-preview` in every declared variant.
- Zero raw design literals; every value traces to a token.
- No consumer needs a bespoke override to use it.

## Anti-Patterns
- A component with a `variant` string parsed by substring.
- Inlining a color or spacing value that already exists as a token.
- Wrapping a single stdlib or framework primitive with no added policy.
