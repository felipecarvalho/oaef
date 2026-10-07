---
name: architecture-audit
description: >-
  Use when reviewing module boundaries, coupling or dependency direction in Expo. Triggers on: "architecture",
  "boundary", "coupling", "cycle". Chains into: conformance-audit, code-review. Audits layer boundaries, cyclic
  dependencies and Clean Sizing inside Expo: domain code never reaches outward, infrastructure never leaks inward,
  and every module keeps a single reason to change.
argument-hint: "[module path or boundary name]"
license: MIT
metadata:
  framework: OAEF
  stack: expo
  version: 1.1.0
---

# Architecture Audit (Expo)

> **Stack Profile:** Expo
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Verify that Expo feature slices keep a single direction of dependency: `presentation -> domain <- data`. Domain defines contracts and knows nothing about React, Expo, or the network; data implements those contracts; presentation orchestrates. Every module keeps one reason to change.

## Territory
- `src/features/<feature>/domain/` - entities, value objects, repository contracts.
- `src/features/<feature>/data/` - repository implementations, API and storage adapters.
- `src/features/<feature>/presentation/` - hooks, screens, view models.
- `src/shared/`, `src/components/` - cross-feature surfaces.
- `app/` - Expo Router entrypoints and route groups.

## Boundary Checklist
1. **Direction** - domain imports neither React nor `expo-*` nor `data/`; data imports domain, never presentation.
2. **Cycles** - no import cycle between feature modules; consolidate shared code into `src/shared/` instead.
3. **Container confinement** - service-locator resolution (`container.get(`, `container.resolve(`, `getService(`) never appears under `domain/`, `data/`, `services/`, or `repositories/` (`CC-07`).
4. **Network client** - no concrete client instantiation (`axios.create(`, `new XMLHttpRequest(`) outside the composition root or an injected factory (`CC-10`).
5. **Cross-feature reach** - a feature never imports another feature's internals; share via `src/shared/` or a published contract.
6. **Route thinness** - `app/` route files re-export thin screens and hold no business logic.

## Sizing Bounds
- Files at most 300 physical lines (target at most 200); extract before crossing 200.
- Methods and hooks at most 50 lines (target at most 30).
- One component or hook per file; one public export per module barrel.
- Feature slice holds at most one responsibility; split when two unrelated concerns share the directory.

## Repository Conformance Gate
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`) and resolve every `CC-07` and `CC-10` finding.
- Run `oaef lint` and `oaef doctor`.
- Record boundary exceptions, with the reason, in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- No import cycle detected across `src/features/**` and `app/**`.
- Zero service-locator or concrete-client findings inside domain, data, service, and repository layers.
- Every audited module has a single reason to change and stays inside the sizing bounds.

## Anti-Patterns
- Domain code importing React, Expo, or a concrete repository implementation.
- A feature slice importing another feature's private module.
- A shared `utils` grab-bag that hides an unlifted cross-feature dependency.
