---
name: ponytail
description: >-
  Use when adding, refactoring, simplifying or deleting code in Swift. Triggers on: "new", "refactor", "add", "simple", "minimal", "YAGNI", "dead code", "delete", "remove". Chains into: screen-builder, component-author, nullable-types, code-review. Governs the seven-rung Simplicity Ladder across every Swift source tree: it demands the smallest correct diff, forbids ceremonial layers and speculative abstraction, and routes every root cause to the single shared guard instead of per-call-site defensive branches.
argument-hint: "[mode: lite|full|ultra] [path]"
license: MIT
metadata:
  framework: OAEF
  stack: swift
  version: 1.1.0
---

# Ponytail Simplicity Ladder (Swift)

> **Stack Profile:** Swift
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** meta

## Mission
Enforce the seven-rung Simplicity Ladder before any Swift line is written. The best code is the code that did not have to be written; the deliverable is the smallest correct diff, not a scaffold for an imagined future.

## Territory
- `Sources/` — every production Swift target.
- `Sources/<Module>/{Domain,Data,Presentation}` — feature slice layers.
- `*.swift` at repository root.
- `Package.swift` and `Package.resolved` — only when a primitive truly does not exist.

## Modes
- `lite` — deletions, naming and comment cleanup; no structural change.
- `full` — default; refactors, feature work and dependency review.
- `ultra` — hot paths: no avoidable allocation, no copy, no intermediate collection.

## The N-Step Ladder
1. YAGNI — the requirement does not exist; do not write it.
2. Reuse in codebase — an existing type or modifier already does this.
3. Swift stdlib — `Array`/`Dictionary` pipelines, `Optional` chaining, `Result`, `Codable`, `async/await`.
4. Platform-native capability — SwiftUI modifiers, `ViewThatFits`, size classes, `@Observable`.
5. Already-installed dependency — a package already present in `Package.resolved`.
6. One-line idiomatic expression — a single modifier, `guard` or `map`.
7. Smallest correct diff — only then write new code.

## Root-Cause Bug Fixing
- Grep every call site of the failing symbol before editing anything.
- Place one guard at the shared root; never branch at each call site.
- Prove the fix with a regression test in `Tests/`.
- A per-call-site defensive branch is a finding, not a fix.

## Complexity Taxonomy
- Ceremonial layer: a one-line pass-through type with a single caller.
- Speculative abstraction: a protocol with one implementation and no test-double need.
- Dead weight: unreferenced type, unused parameter, commented-out code.
- Narration comment: a comment that restates the code.
- Every occurrence is tagged `[DELETE]`, `[STDLIB]`, `[NATIVE]`, `[YAGNI]` or `[SHRINK]`.

## // ponytail: Debt Markers
- Grammar: `// ponytail: <ceiling + evolution trigger>`.
- Example: `// ponytail: linear scan; switch to a Dictionary index above 100 rows`.
- Report-only; surfaced by `oaef ponytail debt` (native: `swift tool/governance.swift ponytail-debt`).
- Banned as a substitute for a fix that is already reachable.

## Safety Frontier
- Never pruned: validation, error routing, privacy, accessibility and Quality Gates.
- Deletion never removes a test that proves behavior.
- When two shapes are equivalent, choose the one with fewer types.

## Repository Conformance Gate
- `oaef doctor`
- `oaef lint`
- `oaef clean-code` (native: `swift tool/governance.swift clean-code`)
- `oaef ponytail debt` (native: `swift tool/governance.swift ponytail-debt`)
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The chosen rung is stated in the change description.
- No new type without a second concrete caller.
- `swiftlint` and `swift build` pass with the diff applied.

## Anti-Patterns
- A wrapper that forwards to another type without adding behavior.
- A protocol with one implementation and no mock requirement.
- `Array(` materialization inside a loop body on a hot path.
- Guard clauses duplicated at every call site instead of at the root.
- A comment that narrates `let value = value`.
