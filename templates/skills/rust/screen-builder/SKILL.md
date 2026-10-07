---
name: screen-builder
description: >-
  Use when building or changing a screen, page, feature or user flow in Rust. Triggers on: "screen",
  "page", "feature", "flow", "view". Chains into: ui-preview, responsive-layout, test-generator.
  Constructs vertical feature slices in Rust inside the Clean Sizing bounds: state, presentation and
  routing arrive together, files stay under 300 lines, and the surface is previewable in isolation
  before integration.
argument-hint: "[screen or flow name]"
license: MIT
metadata:
  framework: OAEF
  stack: rust
  version: 1.1.0
---

# Feature Surface Builder (Rust)

> **Stack Profile:** Rust
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Build a feature surface as one vertical slice: the domain type, the use-case entrypoint and the
presentation adapter ship together, so a new flow is a self-contained module rather than a scatter of
edits across the crate.

## Territory
- `src/<feature>/domain/**` — entities, value types and the use-case trait.
- `src/<feature>/data/**` — repositories and external adapters.
- `src/<feature>/presentation/**` (or `src/cli/**`) — the surface that exposes the flow: a command
  handler, an HTTP route, a job entrypoint or a terminal command.
- `src/main.rs` — wiring; the slice is registered here.

## Construction Steps
1. Name the flow and its single responsibility; write it down before writing code.
2. Define the domain type and the use-case trait in `domain`; keep it free of I/O.
3. Implement data access behind the trait in `data`.
4. Build the presentation adapter that calls the use case and shapes the output.
5. Register the slice in the composition root; keep wiring out of the logic.
6. Add the preview harness (see `ui-preview`) and a test before integrating.

## State & Routing Contract
- State is an owned struct built at the composition root; the domain receives `&` references, never the
  global graph.
- Routing maps an external input (command name, path, message) to exactly one use-case call; unknown
  inputs return a typed error, never a silent fallthrough.
- No mutable global state; pass `Arc`/references explicitly through constructors.
- The slice exposes one public entrypoint; everything else stays `pub(crate)`.

## Repository Conformance Gate
- `cargo run --bin governance -- clean-code`
- `oaef lint`, `oaef doctor`
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The slice lives under one feature module, previewable and testable in isolation.
- State flows through constructors; routing has no silent fallthrough.

## Anti-Patterns
- A flow split across unrelated modules with hidden coupling.
- Presentation code calling a repository directly instead of the use case.
- Global mutable state used to pass context between layers.
- A feature file exceeding the 300-line Clean Sizing bound.
