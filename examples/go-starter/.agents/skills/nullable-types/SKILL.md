---
name: nullable-types
description: >-
  Use when a value can be absent, nil, null or optional in Go. Triggers on: "null", "optional", "nil", "guard clause", "defensive". Chains into: test-generator, run-static-analysis. Owns defensive null handling and non-nullable collection defaults in Go: absence carries business meaning, guard clauses return early instead of nesting, and a collection parameter defaults to a constant empty collection rather than an optional list.
argument-hint: "[path or type name]"
license: MIT
metadata:
  framework: OAEF
  stack: go
  version: 1.1.0
---

# Nullable Types (Go)

> **Stack Profile:** Go
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Keep `nil` meaningful in Go. A pointer, slice, map or interface is nil only because absence is a domain fact, never because a zero value was convenient.

## Territory
- `internal/<feature>/domain/` — value types and business invariants.
- `internal/<feature>/data/` — repository results and scan targets.
- `internal/<feature>/http/` — request decoding and response shaping.
- `*.go` at the repository root — shared helpers.

## Conventions
- Represent absence with an explicit type: `(T, bool)` from a lookup, or `(T, error)` from a fetch. Reserve bare `*T` for genuinely optional fields such as the distinct zero value of a numeric field.
- Never return a nil `*T` where an error already communicates failure; return the zero value plus the error.
- Prefer a small `Result`-style struct with an `ok` field over an interface that may hold a typed nil.
- Document nil-safety in the doc comment of any exported function that accepts a slice, map or interface: the Go type system cannot express a non-null collection default (`CC-08` is a documented no-op here).
- Bind `err` immediately and return; never store a nil error as a sentinel.

## Non-Nullable Collections
A `[]T`, `map[K]V` or channel parameter must be documented as nil-safe in its doc comment, and a nil collection must be handled as an empty collection:
```go
// Lookup returns the sessions for id; a nil result is treated as empty.
func Lookup(id string) ([]Session, error) { … }
```
Return `nil` for an empty result and iterate safely; never require the caller to construct an empty slice as a guard.

## Guard Clauses
- Return early on absence; do not nest the happy path inside an `if present { … }`.
- One guard per precondition, each on its own line.
- Reject the invalid case with a typed error, not a nil propagation:
```go
if session == nil {
    return nil, ErrSessionNotFound
}
```
- Never swallow the absent case with `_ = value`; route it to an error or a log.

## Repository Conformance Gate
- Run `oaef doctor` (native: `go run tool/governance.go doctor`).
- Run `oaef lint` (native: `go run tool/governance.go lint`).
- Run `oaef clean-code` (native: `go run tool/governance.go clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every nil check maps to a business meaning or an error path.
- Exported collection parameters carry a nil-safe doc comment.
- `go vet ./...` reports no nil-related diagnostics.

## Anti-Patterns
- `if x != nil { if y != nil { … } }` where two guard clauses would read better.
- Returning `interface{}` to express "maybe absent".
- A nil map write that panics at runtime.
- Using a pointer solely to distinguish zero from absent without documenting it.
