---
name: ui-preview
description: >-
  Use when a component or screen must be inspected in isolation before it is wired into the application
  in Rust. Triggers on: "preview", "storybook", "isolated render". Chains into: test-generator,
  run-static-analysis. Provides isolated preview harnesses for Rust: loading, success, empty and error
  states are rendered without booting the full runtime, so layout, tokens and typography are validated
  before integration.
argument-hint: "[component or screen name]"
license: MIT
metadata:
  framework: OAEF
  stack: rust
  version: 1.1.0
---

# Isolated Preview Harness (Rust)

> **Stack Profile:** Rust
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Inspect a module or surface in isolation before it is wired into the application: a small `examples/`
binary or a `#[cfg(test)]` harness renders every state against fixtures and prints or snapshots the
result.

## Territory
- `examples/<surface>.rs` — a runnable preview binary per surface.
- `src/<feature>/presentation/**` — the code under preview.
- `tests/fixtures/**` — deterministic sample inputs.
- `tests/snapshots/**` — golden outputs for regression on the rendered surface.

## Preview Harness
- One `examples/<surface>.rs` per previewable surface; `cargo run --example <surface>` executes it.
- The harness constructs the surface with fake dependencies, never the production composition root.
- Render all required states: loading, success, empty and error; each state is a separate fixture.
- Fixtures are deterministic: fixed timestamps, fixed identifiers, no randomness or wall-clock reads.
- Capture output as a golden snapshot and compare; a diff is a deliberate review decision, not a silent
  overwrite.
- Keep previews out of the production binary: `examples/` and `#[cfg(test)]` only.

## Repository Conformance Gate
- `cargo run --bin governance -- clean-code`
- `oaef lint`, `oaef doctor`
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every surface has a runnable isolated preview covering all four states.
- Previews use fakes only and produce deterministic snapshots.

## Anti-Patterns
- A preview that boots the full runtime or hits the network.
- Non-deterministic fixtures (current time, random identifiers).
- Golden snapshots regenerated blindly to make a test pass.
- Preview code shipped inside the production build.
