---
name: test-generator
description: >-
  Use when writing or expanding automated tests, mocks or fixtures for Go. Triggers on: "test", "coverage", "mock", "fixture". Chains into: collect-coverage, run-static-analysis. Generates Go tests with the AAA pattern and one DRY factory per entity: unit, component and integration coverage of the happy path and of every error branch, with deterministic data and no dead parameters.
argument-hint: "[target class or module]"
license: MIT
metadata:
  framework: OAEF
  stack: go
  version: 1.1.0
---

# Test Generator (Go)

> **Stack Profile:** Go
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Generate deterministic Go tests with the AAA pattern and one DRY factory per entity, covering the happy path and every error branch.

## Territory
- `*_test.go` — unit and table-driven tests in the package directory.
- `internal/<feature>/*/{domain,data,http}` — the packages under test.
- `testdata/` — fixtures and golden files.
- `tests/` — integration tests, when the repository declares one.

## Testing Pyramid
- **Unit** — pure domain logic, table-driven: one `[]struct{ name string; ... }` with `t.Run(tc.name, …)` per case.
- **Component** — a handler or port exercised with `httptest` and an in-memory fake, no real I/O.
- **Integration** — the composition root wired against a disposable dependency, guarded by a build tag or an environment check.
- Every test names the behaviour and the expectation (`TestReserve_SessionExpired_ReturnsError`).
- No `time.Sleep` for synchronisation; use channels, `sync.WaitGroup` or a fake clock.

## DRY Test Factories (make*)
- One factory per entity, named `make<Entity>` (or `make_<entity>` for unexported helpers).
- The factory takes only the fields the test varies; every other field gets a deterministic default.
- No dead parameters: a parameter that no test overrides is removed and defaulted inside the factory.
- Optional collection fields default to a non-nil empty slice or map, never nil at the call site.
- Factories live next to the tests in the same package, unexported unless shared across packages.

```go
func makeSession(options ...func(*Session)) Session {
    session := Session{ID: "s-1", State: StateActive}
    for _, option := range options {
        option(&session)
    }
    return session
}
```
- Prefer fakes that implement the consumer-owned interface over generated mocks; a generated mock is used only when the call sequence itself is the contract.
- Deterministic data only: no real clock, no real network, no `rand` without a fixed seed.

## Repository Conformance Gate
- Run `oaef doctor` (native: `go run tool/governance.go doctor`).
- Run `oaef lint` (native: `go run tool/governance.go lint`).
- Run `oaef clean-code` (native: `go run tool/governance.go clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `go test ./...` passes with `-race` and `-count=1`.
- Every error branch of the touched code has a dedicated case.
- `go test ./... -coverprofile=coverage.out` produces an artifact for `collect-coverage`.

## Anti-Patterns
- A test asserting on an internal field instead of observable behaviour.
- A factory with ten parameters, half of them constant.
- A mock verifying an implementation detail rather than the contract.
- Flaky tests relying on real time, ordering or the network.
