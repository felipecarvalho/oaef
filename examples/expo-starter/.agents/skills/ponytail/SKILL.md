---
name: ponytail
description: >-
  Use when adding, refactoring, simplifying or deleting code in Expo. Triggers on: "new", "refactor", "add",
  "simple", "minimal", "YAGNI", "dead code", "delete", "remove". Chains into: screen-builder, component-author,
  nullable-types, code-review. Governs the seven-rung Simplicity Ladder across every Expo source tree: it demands
  the smallest correct diff, forbids ceremonial layers and speculative abstraction, and routes every root cause
  to the single shared guard instead of per-call-site defensive branches.
argument-hint: "[mode: lite|full|ultra] [path]"
license: MIT
metadata:
  framework: OAEF
  stack: expo
  version: 1.1.0
---

# Ponytail - Simplicity Ladder (Expo)

> **Stack Profile:** Expo
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)

> **Attribution:** the Simplicity Ladder is inspired by Dietrich Gebert's *Ponytail* minimalism (smallest correct diff, zero AI slop).
> **Skill Class:** meta

## Mission
Climb the Simplicity Ladder before writing any Expo line. The smallest correct diff wins; speculative abstraction and ceremonial layers are defects. Every root cause is fixed once in the shared guard, never patched per call site.

## Territory
- `app/` - Expo Router file-based routes; route files stay thin and delegate into `src/features/`.
- `src/features/<feature>/{presentation,domain,data}` - feature slices; domain stays free of React.
- `src/components/`, `src/shared/` - reusable surfaces and utilities.
- `**/*.ts`, `**/*.tsx` - every production TypeScript source under `app/` and `src/`.

## Modes
- `lite` - default; accept obvious simplifications and leave ambiguous code alone.
- `full` - question every rung, remove duplication and dead layers aggressively.
- `ultra` - keep nothing without a live caller and a test; delete first, rebuild only if proven necessary.

## The N-Step Ladder
1. **YAGNI** - delete the unrequested feature, flag, and config branch.
2. **Reuse in the codebase** - search `src/shared/` and `src/components/` before authoring a twin.
3. **TypeScript standard library** - `Array.prototype` pipelines, `Object.groupBy`, `Intl`, optional chaining and `??` over hand-rolled helpers.
4. **Platform-native capability** - Expo Router navigation, React Native primitives (`FlatList`, `Pressable`, `Modal`), and platform APIs reached through Expo modules already installed.
5. **Already-installed dependency** - `expo-router`, `expo-constants`, `expo-device`; adding a package for a solved problem is banned.
6. **One-line idiomatic expression** - the shortest expression that stays readable.
7. **Smallest correct diff** - touch only what must change; no drive-by refactors, renames, or file moves.

## Root-Cause Bug Fixing
Grep every caller before patching: `grep -rn "loadSession(" src app`. Fix the one shared guard or invariant and reject per-call-site defensive branches that repeat the same check.

## Complexity Taxonomy
- **Accidental** - ceremony, wrappers that only forward props, one-line pass-through hooks: `[DELETE]`.
- **Speculative** - single-implementation interfaces with no mock need, config for a case that never occurs: `[YAGNI]`.
- **Reimplemented** - custom code for a stdlib or platform primitive: `[STDLIB]` / `[NATIVE]`.
- **Duplicated** - the same block in two or more files: elevate per the Rule of Two.
- **Necessary** - irreducible domain complexity: keep, test, and document.

## // ponytail: Debt Markers
Declare every deliberate simplification on the spot with the canonical grammar:

```ts
// ponytail: in-memory session cache, move to persistent storage once writes exceed 10k/day
```

`oaef ponytail debt` (`node tool/governance.mjs ponytail-debt`) lists every marker with `file:line` and reason; `oaef ponytail audit` adds the advisory tag sweep. Markers are report-only and never blocking.

## Safety Frontier
Never pruned: input validation, error routing, privacy and consent, accessibility, and every Quality Gate. Simplicity never licenses an unsafe shortcut.

## Repository Conformance Gate
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`) and fix every blocking `CC-*` finding.
- Run `oaef lint` and `oaef doctor`; treat warnings as errors.
- Record unresolved findings and any accepted debt marker in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The change is the smallest diff that satisfies the real requirement.
- No `[DELETE]`, `[STDLIB]`, `[NATIVE]`, `[YAGNI]`, or `[SHRINK]` opportunity remains unaddressed.
- Each root cause is fixed once, with the grep evidence recorded in the pull request.

## Anti-Patterns
- Adding a dependency, helper, or layer for a problem the platform already solves.
- Fixing a symptom at each call site instead of the shared root.
- Leaving a wrapper that only forwards arguments or a narration comment that restates the next line.
