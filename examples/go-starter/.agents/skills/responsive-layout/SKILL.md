---
name: responsive-layout
description: >-
  Use when a surface must adapt to another screen size, form factor or payload shape in Go. Triggers on: "responsive", "adaptive", "breakpoint", "tablet", "foldable", "viewport". Chains into: ui-preview, test-generator. Owns adaptive design in Go: breakpoints, safe areas, dynamic type and foldables for interactive surfaces, and payload shaping, pagination, content negotiation and streaming backpressure for headless ones.
argument-hint: "[breakpoint or surface name]"
license: MIT
metadata:
  framework: OAEF
  stack: go
  version: 1.1.0
---

# Responsive Layout / Adaptive Surface Design (Go)

> **Stack Profile:** Go
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Make a Go service adapt to the shape of the request and the capacity of the consumer. Go is a headless stack: the adaptable surface is the response contract, not a viewport.

## Territory
- `internal/<feature>/http/` — request parsing, negotiation and response encoding.
- `internal/<feature>/data/` — pagination and stream access.
- `internal/<feature>/domain/` — schema and version types.
- `cmd/**/main.go` — server timeouts, limits and backpressure configuration.

## Adaptive Surface Design
An adaptive headless surface honours the caller's constraints instead of assuming one fixed shape:
- Shape the response to the requested representation: JSON by default, honour `Accept` and `Content-Type` when multiple encodings are offered.
- Clamp the response to the consumer's declared limits: page size, maximum items, byte budget and requested fields.
- Version the wire contract explicitly; never mutate a published field's meaning.
- Apply `context` deadlines on every outbound call; a slow dependency must not exhaust the caller's budget.
- Degrade gracefully: when an optional enrichment is unavailable, return the core payload rather than failing the whole request.

## Payload Shaping
- **Pagination** — use a stable cursor over an ordered key; return the next cursor and an explicit `has_more` flag. Avoid offset pagination on mutable data.
- **Field selection** — allow the caller to narrow the projection; do not serialise fields the caller did not request.
- **Content negotiation** — choose the encoder from `Accept`; fall back to the repository's declared default; reject an unsupported type with `406`.
- **Streaming** — delimit the stream rather than materialising the full result: `json.Encoder` over an `io.Writer`, `bufio.Scanner` on ingest, `io.Copy` for byte passthrough.
- **Backpressure** — bound concurrency with a buffered channel or a semaphore; the producer blocks or sheds instead of growing unbounded slices.
- **Limits as tokens** — page size, deadline and buffer size are named constants, never literals.

```go
const (
    defaultPageSize = 50
    maxPageSize     = 500
)
```

## Repository Conformance Gate
- Run `oaef doctor` (native: `go run tool/governance.go doctor`).
- Run `oaef lint` (native: `go run tool/governance.go lint`).
- Run `oaef clean-code` (native: `go run tool/governance.go clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every adaptive parameter (page size, deadline, encoding) has a named constant and a default.
- Pagination is cursor-stable under concurrent writes.
- A test proves the negotiated encoding and the clamp at the boundary values.

## Anti-Patterns
- Offset pagination over a mutable collection.
- Materialising an unbounded result set before streaming it.
- A hardcoded page size or timeout at the call site.
- Changing a published field's type without a version bump.
