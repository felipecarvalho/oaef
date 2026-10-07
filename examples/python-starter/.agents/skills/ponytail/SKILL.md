---
name: ponytail
description: >-
  Use when adding, refactoring, simplifying or deleting code in Python 3. Triggers on: "new", "refactor", "add", "simple", "minimal", "YAGNI", "dead code", "delete", "remove". Chains into: screen-builder, component-author, nullable-types, code-review. Governs the seven-rung Simplicity Ladder across every Python 3 source tree: it demands the smallest correct diff, forbids ceremonial layers and speculative abstraction, and routes every root cause to the single shared guard instead of per-call-site defensive branches.
argument-hint: "[mode: lite|full|ultra] [path]"
license: MIT
metadata:
  framework: OAEF
  stack: python
  version: 1.1.0
---

# Ponytail Simplicity Ladder (Python 3)

> **Stack Profile:** Python 3
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** meta

## Mission
Deliver the smallest correct diff that satisfies the demand. Every rung climbed removes
code that would otherwise be written, reviewed and maintained. Applied before any other
skill in the recipe chain.

## Territory
- Repository root — module and package layouts.
- `src/<package>/` — production modules.
- `<package>/features/<feature>/{presentation,domain,data}` — vertical slices.
- `tests/`, `test_*.py` — test facilities (factories, fakes, fixtures).

## Modes
- `lite` — single function or module; inspect the immediate callers before editing.
- `full` — feature slice or package; inspect every caller tree-wide before editing.
- `ultra` — repository-wide refactor; grep for duplicated patterns and delete them.

Declare the mode in the working note. An undeclared mode defaults to `full`.

## The N-Step Ladder
Climb in order and stop at the first rung that satisfies the requirement.
1. YAGNI — the capability is not needed yet; write nothing.
2. Reuse in codebase — an existing module, helper or dataclass already does this.
3. Language/stdlib primitives — `dataclasses`, `functools.cache`, `functools.partial`,
   `itertools`, `pathlib`, `collections` (`defaultdict`, `Counter`), `enum`,
   structural pattern matching and `contextlib` before any third-party package.
4. Platform-native capability — the runtime, the standard library or an installed
   dependency already exposes the behavior; do not wrap it.
5. Already-installed dependency — a package present in `pyproject.toml` is fair game;
   adding a new one is not.
6. One-line idiomatic expression — a comprehension, `match` statement or ternary beats
   a helper function.
7. Smallest correct diff — only then write new code, touching the fewest lines possible.

## Root-Cause Bug Fixing
- `grep -rn` every caller of the failing function before editing it.
- Fix the single shared root cause so all call sites inherit the correction.
- Never add a defensive branch at one call site while the shared path stays broken.

## Complexity Taxonomy
- Ceremonial layer — a one-line pass-through function or a class wrapping a single call.
- Speculative abstraction — an interface or ABC with one implementation and no mock need.
- Dead parameter — a factory or function parameter no caller ever varies.
- Narration comment — a comment restating what the next line already says.
Every entry above is a deletion candidate; delete first, simplify second.

## // ponytail: Debt Markers
Record a deliberately accepted ceiling with an inline marker:
`# ponytail: <ceiling>; evolve when <trigger>`. One marker per accepted limit.
The markers are report-only: `oaef ponytail debt` lists every marker with its location,
and `oaef ponytail audit` reports markers whose trigger has already been met.

## Safety Frontier
Validation, error routing, privacy redaction, accessibility metadata and the Quality Gates
are never pruned. Simplification removes ceremony, not correctness.

## Repository Conformance Gate
- `oaef doctor` — structural conformance.
- `oaef lint` — governance findings.
- `oaef clean-code` (native: `python3 tool/governance.py clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The diff is the smallest that satisfies the demand and every caller was inspected.
- `ruff check .` and `mypy .` pass with zero new suppressions.
- No ceremonial layer, speculative abstraction or narration comment remains.

## Anti-Patterns
- `[DELETE]` keeping dead branches "for compatibility" with no caller.
- `[STDLIB]` hand-rolling what `dataclasses` or `functools` already solves.
- `[NATIVE]` wrapping a platform capability behind a single-implementation class.
- `[YAGNI]` building a configuration flag with one possible value.
- `[SHRINK]` copying a ten-line block instead of extracting one guard.
