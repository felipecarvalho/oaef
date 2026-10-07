---
name: responsive-layout
description: >-
  Use when a surface must adapt to another screen size, form factor or payload shape in Universal / Polyglot. Triggers on: "responsive", "adaptive", "breakpoint", "tablet", "foldable", "viewport". Chains into: ui-preview, test-generator. Owns adaptive design in Universal / Polyglot: breakpoints, safe areas, dynamic type and foldables for interactive surfaces, and payload shaping, pagination, content negotiation and streaming backpressure for headless ones.
argument-hint: "[breakpoint or surface name]"
license: MIT
metadata:
  framework: OAEF
  stack: universal
  version: 1.1.0
---

# Responsive Layout & Adaptive Surface Design (Universal / Polyglot)

> **Stack Profile:** Universal / Polyglot
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Make every surface adapt without breaking: interactive surfaces react to viewport and form factor, headless surfaces react to payload and transport constraints. Guidance is labelled per language family so the reader picks the correct column.

## Territory
- Interactive UI sources: `.tsx`, `.jsx`, `.swift`, `.kt`, `.dart` under `src/`, `app/`, `Sources/`, `lib/`.
- Headless sources: `.py`, `.go`, `.rs`, `.mjs`, `.cjs`, `.sh`, `.bash` under `src/`, `internal/`, `cmd/`, repository root.
- Shared configuration: theme/token files, schema definitions and OpenAPI documents.

## Adaptive Surface Design

### Interactive family (`.tsx`, `.jsx`, `.swift`, `.kt`, `.dart`)
- Breakpoints follow the design tokens, never ad-hoc pixel literals.
- Safe areas, dynamic type and foldable postures are respected, not assumed.

### Headless family (`.py`, `.go`, `.rs`, `.mjs`, `.sh`)
- Payload shaping: return only the fields the consumer needs; no over-fetching.
- Pagination: cursor-based, stable under concurrent writes.
- Content negotiation: honor `Accept`/`Content-Type` instead of assuming JSON.
- Schema versioning: additive changes only; a breaking change is a new version.
- Streaming and backpressure: bound the buffer, apply deadlines, never unbounded accumulate.

### Mixed repositories
A `.tsx` view consuming a `.py` endpoint applies both columns: breakpoint strategy for the view, payload shaping for the response it renders.

## Breakpoint Strategy
- Define named breakpoints once in a shared token module and import them everywhere.
- Every layout has a compact, medium and expanded state; the compact state is the floor.
- Test each state by resizing a preview harness (`ui-preview`), not by eyeballing a device.

## Payload Shaping
- One serialization boundary per service; the domain model never leaks wire shape.
- Optional fields default to a constant empty collection or explicit absent marker, never `null` in transit.
- Backpressure is mandatory on any stream whose producer can outpace the consumer.

## Repository Conformance Gate
- `oaef doctor` and `oaef lint` clean for the touched repository.
- `oaef clean-code` (native: `bash tool/governance.sh clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every interactive surface renders in all declared breakpoints without overflow.
- Every headless surface documents its pagination, negotiation and backpressure contract.
- No raw pixel literal or unversioned schema change reaches review.

## Anti-Patterns
- Hardcoding a single viewport width into a layout constant.
- Unbounded response lists returned to a client.
- Inventing a breakpoint locally instead of using the shared token.
