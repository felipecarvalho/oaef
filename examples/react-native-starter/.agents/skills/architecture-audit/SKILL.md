---
name: architecture-audit
description: >-
  Use when reviewing module boundaries, coupling or dependency direction in React Native. Triggers on: "architecture", "boundary", "coupling", "cycle". Chains into: conformance-audit, code-review. Audits layer boundaries, cyclic dependencies and Clean Sizing inside React Native: domain code never reaches outward, infrastructure never leaks inward, and every module keeps a single reason to change.
argument-hint: "[module path or boundary name]"
license: MIT
metadata:
  framework: OAEF
  stack: react-native
  version: 1.1.0
---

# Architecture Audit (React Native)

> **Stack Profile:** React Native
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Prove that dependency direction and module sizing stay intact as the React Native application grows. Layers are a contract: `domain` defines rules, `data` implements persistence and transport, `presentation` renders. Edges point inward only.

## Territory
- `src/features/<feature>/domain` — entities, value objects, repository ports.
- `src/features/<feature>/data` — repository implementations, mappers, clients.
- `src/features/<feature>/presentation` — screens, components, hooks, view models.
- `src/shared/`, `src/components/` — cross-feature utilities with no feature imports.
- `src/**/core/**`, `src/**/infra/**` — infrastructure adapters.

## Boundary Checklist
- `domain` imports no `react-native`, no `axios`, no navigation and no `data`/`presentation` module.
- `data` implements a port declared in `domain`; it never imports `presentation`.
- `presentation` orchestrates through ports and hooks; it never instantiates a network client (`axios.create(`, `new XMLHttpRequest(`, `new HttpClient(` — `CC-10`).
- Container resolution (`container.get(`, `Container.get(`, `container.resolve(`, `getService(`) is confined to the composition root and presentation layer; it is banned in `src/domain/`, `src/data/`, `src/services/`, `src/repositories/` (`CC-07`).
- A shared module imports nothing from a feature; a feature may import shared.
- No import cycle between slices; verify with a graph pass over the import edges or `npx madge --circular src` when available.

## Sizing Bounds
- Files at or under 300 lines; splitting a component or hook that exceeds the bound.
- Functions at or under 50 lines.
- One primary export per module; a file with three unrelated exports is a split candidate.
- No "utils" catch-all module accumulating unrelated helpers.

## Repository Conformance Gate
- Run `oaef doctor` (native: `node tool/governance.mjs doctor`).
- Run `oaef lint` (native: `npx eslint .`).
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every edge points inward; no inward layer imports an outward one.
- No import cycle remains between feature slices.
- Every module has a single reason to change and stays within the sizing bounds.

## Anti-Patterns
- A repository importing a screen or navigation object.
- Domain entities annotated with framework types.
- A shared component reaching into a specific feature.
- Container lookups inside domain or data code.
