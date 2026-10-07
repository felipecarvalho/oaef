---
name: ponytail
description: >-
  Use when adding, refactoring, simplifying or deleting code in React Native. Triggers on: "new", "refactor", "add", "simple", "minimal", "YAGNI", "dead code", "delete", "remove". Chains into: screen-builder, component-author, nullable-types, code-review. Governs the seven-rung Simplicity Ladder across every React Native source tree: it demands the smallest correct diff, forbids ceremonial layers and speculative abstraction, and routes every root cause to the single shared guard instead of per-call-site defensive branches.
argument-hint: "[mode: lite|full|ultra] [path]"
license: MIT
metadata:
  framework: OAEF
  stack: react-native
  version: 1.1.0
---

# Ponytail (React Native)

> **Stack Profile:** React Native
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)

> **Attribution:** the Simplicity Ladder is inspired by Dietrich Gebert's *Ponytail* minimalism (smallest correct diff, zero AI slop).
> **Skill Class:** meta

## Mission
Deliver the smallest correct diff for every React Native change. The best code is the code you did not have to write: prefer an existing hook, a TypeScript/JavaScript primitive or a platform capability over a new module. Zero tolerance for AI slop, narration comments and speculative abstraction.

## Territory
- `src/**/*.{ts,tsx}` — component, hook, service and module source.
- `app/**` — application shell, navigation and provider wiring.
- `src/features/<feature>/{presentation,domain,data}` — vertical feature slices.
- `src/components/`, `src/shared/` — reusable surfaces and design-system primitives.
- `__tests__/`, `src/**/*.test.tsx` — suites and doubles touched by the change.

## Modes
- `lite` — review-only pass; report ladder violations, change nothing.
- `full` — default; refactor the touched slice to the lowest viable rung.
- `ultra` — whole-repository sweep; collapse duplicated helpers and dead exports.

## The N-Step Ladder
Climb from the top; stop at the first rung that solves the problem.
1. **YAGNI** — delete the requirement that is not demanded yet.
2. **Reuse in codebase** — an existing hook, component or util in `src/shared/`.
3. **Language / stdlib primitives** — optional chaining, nullish coalescing, `Array.prototype` pipelines, `Object.groupBy`, `Intl`, `structuredClone`.
4. **Platform-native capability** — `FlatList` virtualization, `useMemo`/`useCallback`, `useWindowDimensions`, `Platform.select`, `PixelRatio`.
5. **Already-installed dependency** — a package present in `package.json`; never add one for a solved problem.
6. **One-line idiomatic expression** — inline the logic instead of a helper module.
7. **Smallest correct diff** — only then author new code.

## Root-Cause Bug Fixing
- `grep` every caller of the failing function before editing.
- Place the single guard in the shared root, not at each call site.
- A defensive branch repeated in two components is a ladder violation: hoist it.

## Complexity Taxonomy
- **Accidental** — ceremony, one-line pass-through hooks, single-implementation interfaces with no mock need: remove.
- **Essential** — real domain rules, error routing, accessibility: keep.
- **Speculative** — configurability exercised by one caller: delete until a second caller exists.

## // ponytail: Debt Markers
Leave an explicit marker where a deliberate ceiling was chosen:
`// ponytail: <ceiling> — evolve when <trigger>`
Tags: `[DELETE]`, `[STDLIB]`, `[NATIVE]`, `[YAGNI]`, `[SHRINK]`. Reported non-blocking by `oaef ponytail debt` (native: `node tool/governance.mjs ponytail-debt`).

## Safety Frontier
Never prune validation, error routing, privacy redaction, accessibility or any Quality Gate in the name of simplicity. These are essential complexity and stay.

## Repository Conformance Gate
- Run `oaef doctor` (native: `node tool/governance.mjs doctor`).
- Run `oaef lint` (native: `npx eslint .`).
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The diff is the smallest that satisfies the demand.
- No ceremonial layer, speculative option or narration comment remains.
- Every deliberate ceiling carries a `// ponytail:` marker.

## Anti-Patterns
- A one-line hook or use case that only forwards arguments.
- An abstraction introduced for a single caller.
- Copy-pasted guards instead of one shared root guard.
- Dead exports and unused props left behind.
