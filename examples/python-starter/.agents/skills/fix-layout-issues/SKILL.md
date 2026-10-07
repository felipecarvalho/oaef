---
name: fix-layout-issues
description: >-
  Use when a layout overflows, a constraint is unbounded or a render error breaks a surface in Python 3. Triggers on: "overflow", "unbounded", "layout", "layout broken", "render error". Chains into: test-generator, run-static-analysis. Diagnoses structural render defects in Python 3: it isolates the offending constraint, state or data shape, fixes the shared root cause instead of clipping the symptom, and proves the correction with a regression test.
argument-hint: "[symptom or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: python
  version: 1.1.0
---

# Structural Defect Triage (Python 3)

> **Stack Profile:** Python 3
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Repair structural render defects: an overflowing or unbounded payload, a serialization
error, a shape mismatch between producer and consumer. Fix the shared root cause, never
clip the symptom at one call site.

## Territory
- `<package>/features/<feature>/presentation/` — serializers and response shaping.
- `<package>/features/<feature>/data/` — adapters producing the offending shape.
- `<package>/features/<feature>/domain/` — models whose constraints are violated.
- `tests/features/<feature>/` — where the regression test lands.

## Triage Procedure
1. Reproduce deterministically: capture the input that triggers the defect as a fixture.
2. Locate the failing boundary: serializer, mapper, adapter or domain model.
3. Identify the constraint that is violated — unbounded result set, missing field,
   unexpected `None`, oversized payload, cyclic reference in serialization.
4. Distinguish symptom from cause: a `try/except` that hides the error is a symptom patch.
5. `grep -rn` every producer and consumer of the offending shape; the defect is usually
   shared across call sites.
6. Fix the single shared root cause: bound the collection, declare the field, enforce the
   constraint in the model, or break the cycle at the mapping boundary.
7. Add a regression test that fails before the fix and passes after it.

## Common Defect Classes
- Unbounded collection reached serialization: apply the pagination cap from the payload
  shaping contract instead of serializing everything.
- `None` leaking into a required field: fix the producing adapter, not the serializer.
- Depth or recursion error from cyclic object graphs: introduce an identity-based
  reference and map at the boundary.
- Encoding or content-type mismatch: fix the negotiated representation, add the missing
  charset.
- Silent truncation: a payload capped without a `has_more` marker misleads the consumer.

## Repository Conformance Gate
- `oaef doctor` — structural conformance.
- `oaef lint` — governance findings.
- `oaef clean-code` (native: `python3 tool/governance.py clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The defect reproduces from a committed fixture and the regression test guards it.
- The shared root cause is fixed; no per-call-site workaround remains.
- `ruff check .`, `mypy .` and `pytest` pass for the affected feature.

## Anti-Patterns
- Wrapping the failure in `except Exception: pass` to make the error disappear.
- Clamping a payload at one call site while other producers stay unbounded.
- Special-casing a single input instead of correcting the shared constraint.
- Widening a type annotation to `Any` to silence the real mismatch.
- Deleting the regression test because it is inconvenient to maintain.
