---
name: ui-preview
description: >-
  Use when a component or screen must be inspected in isolation before it is wired into the application in Go. Triggers on: "preview", "storybook", "isolated render". Chains into: test-generator, run-static-analysis. Provides isolated preview harnesses for Go: loading, success, empty and error states are rendered without booting the full runtime, so layout, tokens and typography are validated before integration.
argument-hint: "[component or screen name]"
license: MIT
metadata:
  framework: OAEF
  stack: go
  version: 1.1.0
---

# UI Preview / Isolated Harness (Go)

> **Stack Profile:** Go
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Render a Go surface in isolation and inspect its output for every state before it is wired into the running service. In a headless stack the "render" is the serialised payload or the handler response.

## Territory
- `internal/<feature>/http/` — the handler under preview.
- `cmd/<name>-preview/main.go` — a runnable preview entry point, when a small binary is warranted.
- `testdata/` — golden files for each previewed state.
- `internal/<feature>/*_test.go` — harness-driven state tests.

## Preview Harness
Build the narrowest harness that exercises the surface without the full composition:
- Prefer an `Example` function (`func ExampleComponent()`) or a golden test that drives the handler with `httptest.NewRecorder` — no server boot required.
- For a runnable preview, add a small binary under `cmd/<name>-preview/` guarded from the production build.
- Render every state explicitly: **loading** (in-flight or partial), **success**, **empty** (no data), and **error** (typed failure mapped to a status).
- Compare against a golden file in `testdata/`; update it deliberately with `go test ./... -update`.
- Feed the harness the same tokens/constants the production path uses; a preview that diverges from production is a false signal.

```go
func TestPreviewSuccess(t *testing.T) {
    recorder := httptest.NewRecorder()
    handler(recorder, httptest.NewRequest(http.MethodGet, "/items", nil))
    got := recorder.Body.String()
    assertGolden(t, "success.json", got)
}
```

## Repository Conformance Gate
- Run `oaef doctor` (native: `go run tool/governance.go doctor`).
- Run `oaef lint` (native: `go run tool/governance.go lint`).
- Run `oaef clean-code` (native: `go run tool/governance.go clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- All four states (loading, success, empty, error) render from the harness.
- The golden files match the production encoding path byte for byte.
- The harness imports nothing that boots a real network or database.
- The command runs with `go run ./cmd/<name>-preview`.

## Anti-Patterns
- A preview that reimplements the handler instead of calling it.
- Booting the full server or a real store to inspect one response.
- A golden file committed without a reproducible update command.
- A preview binary left in the production build output.
