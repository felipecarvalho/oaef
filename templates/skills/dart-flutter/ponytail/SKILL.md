---
name: ponytail
description: >-
  Use when adding, refactoring, simplifying or deleting code in Dart & Flutter. Triggers on: "new", "refactor", "add", "simple", "minimal", "YAGNI", "dead code", "delete", "remove".
  Chains into: screen-builder, component-author, nullable-types, code-review. Governs the seven-rung Simplicity Ladder across every Dart & Flutter source tree: it demands the smallest correct diff, forbids ceremonial layers and speculative abstraction, and routes every root cause to the single shared guard instead of per-call-site defensive branches.
argument-hint: "[mode: lite|full|ultra] [path]"
license: MIT
metadata:
  framework: OAEF
  stack: dart-flutter
  version: 1.1.0
---

# Ponytail (Dart & Flutter)

> **Stack Profile:** Dart & Flutter
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)

> **Attribution:** the Simplicity Ladder is inspired by Dietrich Gebert's *Ponytail* minimalism (smallest correct diff, zero AI slop).
> **Skill Class:** meta

## Mission
Enforce the smallest correct diff on every Dart and Flutter source tree. This skill is the mandatory meta-skill of every dispatch recipe: it runs before construction, remediation and review, and it prunes speculative abstraction, ceremonial layers and narration while preserving the safety frontier intact.

## Territory
- `lib/**` — all production Dart sources; the ladder applies to every file.
- `lib/features/<feature>/{presentation,domain,data}/**` — vertical slices, the usual home of one-line pass-through layers.
- `lib/shared/**`, `lib/ui/**` — shared widgets and tokens; reuse candidates live here.
- `lib/di/**`, `lib/main.dart` — composition root; the only place a container token is tolerated.
- `test/**`, `test/features/<feature>/**` — test code follows the ladder too (DRY factories, no dead parameters).
- `pubspec.yaml` — rung 5 decisions (already-installed dependency) are read here.

## Modes
- `lite` — deletions and single-file simplifications. No cross-module sweep.
- `full` — default. Applies all seven rungs, the complexity taxonomy and debt markers across the touched slice.
- `ultra` — full plus a repository-wide `oaef ponytail audit` sweep over `lib/**`.

## The N-Step Ladder
Climb in order; stop at the first rung that satisfies the requirement.
1. **YAGNI** — the requirement does not exist yet, so the code does not exist. Delete first.
2. **Reuse in codebase** — search `lib/shared/`, `lib/ui/` and the feature slice before writing a new widget or helper.
3. **Language / stdlib primitives** — `dart:core` collections, `Iterable` pipelines (`where`, `map`, `fold`), records, pattern matching and `switch` expressions, `StringBuffer`, extension methods, `const` constructors.
4. **Platform-native capability** — Flutter widgets and framework APIs already available: `LayoutBuilder`, `MediaQuery.sizeOf`, `ThemeData`, `SliverList`, `AnimatedBuilder`.
5. **Already-installed dependency** — a package already in `pubspec.yaml` that solves the problem without new surface area.
6. **One-line idiomatic expression** — a single expression beats a named helper that wraps it.
7. **Smallest correct diff** — the literal minimum edit inside the correct file.

## Root-Cause Bug Fixing
Grep every caller before patching one call site: `grep -rn "targetSymbol(" lib/`. A defect that repeats across call sites has one shared root; fix the guard at the root (the shared function, the parser, the repository) and let every caller inherit it. Per-call-site defensive branches are a ladder violation and are flagged as `[SHRINK]`.

## Complexity Taxonomy
- **Ceremonial layer** — a one-line use case, view model or repository that only forwards to the next layer. Tag `[DELETE]` when no policy lives in it.
- **Single-implementation interface** — an abstract class with one implementer and no mock or substitution need. Tag `[YAGNI]`.
- **Speculative abstraction** — a generic utility authored for an imagined second caller. Tag `[YAGNI]`; reopen under the Rule of Two.
- **Reimplementation of a primitive** — hand-rolled code replaced by a `dart:core` or framework primitive. Tag `[STDLIB]` or `[NATIVE]`.
- **Narration comment** — a comment restating the next line. Tag `[DELETE]`.

## // ponytail: Debt Markers
Declare the ceiling of a deliberate simplification together with the event that must reopen it:

```dart
// ponytail: in-memory session cache, move to persistent storage once writes exceed 10k/day
```

Grammar is `ponytail: <ceiling + evolution trigger>`; markers are report-only and surfaced by `oaef ponytail debt` (`PT-01`).

## Safety Frontier
Never pruned by the ladder: input validation, error routing and exception discipline (`CC-06`), privacy and consent (`CC-04`), accessibility, and every Quality Gate. Simplification stops at the boundary of correctness.

## Repository Conformance Gate
- `oaef doctor` — structural, skill and entrypoint conformance.
- `oaef lint` — `CC-*` advisory sweep plus `SK-01`…`SK-06` and secret detection.
- `oaef clean-code` (native: `dart run tool/governance.dart clean-code`) — blocking under the `strict` profile.
- `oaef ponytail debt` (native: `dart run tool/governance.dart ponytail-debt`) — report every marker.
- Unresolved findings are recorded in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every touched file sits at the lowest rung that satisfies the requirement.
- No decorative layer, single-implementation interface or speculative utility remains in the diff.
- Root causes are fixed once, at the shared guard, and proven by a test.
- Remaining simplifications carry a `// ponytail:` marker or are removed outright.

## Anti-Patterns
- Writing a new helper before searching `lib/shared/` and the feature slice.
- Wrapping a framework primitive (a `SliverList`, a `switch` expression) in bespoke code.
- Adding a parameter "for future use" that no caller reads.
- Patching symptoms with per-call-site null checks instead of the shared root guard.
- Leaving commented-out code or narration comments in the diff.
