---
name: screen-builder
description: >-
  Use when building or changing a screen, page, feature or user flow in Go. Triggers on: "screen", "page", "feature", "flow", "view". Chains into: ui-preview, responsive-layout, test-generator. Constructs vertical feature slices in Go inside the Clean Sizing bounds: state, presentation and routing arrive together, files stay under 300 lines, and the surface is previewable in isolation before integration.
argument-hint: "[screen or flow name]"
license: MIT
metadata:
  framework: OAEF
  stack: go
  version: 1.1.0
---

# Screen Builder (Go)

> **Stack Profile:** Go
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Deliver a complete vertical slice for a feature, page or flow: domain type, port, adapter and transport endpoint arrive together, wired at the composition root.

## Territory
- `internal/<feature>/domain/` — the feature's types and rules.
- `internal/<feature>/data/` — persistence adapter for the slice.
- `internal/<feature>/http/` — request decoding, handler, response encoding.
- `cmd/**/main.go` — the slice's composition and route registration.
- `internal/<feature>/*_test.go` — the slice's tests.

## Construction Steps
1. Define the domain type and its invariants in `domain`; no transport or driver imports.
2. Declare the consumer-owned interface the slice needs (`type Store interface { Get(ctx context.Context, id string) (Item, error) }`).
3. Implement the adapter in `data`, returning typed errors (`errors.Is`/`errors.As` friendly).
4. Implement the transport handler in `http`: decode, call the port, map errors to status codes, encode the response.
5. Register the route in `cmd/**/main.go`; construct the concrete store there only.
6. Run `gofmt -l .` and `go vet ./...` before declaring the slice complete.

A feature is one vertical slice, not a horizontal layer. Ship the smallest slice that serves the flow.

## State & Routing Contract
- Handlers are stateless: all mutable state lives behind the injected port.
- Routing is explicit in the composition root, using the standard library mux (`http.NewServeMux`, `mux.HandleFunc`) unless a router is already installed.
- Every handler carries a `context.Context` and forwards it to the port; deadlines and cancellation propagate outward.
- Errors are translated once, at the transport boundary; the handler never leaks a driver error to the caller.

## Repository Conformance Gate
- Run `oaef doctor` (native: `go run tool/governance.go doctor`).
- Run `oaef lint` (native: `go run tool/governance.go lint`).
- Run `oaef clean-code` (native: `go run tool/governance.go clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The slice builds and its handler is reachable through a registered route.
- Files stay under 300 lines and functions under 50 lines.
- A preview harness (`ui-preview`) renders the slice's output before integration.

## Anti-Patterns
- A feature implemented as a horizontal layer across many packages.
- A handler that reaches into a package-level global store.
- Duplicated decode/encode logic that belongs in one helper.
- Wiring the concrete adapter outside `cmd/**/main.go`.
