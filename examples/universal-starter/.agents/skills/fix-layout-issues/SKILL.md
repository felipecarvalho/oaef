---
name: fix-layout-issues
description: >-
  Use when a layout overflows, a constraint is unbounded or a render error breaks a surface in Universal / Polyglot. Triggers on: "overflow", "unbounded", "layout", "layout broken", "render error". Chains into: test-generator, run-static-analysis. Diagnoses structural render defects in Universal / Polyglot: it isolates the offending constraint, state or data shape, fixes the shared root cause instead of clipping the symptom, and proves the correction with a regression test.
argument-hint: "[symptom or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: universal
  version: 1.1.0
---

# Fix Layout Issues (Universal / Polyglot)

> **Stack Profile:** Universal / Polyglot
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Turn a visual or structural defect into a proven root-cause fix backed by a regression test, never a clip that hides the symptom.

## Territory
- Interactive defect sources: `.tsx`, `.jsx`, `.kt`, `.dart`, `.swift` render trees and their style/token definitions.
- Headless defect sources: `.py`, `.go`, `.rs`, `.mjs`, `.sh` that emit a payload or stream that a surface renders.
- Error logs, stack traces and screenshots attached to the report.

## Triage Procedure
1. Reproduce the defect in the isolated preview harness before editing anything.
2. Classify it: unbounded constraint, missing finite size, null/absent data, or stale state.
3. Locate the shared root: grep every caller of the failing widget or serializer.
4. Fix the root once; remove any per-call-site workaround introduced earlier.
5. Add a regression test that fails before the fix and passes after it.
6. Re-render the harness at the smallest and largest breakpoints.
7. Re-run `bash lint.sh` and `bash test.sh` to confirm the fix introduces no new finding.

## Defect Classes
- **Unbounded constraint** — a scrollable or growing child inside a parent that offers no finite extent.
- **Missing size** — a surface that assumes a viewport the device does not provide.
- **Absent data** — a render path that dereferences a value the payload omitted.
- **Stale state** — a layout that keeps a previous breakpoint after the window changed.

## Repository Conformance Gate
- `oaef doctor` and `oaef lint` clean for the touched repository.
- `oaef clean-code` (native: `bash tool/governance.sh clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The defect reproduces in a test before the fix and disappears after it.
- The shared root cause is corrected, not masked by a clip or an overflow guard alone.
- No new unbounded constraint is introduced elsewhere.

## Anti-Patterns
- Adding `overflow: hidden` to hide a real sizing defect.
- Patching the one reported call site while sibling call sites stay broken.
- Marking the issue fixed without a reproducing test.
