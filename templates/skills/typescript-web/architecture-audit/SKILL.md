---
name: architecture-audit
description: >-
  Use when reviewing module boundaries, coupling or dependency direction in TypeScript & Web. Triggers on: "architecture", "boundary", "coupling", "cycle". Chains into: conformance-audit, code-review. Audits layer boundaries, cyclic dependencies and Clean Sizing inside TypeScript & Web: domain code never reaches outward, infrastructure never leaks inward, and every module keeps a single reason to change.
argument-hint: "[module path or boundary name]"
license: MIT
metadata:
  framework: OAEF
  stack: typescript-web
  version: 1.1.0
---

# Architecture Audit (TypeScript & Web)

> **Stack Profile:** TypeScript & Web
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission

Verify that the dependency graph points inward and stays acyclic. Domain and data layers
are pure; presentation depends on them, never the reverse. Infrastructure details stay
behind interfaces owned by the consumer.

## Territory

- `src/features/<feature>/{presentation,domain,data}/` — the vertical slice layers.
- `src/shared/`, `src/components/` — reusable surfaces with no domain leakage upward.
- `src/**/index.ts` — barrel files; audit what each re-exports.
- `tsconfig.json` path aliases — the mechanical boundary mechanism.
- `package.json` — dependency direction at the package level.

## Boundary Checklist

1. **Inward only** — `presentation -> domain`, `data -> domain`; `domain` imports neither
   `presentation` nor `data`.
2. **No infrastructure leak** — `fetch`, `axios.create(`, `localStorage`, `window`,
   `document` and framework hooks never appear in `domain/` or `data/` code that must stay
   runtime-agnostic; they live behind an interface.
3. **No cycle** — following imports never returns to the origin module. Barrels must not
   create a cycle by re-exporting a sibling that imports back.
4. **Single reason to change** — a module holds one cohesive responsibility; unrelated
   helpers do not share a file.
5. **Consumer-owned interfaces** — the interface is declared where it is used, not in the
   implementation module.
6. **Path aliases enforce it** — `@domain/*`, `@data/*`, `@presentation/*` in
   `tsconfig.json` make an illegal import visible and lintable.

## Sizing Bounds

- Maximum 300 lines per file; maximum 50 lines per function (`Clean Sizing`).
- A file over 300 lines is split by responsibility, not by arbitrary line count.
- A component over 50 lines extracts sub-components, hooks or presentational atoms.
- Measure with `oaef audit` and the native quality gate; the bound is a floor, not a
  target to creep toward.

## Repository Conformance Gate

- Run `oaef doctor`, `oaef lint`, `oaef clean-code` (native:
  `node tool/governance.mjs doctor|lint|clean-code`).
- Run `oaef audit` for Clean Sizing floors and `npx tsc --noEmit` for boundary typing.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria

- No import crosses a layer against the direction rules.
- No dependency cycle among `src/features/**` modules.
- Every audited file is within the Clean Sizing bounds.

## Anti-Patterns

- `domain/` importing a framework hook or a network client.
- A barrel file that reintroduces a cycle it was meant to remove.
- Splitting a 320-line file into two 160-line files with no responsibility boundary.
- Declaring the implementation interface in the concrete module instead of the consumer.
