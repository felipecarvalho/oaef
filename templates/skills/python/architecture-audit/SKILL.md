---
name: architecture-audit
description: >-
  Use when reviewing module boundaries, coupling or dependency direction in Python 3. Triggers on: "architecture", "boundary", "coupling", "cycle". Chains into: conformance-audit, code-review. Audits layer boundaries, cyclic dependencies and Clean Sizing inside Python 3: domain code never reaches outward, infrastructure never leaks inward, and every module keeps a single reason to change.
argument-hint: "[module path or boundary name]"
license: MIT
metadata:
  framework: OAEF
  stack: python
  version: 1.1.0
---

# Architecture Audit (Python 3)

> **Stack Profile:** Python 3
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Keep dependency direction one-way and every module single-purpose. Domain code depends on
nothing outward; adapters depend on the domain; the composition root depends on everything.

## Territory
- `<package>/features/<feature>/domain/` — pure business rules.
- `<package>/features/<feature>/data/` — persistence and transport adapters.
- `<package>/features/<feature>/presentation/` — request/response mapping.
- `src/<package>/di/`, `main.py` — composition root.
- `tests/` — where structural tests may assert import direction.

## Boundary Checklist
- Domain imports only the standard library and sibling domain modules; no `requests`,
  `httpx`, `aiohttp`, `sqlalchemy`, `fastapi` or any adapter import.
- Data layer imports domain contracts; domain never imports the data layer.
- Presentation maps transport types to domain types; no business rule lives here.
- Cross-feature imports go through a published domain contract, never into a foreign
  `data/` or `presentation/` package.
- No import cycles: run `python3 -c "import <package>"` and `pylint --disable=all
  --enable=cyclic-import <package>` to confirm. `CC-07`/`CC-10` guard the inward leaks.
- Concrete network clients (`requests.Session(`, `httpx.Client(`, `aiohttp.ClientSession(`)
  live only in the composition root or an adapter module, never in domain code.
- Greenlet/async boundaries are explicit: domain functions are synchronous or `async`
  consistently, never mixed through implicit event loops.

## Sizing Bounds
- One module, one reason to change: split when two concerns share a file.
- File ceiling 300 lines; function ceiling 50 lines; delete or split on breach.
- One public class or one cohesive function group per module.
- `__init__.py` re-exports the public contract only; no logic.
- A module importing more than five siblings signals a missing facade.

## Repository Conformance Gate
- `oaef doctor` — structural conformance.
- `oaef lint` — governance findings.
- `oaef clean-code` (native: `python3 tool/governance.py clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Import-direction checks report zero violations across all feature slices.
- No import cycles and no adapter import reachable from `domain/`.
- Every module respects the 300-line file and 50-line function ceilings.

## Anti-Patterns
- A repository module importing `fastapi` or `sqlalchemy` into `domain/`.
- Shared mutable global state acting as an implicit cross-module channel.
- A `utils/` package that every layer imports, inverting the dependency direction.
- Feature A reaching directly into Feature B's `data/` package.
- A god module accumulating unrelated helpers until it exceeds the sizing ceiling.
