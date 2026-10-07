---
name: fix-layout-issues
description: >-
  Use when a layout overflows, a constraint is unbounded or a render error breaks a surface in Swift. Triggers on: "overflow", "unbounded", "layout", "layout broken", "render error". Chains into: test-generator, run-static-analysis. Diagnoses structural render defects in Swift: it isolates the offending constraint, state or data shape, fixes the shared root cause instead of clipping the symptom, and proves the correction with a regression test.
argument-hint: "[symptom or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: swift
  version: 1.1.0
---

# Fix Layout Issues (Swift)

> **Stack Profile:** Swift
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Diagnose and fix structural SwiftUI render defects at the shared root cause. Clipping, truncation or a clipped overlay hides the symptom; the fix removes the constraint, state or data shape that produced it.

## Territory
- `Sources/<Module>/Presentation/` — the failing view tree.
- `Sources/<Module>/Presentation/Components/` — shared surfaces involved.
- `Sources/<Module>/DesignSystem/` — spacing and sizing tokens.
- `Tests/` — the regression test that locks the correction.

## Triage Procedure
1. Reproduce in a `#Preview` with the smallest input that triggers the defect.
2. Identify the offending node: unbounded frame, unbounded text or an oversized child.
3. Classify the cause: missing constraint, bad data shape, wrong state, or a fixed frame.
4. Fix the shared root: the token, the state model or the parent container.
5. Grep for sibling views that repeat the same pattern and fix them holistically.
6. Add a regression test or a promoted preview that fails before and passes after.
7. Re-check the other size classes and Dynamic Type sizes for the same defect.
8. Record any defect that cannot be reproduced deterministically in the handoff.

## Repository Conformance Gate
- `oaef doctor`
- `oaef lint`
- `oaef clean-code` (native: `swift tool/governance.swift clean-code`)
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The defect no longer reproduces at the smallest input and at the extremes.
- The fix addresses the shared cause across every equivalent view.
- A regression test proves the correction.
- `swift build` and `swift test` pass.

## Anti-Patterns
- `.clipped()` or `.lineLimit(1)` applied to hide an overflow.
- A hardcoded `.frame(width:height:)` that masks an unbounded parent.
- Fixing one view while its siblings keep the same defect.
- A layout change shipped without a reproduction preview or test.
- Treating a data-shape defect as a pure styling issue.
