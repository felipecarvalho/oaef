---
name: responsive-layout
description: >-
  Use when a surface must adapt to another screen size, form factor or payload shape in TypeScript & Web. Triggers on: "responsive", "adaptive", "breakpoint", "tablet", "foldable", "viewport". Chains into: ui-preview, test-generator. Owns adaptive design in TypeScript & Web: breakpoints, safe areas, dynamic type and foldables for interactive surfaces, and payload shaping, pagination, content negotiation and streaming backpressure for headless ones.
argument-hint: "[breakpoint or surface name]"
license: MIT
metadata:
  framework: OAEF
  stack: typescript-web
  version: 1.1.0
---

# Responsive Layout (TypeScript & Web)

> **Stack Profile:** TypeScript & Web
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission

Make a browser surface adapt to every viewport and input mode without duplicated layouts.
The browser is the breakpoint engine: CSS media and container queries resolve adaptation
before JavaScript observes anything.

## Territory

- `src/components/**`, `src/shared/ui/**` — reusable adaptive surfaces.
- `src/features/<feature>/presentation/**` — screen-level layouts and grids.
- `src/styles/**` — token files, breakpoint custom properties, fluid scales.
- `src/**/*.css`, CSS modules, and styled or utility-class call sites.
- `public/**` — responsive image assets and `srcset` metadata.

## Adaptive Surface Design

Adaptation is layered, cheapest first:

1. **Intrinsic layout** — `flex-wrap`, `grid-template-columns: repeat(auto-fit, minmax(…))`,
   `min()`, `max()`, `clamp()`. Most surfaces need no query at all.
2. **Container queries** — `@container (min-width: 30rem)` adapts a component to its
   parent slot, which is what actually matters for a reusable surface.
3. **Media queries** — viewport-level adjustments, safe areas and input modality.
4. **Viewport observation in JS** — `ResizeObserver` or `matchMedia` only when the DOM
   cannot express the rule, and never on the hot render path.

Dynamic type: use fluid `clamp()` typography and relative units (`rem`, `em`, `ch`) so the
surface respects the user's base font size; never fix a font size in `px`.

## Breakpoint Strategy

- Define named breakpoints as custom properties in `src/styles/tokens.css`; reference the
  names, never repeat a raw `768px` across files.
- Mobile-first: base rules apply to the smallest viewport, `min-width` queries add
  layers. Avoid `max-width` cascades that fight each other.
- Container queries are the default for components; media queries are for the page shell.
- Respect `env(safe-area-inset-*)` for notched and foldable viewports.
- Honour `@media (prefers-reduced-motion: reduce)` and `prefers-color-scheme`.
- Serve responsive images with `srcset`/`sizes` and `loading="lazy"`.
- A foldable or tablet must never render a stretched single column: raise the column
  count or expand the shell at the named breakpoint.
- Verify with `ui-preview` at each named breakpoint before integration.

## Repository Conformance Gate

- Run `oaef doctor`, `oaef lint`, `oaef clean-code` (native:
  `node tool/governance.mjs doctor|lint|clean-code`).
- Run `npx tsc --noEmit` and `npx eslint src`.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria

- Every breakpoint is a named token; no raw pixel breakpoint is repeated.
- The surface adapts at each named breakpoint without a duplicated layout component.
- Fluid type, safe areas, reduced motion and colour scheme are handled.

## Anti-Patterns

- A separate desktop component duplicating the mobile component.
- `window.innerWidth` read in a render body to choose a layout.
- Fixed `px` font sizes that ignore the user's base size.
- A raw `@media (max-width: 768px)` repeated in five files instead of a named token.
