---
name: ponytail
description: >-
  Use when adding, refactoring, simplifying or deleting code in Universal / Polyglot. Triggers on: "new", "refactor", "add", "simple", "minimal", "YAGNI", "dead code", "delete", "remove". Chains into: screen-builder, component-author, nullable-types, code-review. Governs the seven-rung Simplicity Ladder across every Universal / Polyglot source tree: it demands the smallest correct diff, forbids ceremonial layers and speculative abstraction, and routes every root cause to the single shared guard instead of per-call-site defensive branches.
argument-hint: "[mode: lite|full|ultra] [path]"
license: MIT
metadata:
  framework: OAEF
  stack: universal
  version: 1.1.0
---

# Ponytail — Simplicity Ladder (Universal / Polyglot)

> **Stack Profile:** Universal / Polyglot
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)

> **Attribution:** the Simplicity Ladder is inspired by Dietrich Gebert's *Ponytail* minimalism (smallest correct diff, zero AI slop).
> **Skill Class:** meta

## Mission
Enforce the smallest correct diff in any embedded language of this repository, measured by the portable engine (`bash tool/governance.sh ponytail-debt`). The best code is the code you did not have to write.

## Territory
- Repository root over `.dart`, `.ts`, `.tsx`, `.js`, `.mjs`, `.cjs`, `.jsx`, `.py`, `.go`, `.rs`, `.kt`, `.kts`, `.swift`, `.cs`, `.sh`, `.bash`.
- `src/<package>/**`, `internal/<feature>/**`, `cmd/**`, `lib/**` when the embedded language imposes them.
- Test trees are out of scope for deletion: a test proves behavior, it is never dead weight.

## Modes
- `lite` — review-only; report findings, change nothing.
- `full` — default; apply the ladder to the edited files and report the ceiling.
- `ultra` — whole-workspace sweep; delete proven-dead code and elevate repeated shapes (Rule of Two).

## The N-Step Ladder
Climb in order and stop at the first rung that solves the problem:
1. **YAGNI** — does this code need to exist at all?
2. **Reuse in codebase** — does an equivalent helper already exist?
3. **Language/stdlib primitives** — `collections`, `itertools`, `pathlib`, `slices`, `maps`, `Option`/`Result`, `LINQ`, POSIX built-ins.
4. **Platform-native capability** — the runtime, filesystem or OS already provides it.
5. **Already-installed dependency** — no new manifest entry for a solved problem.
6. **One-line idiomatic expression** — a single expression over a hand-rolled block.
7. **Smallest correct diff** — otherwise, write only what must change.

## Root-Cause Bug Fixing
Grep every caller (`grep -rn` over the extension set) before patching a symptom. One guard in the shared root replaces N defensive branches at N call sites. A per-call-site patch that leaves the shared defect is a rejected diff.

## Complexity Taxonomy
- **Ceremonial layer** — a one-line pass-through use case or wrapper with no policy.
- **Speculative abstraction** — a single-implementation interface with no mock or second consumer need.
- **Narration comment** — a comment restating the next line of code.
- All three are deleted, not documented.

## // ponytail: Debt Markers
Declare a deliberate ceiling with its evolution trigger, introduced by the comment syntax of the surrounding file (`//`, `#`, `--`, `/*`, `<!--`):

```text
# ponytail: in-memory cache, move to persistent storage once writes exceed 10k/day
```

`bash tool/governance.sh ponytail-debt` lists every marker with `file:line` and reason (`PT-01`, report-only).

## Safety Frontier
Validation, error routing, privacy, accessibility and Quality Gates are never pruned. When the ladder and a gate conflict, the gate wins.

## Repository Conformance Gate
- `oaef doctor` and `oaef lint` clean for the touched repository.
- `oaef clean-code` (native: `bash tool/governance.sh clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `oaef ponytail debt` lists only markers whose ceiling and trigger are both stated.
- No new ceremonial layer, speculative abstraction or narration comment survives review.
- The diff is the smallest change that makes the contract hold.

## Anti-Patterns
- Adding a helper that wraps a single stdlib call.
- Fixing a bug at the call site while the shared root stays broken.
- Deleting a valid test to shrink a diff.
