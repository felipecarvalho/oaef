---
name: responsive-layout
description: >-
  Use when a surface must adapt to another screen size, form factor or payload shape in Python 3. Triggers on: "responsive", "adaptive", "breakpoint", "tablet", "foldable", "viewport". Chains into: ui-preview, test-generator. Owns adaptive design in Python 3: breakpoints, safe areas, dynamic type and foldables for interactive surfaces, and payload shaping, pagination, content negotiation and streaming backpressure for headless ones.
argument-hint: "[breakpoint or surface name]"
license: MIT
metadata:
  framework: OAEF
  stack: python
  version: 1.1.0
---

# Adaptive Surface Design (Python 3)

> **Stack Profile:** Python 3
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Make every surface adapt to its consumer. This is a headless stack: adaptation means
shaping the payload, the page size and the transport to the client and the workload, not
reading a viewport or a device class.

## Territory
- `<package>/features/<feature>/presentation/` — content negotiation and serialization.
- `<package>/features/<feature>/domain/` — query contracts and cursor models.
- `src/<package>/shared/` — pagination, streaming and versioning helpers.
- `tests/features/<feature>/` — payload-shape and backpressure tests.

## Adaptive Surface Design
- Treat the caller as the unknown: negotiate representation from the `Accept` header and
  default to a documented media type when the header is absent or unsupported.
- Keep response models versioned; never mutate a published schema in place.
- Shape the payload to the requested projection: allow field selection instead of always
  returning the full aggregate.
- Enforce a maximum payload size; reject or paginate oversized result sets.
- Degrade gracefully: if an optional expansion cannot be served, return the base document
  with an explicit partial marker rather than failing the whole request.
- Bound every external call with a timeout and a retry budget; surface the deadline to callers.

## Payload Shaping
- Pagination is cursor-based: opaque cursors encode the last stable key, never an offset
  that shifts under concurrent writes. Return `next_cursor` and an explicit `has_more`.
- Cap page size with a named constant; clamp a client-supplied size to the cap.
- Content negotiation is table-driven: media type to serializer, with one default and a
  documented `406`-equivalent error for unsupported types.
- Schema versioning is additive: new optional fields first, deprecations announced and
  removed only on a major version. Validate the request version explicitly.
- Streaming uses generators or async iterators; apply backpressure by yielding in bounded
  chunks and honoring client disconnect signals (`aiohttp` cancellation, generator close).
- Never buffer an unbounded result set in memory to shape it; transform lazily.
- Emit pagination and payload-size metrics through the logging interface, never `print`.

## Repository Conformance Gate
- `oaef doctor` — structural conformance.
- `oaef lint` — governance findings.
- `oaef clean-code` (native: `python3 tool/governance.py clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every list endpoint is cursor-paginated with a capped page size.
- Every representation is versioned and negotiated from `Accept`.
- Streaming endpoints apply bounded chunks and respond to client disconnects.

## Anti-Patterns
- Offset pagination over a table with concurrent writes.
- Returning the full aggregate when the client requests a small projection.
- Buffering an entire result set before serializing it.
- Adding a required field to a published schema without a version bump.
- Ignoring the `Accept` header and always emitting the default format.
