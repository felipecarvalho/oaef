---
name: component-author
description: >-
  Use when authoring or extracting a reusable component, widget, button, card or modal in Rust.
  Triggers on: "component", "widget", "button", "card", "modal". Chains into: ui-preview,
  responsive-layout, test-generator. Authors reusable Rust surfaces from design-system tokens: one
  responsibility per component, tokens instead of literals, and a contract that serves every consumer
  without a bespoke variant.
argument-hint: "[component name]"
license: MIT
metadata:
  framework: OAEF
  stack: rust
  version: 1.1.0
---

# Reusable Component Authoring (Rust)

> **Stack Profile:** Rust
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Author a reusable unit of behavior, the Rust reading of a component: a small module or crate with one
responsibility, a narrow public API and configuration supplied by typed values instead of literals.

## Territory
- `src/shared/**` — cross-feature reusable modules.
- `src/components/**` — standalone reusable units with their own tests.
- `src/<feature>/domain` — the value types a component consumes.
- `tests/` — integration tests per component contract.

## Component Contract
- One responsibility per module; the public API is the smallest set of functions and types a consumer
  needs, everything else `pub(crate)`.
- Inputs arrive as borrowed references or owned values through a constructor; no global lookups.
- Configuration is passed in as a typed struct with `Default`, never read from ambient state.
- Errors are part of the contract: return `Result<T, E>` with an error enum, not a panic.
- The contract serves every consumer without a bespoke variant; a second caller must not require a fork.
- Derive the traits consumers need (`Debug`, `Clone`, `PartialEq`), and nothing speculative.

## Token Discipline
- Design tokens are named constants, newtypes or a configuration struct; a literal color, size or
  duration embedded in logic is a finding.
- Centralize tokens in one module and reference them by name so a change happens once.
- Prefer a newtype (`struct Milliseconds(u64)`) over a bare primitive when a value has a unit or domain
  meaning; this prevents argument swaps at the call site.
- Keep `const` where a value is fixed at compile time; use configuration only for values that vary per
  deployment.

## Repository Conformance Gate
- `cargo run --bin governance -- clean-code`
- `oaef lint`, `oaef doctor`
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The module has one responsibility and a documented public API.
- No literal token values in logic; every unit-bearing value is typed.

## Anti-Patterns
- A generic component with one caller and a config knobs surface nobody uses.
- Booleans as configuration flags that multiply into incompatible variants.
- Panicking on invalid input instead of returning a typed error.
- Tokens copied inline across modules so a change must be repeated.
