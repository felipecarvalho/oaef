---
name: fix-layout-issues
description: >-
  Use when a layout overflows, a constraint is unbounded or a render error breaks a surface in TypeScript & Web. Triggers on: "overflow", "unbounded", "layout", "layout broken", "render error". Chains into: test-generator, run-static-analysis. Diagnoses structural render defects in TypeScript & Web: it isolates the offending constraint, state or data shape, fixes the shared root cause instead of clipping the symptom, and proves the correction with a regression test.
argument-hint: "[symptom or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: typescript-web
  version: 1.1.0
---

# Fix Layout Issues (TypeScript & Web)

> **Stack Profile:** TypeScript & Web
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission

Diagnose and remove the structural cause of a render defect: overflow, an unbounded
constraint, a collapsed grid, a stacking-context surprise or a runtime render error. Fix
the shared constraint, never the visual symptom.

## Territory

- `src/components/**`, `src/shared/ui/**` — reusable surfaces where a defect propagates.
- `src/features/<feature>/presentation/**` — screen-level layout and grid code.
- `src/styles/**` — token and layout utility definitions.
- `src/**/*.spec.ts` — the regression test that pins the fix.

## Triage Procedure

1. Reproduce at the smallest viewport and with the longest realistic content; overflow is
   usually content-driven, not viewport-driven.
2. Locate the offending constraint: the first ancestor whose width or height is
   unbounded, or the flex/grid child that refuses to shrink.
3. Classify the cause:
   - **Unbounded** — `min-width: auto` on a flex child, a grid track without `minmax(0, 1fr)`,
     a scroll container with no explicit height.
   - **Overflow** — a fixed `width` or `height` that content exceeds, or a long unbroken
     token that needs `overflow-wrap: anywhere`.
   - **Collapse** — a parent with `height: 0` because all children are absolutely
     positioned or floated.
   - **Stacking** — a `z-index` or `position` interaction that hides the surface.
   - **Render error** — a thrown exception in a render body, commonly a missing key,
     a bad date, or a nullable value treated as present.
4. `grep -rn` the pattern across the codebase: if the same broken constraint appears in
   sibling files, fix every occurrence in the same pass (cascade remediation).
5. Apply the minimal structural correction at the shared root; do not add
   `overflow: hidden` to hide a real overflow, and do not add `!important`.
6. If the cause is a nullable value, route to `nullable-types`; if it is an unbounded
   data set, route to `responsive-layout`.
7. Write a regression test that reproduces the original failure and now passes.

## Repository Conformance Gate

- Run `oaef doctor`, `oaef lint`, `oaef clean-code` (native:
  `node tool/governance.mjs doctor|lint|clean-code`).
- Run `npx tsc --noEmit` and `npx eslint src`.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria

- The defect no longer reproduces at any named breakpoint or with extreme content.
- The correction is structural, not a clip, a `!important` or a size hack.
- A regression test fails before the fix and passes after it.

## Anti-Patterns

- Masking overflow with `overflow: hidden` when the real layout is wrong.
- Pinning a magic `height` that breaks the moment the content changes.
- Fixing one instance while identical defects remain in sibling components.
- Silencing a render error with an empty `catch` or a bare fallback.
