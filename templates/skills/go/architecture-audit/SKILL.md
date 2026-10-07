---
name: architecture-audit
description: >-
  Use when reviewing module boundaries, coupling or dependency direction in Go. Triggers on: "architecture", "boundary", "coupling", "cycle". Chains into: conformance-audit, code-review. Audits layer boundaries, cyclic dependencies and Clean Sizing inside Go: domain code never reaches outward, infrastructure never leaks inward, and every module keeps a single reason to change.
argument-hint: "[module path or boundary name]"
license: MIT
metadata:
  framework: OAEF
  stack: go
  version: 1.1.0
---

# Architecture Audit (Go)

> **Stack Profile:** Go
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Keep Go package boundaries honest. Dependencies point inward to the domain; no import cycle survives; every package has one reason to change.

## Territory
- `internal/<feature>/domain/` — pure business types and rules.
- `internal/<feature>/data/` — repository implementations.
- `internal/<feature>/http/` — transport handlers.
- `internal/` — shared internal packages.
- `cmd/**/main.go` — the only place that wires everything.

## Boundary Checklist
- Direction: `cmd` → `http`/`data` → `domain`. The `domain` package imports neither `data`, `http` nor a network driver.
- Cycles: `go vet ./...` plus a graph check; Go forbids import cycles at compile time, so a cycle is a hard build failure, not a warning.
- Interface ownership: the consumer defines the interface it needs (`type SessionReader interface { … }`), not the producer.
- Composition root: concrete clients and containers are constructed only in `cmd/**/main.go`; the service-locator and concrete-client checks (`CC-07`, `CC-10`) are documented no-ops in Go and degrade to this review guidance.
- Shared surface: `internal/` prevents external import; a package that must be public earns it explicitly.

## Sizing Bounds
- Zero files over 300 lines; split by concern, not by size alone.
- Zero functions over 50 lines; extract a named helper.
- One package per reason to change; a package mixing transport and domain fails the audit.
- Keep exported surface minimal: unexported by default, exported only for a real external consumer.

## Repository Conformance Gate
- Run `oaef doctor` (native: `go run tool/governance.go doctor`).
- Run `oaef lint` (native: `go run tool/governance.go lint`).
- Run `oaef clean-code` (native: `go run tool/governance.go clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `go vet ./...` and the import graph report no cycle or unwanted edge.
- `domain` imports only stdlib and other `domain` packages.
- Clean Sizing floors hold (300/50) across the audited subtree.

## Anti-Patterns
- A producer-owned interface that exists only to be implemented once.
- Domain code importing a driver or a transport package.
- A `utils` package that every layer reaches into.
- Passing `*sql.DB` into the domain layer.
