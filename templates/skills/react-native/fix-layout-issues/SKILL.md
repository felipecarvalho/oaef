---
name: fix-layout-issues
description: >-
  Use when a layout overflows, a constraint is unbounded or a render error breaks a surface in React Native. Triggers on: "overflow", "unbounded", "layout", "layout broken", "render error". Chains into: test-generator, run-static-analysis. Diagnoses structural render defects in React Native: it isolates the offending constraint, state or data shape, fixes the shared root cause instead of clipping the symptom, and proves the correction with a regression test.
argument-hint: "[symptom or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: react-native
  version: 1.1.0
---

# Fix Layout Issues (React Native)

> **Stack Profile:** React Native
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Turn a render defect into a structural fix. Reproduce the failing state, isolate the constraint or data shape that causes it, repair the shared root, and lock the fix with a regression test.

## Territory
- `src/components/**`, `src/shared/ui/**` — flexible layouts.
- `src/features/<feature>/presentation/screens/**` — screens with scroll and container constraints.
- `__tests__/` — reproduction and regression tests.

## Triage Procedure
1. Reproduce in the preview harness or a focused test; capture the exact state and viewport.
2. Classify the failure:
   - **Overflow** — content exceeds its parent; a fixed size fights intrinsic content.
   - **Unbounded constraint** — a child needs a definite size but the parent imposes none.
   - **Text/RTL** — long or localised strings, font scaling, or right-to-left direction.
   - **Data shape** — an empty or over-long collection exposes an unhandled branch.
3. `grep` every renderer of the offending component; the defect is usually a shared root, not one screen.
4. Apply the structural fix at the root:
   - give scroll content a definite parent (`flex: 1` inside a sized container);
   - let text flex with `flexShrink: 1` instead of clipping;
   - replace `flexWrap` overflow with a virtualized list;
   - correct the shared layout prop rather than adding a one-off override.
5. Confirm the layout at compact and expanded widths and under font scaling.
6. Add a regression test that fails before the fix and passes after.

## Repository Conformance Gate
- Run `oaef doctor` (native: `node tool/governance.mjs doctor`).
- Run `oaef lint` (native: `npx eslint .`).
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The defect no longer reproduces in the harness or test.
- The fix lives in the shared root and removes the class of defect, not one instance.
- A regression test guards the corrected behaviour.

## Anti-Patterns
- Adding `overflow: 'hidden'` to mask visible content loss.
- A magic `height` or `maxWidth` tuned to one device.
- Patching a single screen while the sibling renderer stays broken.
- Fixing the symptom without a regression test.
