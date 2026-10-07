---
name: ponytail
description: >-
  Use when adding, refactoring, simplifying or deleting code in Rust. Triggers on: "new", "refactor",
  "add", "simple", "minimal", "YAGNI", "dead code", "delete", "remove". Chains into: screen-builder,
  component-author, nullable-types, code-review. Governs the seven-rung Simplicity Ladder across every
  Rust source tree: it demands the smallest correct diff, forbids ceremonial layers and speculative
  abstraction, and routes every root cause to the single shared guard instead of per-call-site
  defensive branches.
argument-hint: "[mode: lite|full|ultra] [path]"
license: MIT
metadata:
  framework: OAEF
  stack: rust
  version: 1.1.0
---

# Ponytail Simplicity Ladder (Rust)

> **Stack Profile:** Rust
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)

> **Attribution:** the Simplicity Ladder is inspired by Dietrich Gebert's *Ponytail* minimalism (smallest correct diff, zero AI slop).
> **Skill Class:** meta

## Mission
Enforce the smallest correct change in every Rust crate: the best code is the code you did not have to
write. This is the meta-skill of every recipe; it runs before and across all other skills.

## Territory
- `src/**/*.rs` — every production module.
- `src/<feature>/{domain,data,infra}` — vertical slices where narrow types and traits live.
- `src/main.rs` — composition root; wiring belongs here and nowhere else.
- `Cargo.toml` — dependency ledger; adding a crate is the last resort.

## Modes
- `lite` — review-only: annotate findings, change nothing.
- `full` (default) — climb the ladder and apply the smallest correct edit.
- `ultra` — aggressive deletion: remove dead modules, one-caller abstractions and narration comments.

## The N-Step Ladder
Climb in order; stop at the first rung that solves the task.
1. YAGNI — the requirement does not exist yet, so write nothing.
2. Reuse inside the crate — an existing function, trait or module already solves it.
3. Language stdlib primitives — `Option`/`Result`, iterators, `Cow`, `slice::from_ref`, `Default`, `From`.
4. Platform-native capability — ownership, zero-copy `&str`/`&[T]`, `Path`, `mem::take`, `matches!`.
5. Already-installed crate — a dependency already present in `Cargo.toml` covers the need.
6. One-line idiomatic expression — `?`, `filter_map`, `entry().or_default()`, `#[derive(Default)]`.
7. Smallest correct diff — only then write new code.

## Root-Cause Bug Fixing
- Grep every caller (`rg -n '<fn_name>' src`) before touching a symptom.
- Fix the shared root: one guard or one validation in the owning function, not a defensive branch per
  call site.
- Add a regression test under `#[cfg(test)]` or `tests/` that fails before and passes after.
- Never silence a compiler or Clippy diagnostic to make the symptom disappear.

## Complexity Taxonomy
- `[DELETE]` — dead module, unused `pub fn`, unreachable match arm.
- `[STDLIB]` — hand-rolled loop or helper that `Option`/`Result`/iterators already provide.
- `[NATIVE]` — manual buffer or copy that ownership and borrowing solve.
- `[YAGNI]` — speculative trait, generic or configuration with a single caller.
- `[SHRINK]` — a chain of statements that reduces to one idiomatic expression.

## // ponytail: Debt Markers
Declare a deliberate ceiling together with the trigger that must reopen the decision, using Rust
comment syntax:
```rust
// ponytail: in-memory cache, move to persistent storage once writes exceed 10k/day
```
Reported by `oaef ponytail debt` (`PT-01`); `oaef ponytail audit` adds the advisory tag sweep.

## Safety Frontier
Never prune input validation, error routing, contextual logging, privacy redaction, accessibility or
the governance gates. Pruning a safety check is a defect, not a simplification.

## Repository Conformance Gate
- `cargo run --bin governance -- clean-code`
- `oaef doctor`
- `oaef lint`
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The diff is the smallest that satisfies the demand; no speculative API surface was added.
- Every remaining simplification ceiling carries a `// ponytail:` marker.

## Anti-Patterns
- One-line pass-through functions and single-implementation traits with no mock need.
- Narration comments that restate the next statement.
- Adding a crate for something the stdlib already provides.
- Copying a whole structure when a borrow would do.
