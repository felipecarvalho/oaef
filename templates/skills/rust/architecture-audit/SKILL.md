---
name: architecture-audit
description: >-
  Use when reviewing module boundaries, coupling or dependency direction in Rust. Triggers on:
  "architecture", "boundary", "coupling", "cycle". Chains into: conformance-audit, code-review. Audits
  layer boundaries, cyclic dependencies and Clean Sizing inside Rust: domain code never reaches outward,
  infrastructure never leaks inward, and every module keeps a single reason to change.
argument-hint: "[module path or boundary name]"
license: MIT
metadata:
  framework: OAEF
  stack: rust
  version: 1.1.0
---

# Architecture Audit (Rust)

> **Stack Profile:** Rust
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Keep dependency arrows pointing inward and modules small: `domain` defines traits, `data` and `infra`
implement them, and the composition root wires the graph.

## Territory
- `src/<feature>/domain/**` — pure logic; must not depend on `data`, `infra` or network crates.
- `src/<feature>/data/**` — persistence and transport adapters implementing domain traits.
- `src/<feature>/infra/**` — platform and process integration.
- `src/main.rs` — composition root; the only place allowed to select concrete implementations.

## Boundary Checklist
- Trait definitions live in `domain`; concrete implementors live in `data`/`infra`. Never the reverse.
- `domain` compiles with no dependency on a concrete client crate (`reqwest`, `hyper`, database drivers).
- Visibility is minimal: `pub(crate)` by default, `pub` only for the crate's declared API.
- No `use` from an outer layer inside an inner layer; check with a module dependency listing.
- One reason to change per module; a module that mixes parsing, persistence and transport is split.
- Cross-feature calls go through a published trait or an explicit event type, never through a reach-in.

## Sizing Bounds
- Files stay under 300 lines; functions stay under 50 lines; nesting stays under 3 levels.
- A module with more than one responsibility is split along the seam that changes independently.
- Clean Sizing violations are reported by `oaef audit`; treat them as blocking in the `strict` profile.

## Detection Commands
- List module edges: `cargo modules dependencies --all` when the helper is installed, otherwise parse
  `use crate::` lines with `rg -n 'use crate::' src`.
- Detect cycles: `cargo udeps` for dead code and a manual reverse-edge pass over `use` statements.
- Confirm layering: `rg -n 'reqwest|sqlx|hyper' src/*/domain` must return nothing.

## Repository Conformance Gate
- `cargo run --bin governance -- clean-code`
- `oaef doctor`, `oaef lint`
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- No dependency edge leaves `domain`, and no cycle exists between feature modules.
- Every file and function is inside the Clean Sizing bounds.

## Anti-Patterns
- `domain` importing a transport or storage crate to reuse a type.
- Glob re-exports (`pub use infra::*`) that leak implementation details upward.
- A `utils` module that becomes a shared sink for unrelated helpers.
- Feature-to-feature calls that bypass the declared trait boundary.
