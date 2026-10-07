---
name: fix-layout-issues
description: >-
  Use when a layout overflows, a constraint is unbounded or a render error breaks a surface in Rust.
  Triggers on: "overflow", "unbounded", "layout", "layout broken", "render error". Chains into:
  test-generator, run-static-analysis. Diagnoses structural render defects in Rust: it isolates the
  offending constraint, state or data shape, fixes the shared root cause instead of clipping the
  symptom, and proves the correction with a regression test.
argument-hint: "[symptom or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: rust
  version: 1.1.0
---

# Surface Defect Triage (Rust)

> **Stack Profile:** Rust
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Diagnose and fix structural output defects: an overflowing buffer, an unbounded collection, a broken
serialization shape or a panic on the render path. The fix targets the shared root cause, never the
symptom.

## Territory
- `src/<feature>/presentation/**` — serialization, formatting and output construction.
- `src/<feature>/data` — parsing that can overflow a fixed-width buffer or field.
- `src/shared/**` — formatting helpers shared across surfaces.
- `tests/` — regression tests proving the correction.

## Triage Procedure
1. Reproduce with the smallest fixture that still triggers the defect; capture the exact output.
2. Locate the offending constraint: a fixed buffer size, an unbounded growth path, a mismatched field
   width or an unchecked numeric conversion.
3. Trace to the shared root: grep every caller (`rg -n '<fn_name>' src`) and fix the owning function
   once, not each call site.
4. Classify the defect:
   - overflow — a value exceeds the buffer or field that holds it; size the type to the data.
   - unbounded — a collection or string grows without a limit; impose a bound or stream instead.
   - render error — serialization, formatting or a panic on the output path; return a typed error.
5. Apply the smallest correct fix at the root; never clip, truncate silently or catch the panic to hide
   the symptom.
6. Add a regression test that fails on the old code and passes on the new; keep the fixture.

## Repository Conformance Gate
- `cargo run --bin governance -- clean-code`
- `oaef lint` and `cargo clippy --all-targets -- -D warnings`
- `oaef doctor`
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The reproduction fixture no longer triggers the defect, and a regression test guards it.
- The fix lives at the shared root, applying to every equivalent call path.

## Anti-Patterns
- Truncating or clipping output to hide an overflow.
- Widening a buffer without addressing why the value grew.
- A `catch_unwind` or discarded `Result` used to mask a panic on the render path.
- Fixing one call site while the other callers keep the same defect.
