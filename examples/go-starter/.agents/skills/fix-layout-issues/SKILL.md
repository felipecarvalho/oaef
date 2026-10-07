---
name: fix-layout-issues
description: >-
  Use when a layout overflows, a constraint is unbounded or a render error breaks a surface in Go. Triggers on: "overflow", "unbounded", "layout", "layout broken", "render error". Chains into: test-generator, run-static-analysis. Diagnoses structural render defects in Go: it isolates the offending constraint, state or data shape, fixes the shared root cause instead of clipping the symptom, and proves the correction with a regression test.
argument-hint: "[symptom or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: go
  version: 1.1.0
---

# Fix Layout Issues (Go)

> **Stack Profile:** Go
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Diagnose and repair structural render defects in a Go service: a handler that emits a malformed body, a template that renders the wrong shape, an unbounded response that overruns a limit, or a serialisation path that drops fields.

## Territory
- `internal/<feature>/http/` — handler and encoder defects.
- `internal/<feature>/domain/` — the data shape that reaches the wire.
- `templates/` or `internal/.../*.tmpl` — HTML/text templates.
- `internal/<feature>/*_test.go` — the regression test.

## Triage Procedure
1. Reproduce the defect deterministically: capture the request, the input shape and the exact output (body or error).
2. Locate the offending constraint: an encoder ignoring a field, a template referencing a missing key, a slice emitted without a length bound, a nested struct left unset.
3. Find the shared root cause with `grep -rn` across every caller; a symptom appearing in two handlers means the defect lives in the shared encoder or the type definition.
4. Fix the root cause once — in the domain type, the shared encoder or the template — rather than patching each call site.
5. Add a regression test that fails before the fix and passes after; keep the input that reproduced the defect.
6. Run `gofmt -l .`, `go vet ./...` and the golden preview to confirm no other surface regressed.
7. Update the handoff with the defect signature so the same shape is recognised next time.

Common Go shapes: a struct tag typo (`json:"naem"`), a nil map rendered as `null`, an `io.Writer` write error ignored, a template executed without `{{define}}`, a slice reused across a loop iteration, an error response serialised with a success status code.
Reproduce with the smallest input that still fails; if the defect needs a 10k-row payload to appear, the constraint is the unbounded response, not the row count.

## Repository Conformance Gate
- Run `oaef doctor` (native: `go run tool/governance.go doctor`).
- Run `oaef lint` (native: `go run tool/governance.go lint`).
- Run `oaef clean-code` (native: `go run tool/governance.go clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The defect is reproduced by a test that fails without the fix.
- The correction lives at the shared root cause, not at a single call site.
- The golden preview for the affected surface is regenerated and reviewed.

## Anti-Patterns
- Clipping the output (truncating a body) instead of fixing the constraint.
- Special-casing one input that reproduces the defect.
- Suppressing the write error from a template or encoder instead of handling it.
- Patching a symptom in one handler while the shared type stays broken.
