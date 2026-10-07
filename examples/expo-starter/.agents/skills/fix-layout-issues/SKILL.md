---
name: fix-layout-issues
description: >-
  Use when a layout overflows, a constraint is unbounded or a render error breaks a surface in Expo. Triggers on:
  "overflow", "unbounded", "layout", "layout broken", "render error". Chains into: test-generator,
  run-static-analysis. Diagnoses structural render defects in Expo: it isolates the offending constraint, state or
  data shape, fixes the shared root cause instead of clipping the symptom, and proves the correction with a
  regression test.
argument-hint: "[symptom or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: expo
  version: 1.1.0
---

# Fix Layout Issues (Expo)

> **Stack Profile:** Expo
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Return a broken surface to a correct layout by fixing the structural cause, not the visible symptom. Isolate the offending constraint, state, or data shape; correct the shared root; then prove the fix with a regression test.

## Territory
- `src/components/`, `src/features/<feature>/presentation/` - the surface that renders incorrectly.
- `src/features/<feature>/domain/` - data shapes that produce empty or unexpected input.
- `app/` - route and layout wrappers that impose constraints.

## Triage Procedure
1. **Reproduce deterministically** - pin the exact width, state, and data that triggers the defect in `ui-preview`.
2. **Classify the symptom**:
   - Overflow - content exceeds its parent; a horizontal or vertical scroll appears unexpectedly.
   - Unbounded height - a scrollable or virtualized list nested in an unbounded parent.
   - Zero-size - a flex child collapses because a parent has no defined axis.
   - Render error - a thrown exception, a `key` collision, or a bad conditional return.
3. **Locate the constraint**, not the widget: walk up the tree to the element that fixes or fails to fix a size.
4. **Fix the root**: correct the flex/axis configuration, wrap the virtualized list in a bounded parent, or handle the actual data shape. Never add `overflow: 'hidden'` to hide a symptom.
5. **Regression test**: add a render test that would fail on the original defect and passes now.
6. **Cascade**: search the same pattern in sibling surfaces and fix it everywhere in the same change.

## Repository Conformance Gate
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`) and fix every blocking finding.
- Run `oaef lint` and `oaef doctor`.
- Record any layout fix deferred for an unowned surface in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The surface renders correctly at compact and expanded widths with real and empty data.
- The regression test fails on the original defect and passes on the fix.
- The same defect pattern is remediated in every equivalent surface.

## Anti-Patterns
- Clipping, hiding overflow, or shrinking content to conceal an unbounded constraint.
- Fixing one screen while identical surfaces keep the defect.
- Patching a data-shape crash at the render site instead of handling the shape at the boundary.
