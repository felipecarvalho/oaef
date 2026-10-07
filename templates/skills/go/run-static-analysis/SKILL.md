---
name: run-static-analysis
description: >-
  Use when the analyzer, linter or type checker reports findings in Go. Triggers on: "analyze", "lint", "typecheck", "warnings". Chains into: code-review. Runs the Go analyzer with warnings treated as errors and zero suppressions: every finding is fixed in the code instead of being silenced with an inline ignore directive, and machine-generated files stay the only exemption.
argument-hint: "[scope or analyzer]"
license: MIT
metadata:
  framework: OAEF
  stack: go
  version: 1.1.0
---

# Run Static Analysis (Go)

> **Stack Profile:** Go
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Run the Go analyzer and linter with zero suppressions: every finding is fixed in code, and warnings are errors.

## Territory
- `*.go` across the module — `go vet` and `golangci-lint` scope.
- `.golangci.yml` / `.golangci.yaml` — the linter configuration.
- `tool/governance.go` — the OAEF governance runtime.
- `go.mod` / `go.sum` — module hygiene.

## Analyzer Invocation
- Vet the whole module: `go vet ./...`.
- Lint: `golangci-lint run` (or `golangci-lint run --timeout=5m`).
- Format check: `gofmt -l .` must print nothing; `gofumpt -l .` when the repository uses it.
- Tidy check: `go mod tidy` must produce no diff, and `go build ./...` must succeed.
- Machine check: `go run tool/governance.go clean-code` (alias of `oaef clean-code`) runs the `CC-*` mechanical barriers.
- Run the analyzer against the whole module before declaring completion; a package-scoped run hides cross-package findings.

## Zero-Suppression Policy
- No `//nolint` directive is allowed without a one-line justification naming the rule and the reason; a bare `//nolint` is rejected.
- `//lint:ignore` and `-e` exclusions are forbidden as a way to make a build green.
- A caught error is never silenced to please a linter; fix the handling (`CC-06`).
- Machine-generated files (`*.g.*`, `*_pb2.go`, `*.generated.go`) are the only exemption; they are excluded from the scan, never suppressed inline.
- Fix the root cause across every occurrence; a single-file disable hides the next offender.

## Repository Conformance Gate
- Run `oaef doctor` (native: `go run tool/governance.go doctor`).
- Run `oaef lint` (native: `go run tool/governance.go lint`).
- Run `oaef clean-code` (native: `go run tool/governance.go clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `go vet ./...`, `golangci-lint run` and `gofmt -l .` all report clean.
- `oaef clean-code` reports zero blocking `CC-*` findings under the strict profile.
- Any remaining `//nolint` carries a justification and is listed in the handoff when unresolved.

## Anti-Patterns
- Adding `//nolint` to silence a real finding.
- Excluding a package from the linter config to hide violations.
- Ignoring a returned error to satisfy the compiler or the linter.
- Fixing one instance of a repeated finding and leaving its siblings.
