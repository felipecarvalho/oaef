---
name: ponytail
description: >-
  Use when adding, refactoring, simplifying or deleting code in TypeScript & Web. Triggers on: "new", "refactor", "add", "simple", "minimal", "YAGNI", "dead code", "delete", "remove". Chains into: screen-builder, component-author, nullable-types, code-review. Governs the seven-rung Simplicity Ladder across every TypeScript & Web source tree: it demands the smallest correct diff, forbids ceremonial layers and speculative abstraction, and routes every root cause to the single shared guard instead of per-call-site defensive branches.
argument-hint: "[mode: lite|full|ultra] [path]"
license: MIT
metadata:
  framework: OAEF
  stack: typescript-web
  version: 1.1.0
---

# Ponytail (TypeScript & Web)

> **Stack Profile:** TypeScript & Web
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** meta

## Mission

Reduce every change to its smallest correct diff. The best code is the code that did
not have to be written: prefer deleting, reusing and inlining before authoring a new
module, abstraction or dependency in the `src/` surface.

## Territory

- `src/**` — every production source file, whatever the framework.
- `src/features/<feature>/{presentation,domain,data}/` — vertical slices; the ladder applies per layer.
- `src/components/**`, `src/shared/**` — shared surfaces where duplication tempts new abstractions.
- `tool/governance.mjs` — the native governance entry the ladder must keep green.
- `src/**/*.spec.ts`, `test/**` — tests are subjects too: no dead factories or parameters.

## Modes

- **lite** — light touch. Flag only the obvious: dead branches, unused exports,
  commented-out blocks, single-use helpers that add no indirection.
- **full** — default. Climb the full ladder on every touched file, hunt duplication and
  speculative layers, apply the five deletion tags below.
- **ultra** — aggressive. Sweep the whole feature slice, collapse ceremony, challenge
  every new dependency and every abstraction with a single caller.

## The N-Step Ladder

Climb in order; stop at the first rung that satisfies the requirement:

1. **YAGNI** — does the requirement actually exist now? Not "might later".
2. **Reuse in codebase** — does `src/shared/`, `src/components/` or a sibling feature already solve this?
3. **Language / stdlib primitives** — `Array.prototype` pipelines, `Object.groupBy`,
   optional chaining `?.`, nullish coalescing `??`, `structuredClone`, records, `Map`/`Set`.
4. **Platform-native capability** — DOM and CSS before JavaScript: `clamp()`,
   `media (prefers-reduced-motion)`, `srcset`, `dialog`, `URL`, `Intl`, form validation,
   `IntersectionObserver`, `ResizeObserver`.
5. **Already-installed dependency** — reuse a package already in `package.json`, not a new one.
6. **One-line idiomatic expression** — one named expression beats a helper module with a single caller.
7. **Smallest correct diff** — only then write new code, and write as little as possible.

## Root-Cause Bug Fixing

- `grep -rn` every caller of the failing symbol before touching any of them.
- Fix at the single shared root: one guard clause in the shared function, not a defensive
  `if` at each call site.
- Never clip a symptom (`try` around a failing call, a fallback default that hides the
  bug, a `.filter(Boolean)` that silences a data-shape error).
- Add one regression test that fails before the fix and passes after.

## Complexity Taxonomy

Delete on sight: ceremonial intermediate layers (a `useCase` that only forwards);
interfaces with one implementation and no mock need; wrappers that rename a parameter;
narration comments restating the next line; state mirroring derived state; `useEffect`
chains that could be a computed value; a new dependency for a solved problem.

## // ponytail: Debt Markers

When a deliberate ceiling must stay, leave an explicit marker and an evolution trigger:

```ts
// ponytail: hardcoded page size; lift to config when a second consumer needs it.
```

Tags: `[DELETE]` remove entirely, `[STDLIB]` replace with a stdlib primitive,
`[NATIVE]` replace with a DOM/CSS platform capability, `[YAGNI]` do not build yet,
`[SHRINK]` keep the behaviour but reduce the diff. `oaef ponytail debt` lists every
marker with `file:line`; `oaef ponytail audit` is the report-only gate `PT-01`.

## Safety Frontier

The ladder never prunes validation at trust boundaries, error routing, privacy and PII
handling, accessibility affordances, or any Quality Gate. Those are requirements, not
slop.

## Repository Conformance Gate

- Run `oaef doctor`, `oaef lint`, `oaef clean-code` (native:
  `node tool/governance.mjs doctor|lint|clean-code`).
- Run `oaef ponytail debt` and confirm every marker carries a reason.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria

- Every touched file is smaller or equal in surface, never larger without justification.
- No dead export, dead parameter or single-caller abstraction remains.
- `oaef clean-code` reports zero blocking violations and the regression test passes.

## Anti-Patterns

- Building an abstraction "for reuse" with exactly one caller.
- Adding a dependency whose behaviour a stdlib primitive or DOM capability already covers.
- Fixing a bug at the call site while the shared root stays wrong.
- Leaving `// ponytail:` markers with no evolution trigger.
