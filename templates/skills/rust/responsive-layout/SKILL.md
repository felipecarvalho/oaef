---
name: responsive-layout
description: >-
  Use when a surface must adapt to another screen size, form factor or payload shape in Rust. Triggers
  on: "responsive", "adaptive", "breakpoint", "tablet", "foldable", "viewport". Chains into: ui-preview,
  test-generator. Owns adaptive design in Rust: breakpoints, safe areas, dynamic type and foldables for
  interactive surfaces, and payload shaping, pagination, content negotiation and streaming backpressure
  for headless ones.
argument-hint: "[breakpoint or surface name]"
license: MIT
metadata:
  framework: OAEF
  stack: rust
  version: 1.1.0
---

# Adaptive Surface Design (Rust)

> **Stack Profile:** Rust
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Rust is a headless stack: adaptivity means the surface reshapes its output and its data flow to the
consumer's capacity, not its pixel width. This skill owns payload shaping, pagination, content
negotiation and streaming backpressure.

## Territory
- `src/<feature>/presentation/**` — serialization and output shaping.
- `src/<feature>/domain` — pagination and streaming contracts.
- `src/<feature>/data` — transport adapters that enforce backpressure.
- `src/shared/**` — shared serialization and negotiation helpers.

## Adaptive Surface Design
Adapt the emission of a surface to the requesting consumer and to available resources:
- Choose the representation from the negotiated format (`Accept`/`Content-Type`) with a single typed
  enum, defaulting to one documented format.
- Size the response to the consumer: honor requested page sizes, cap them, and return a cursor for the
  next window instead of an unbounded payload.
- Degrade gracefully when resources are constrained: bound buffers, drop optional fields under pressure,
  and never grow an in-memory collection without a limit.
- Version the output schema explicitly; additive changes are backward compatible, breaking changes take
  a new version and a migration note.

## Payload Shaping
- Pagination uses an opaque cursor, not an offset that shifts under concurrent writes; encode the cursor
  as an owned value with `Serialize`/`Deserialize`.
- Streaming exposes `impl Iterator<Item = Result<T, E>>` or an async stream and applies backpressure: the
  producer waits for consumer demand instead of buffering everything.
- Shape payloads along the domain boundary: emit only the fields the consumer needs, and keep internal
  identifiers out of the wire type.
- Content negotiation and field selection are validated once at the boundary; downstream code receives a
  fully typed struct, never a loose map.
- Memory stays bounded: never collect an unbounded stream into a `Vec` on a hot path (`CC-11`).

## Repository Conformance Gate
- `cargo run --bin governance -- clean-code`
- `oaef lint`, `oaef doctor`
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every list endpoint is paginated with a bounded page size and a cursor contract.
- Every stream applies backpressure and holds bounded memory.

## Anti-Patterns
- Offset pagination over a mutating dataset.
- Collecting an unbounded stream into memory before responding.
- Ad-hoc field selection handled by stringly-typed maps.
- Breaking output changes shipped without a schema version bump.
