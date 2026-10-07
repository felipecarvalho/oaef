---
name: architecture-audit
description: >-
  Use when reviewing module boundaries, coupling or dependency direction in Universal / Polyglot. Triggers on: "architecture", "boundary", "coupling", "cycle". Chains into: conformance-audit, code-review. Audits layer boundaries, cyclic dependencies and Clean Sizing inside Universal / Polyglot: domain code never reaches outward, infrastructure never leaks inward, and every module keeps a single reason to change.
argument-hint: "[module path or boundary name]"
license: MIT
metadata:
  framework: OAEF
  stack: universal
  version: 1.1.0
---

# Architecture Audit (Universal / Polyglot)

> **Stack Profile:** Universal / Polyglot
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Keep every embedded language in this polyglot repository honest about its boundaries: dependencies point inward, the composition root is the only place that wires concretions, and no module carries more than one reason to change.

## Territory
- Domain-boundary directories: `src/<package>/domain/**`, `internal/<feature>/domain/**`, `Sources/<Module>/Domain/**`, `**/core/**`.
- Data and infrastructure: `src/<package>/data/**`, `internal/<feature>/data/**`, `Sources/<Module>/Data/**`.
- Composition roots: `main.py`, `main.go`, `src/main.rs`, `Program.cs`, `src/main.dart`, `**/di/**`, `**/composition_root*`.

## Boundary Checklist
- Domain code imports no framework, no HTTP client, no persistence driver.
- Infrastructure defines the port; domain depends on the port, never on the adapter.
- No import cycle inside a single language and none across the shared contract directories.
- Each module exposes a narrow public surface; internals stay unexported or package-private.
- The universal engine no-ops `CC-07` and `CC-10`: for these, consult `templates/rules/<stack>/rules.md` and verify by hand.

## Sizing Bounds
- Files stay under 300 lines; methods stay under 50 lines (Clean Sizing).
- A file that mixes routing, mapping and persistence is split by responsibility, not by convenience.
- A "utils" bucket that accumulates unrelated helpers is a boundary defect: split it or delete it.
- Cross-language contracts live in a dedicated schema layer; neither side imports the other's runtime types.
- A boundary is audited by reading the import list of each file, not by trusting directory names.
- Sibling modules of the same layer never import each other horizontally; they share through a lower layer.

## Repository Conformance Gate
- `oaef doctor` and `oaef lint` clean for the touched repository.
- `oaef clean-code` (native: `bash tool/governance.sh clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Dependency direction verified for every audited boundary.
- Zero cycles and zero cross-language leaks through shared contracts.
- Every audited file and method is within the Clean Sizing bounds.

## Anti-Patterns
- Domain importing a concrete HTTP client.
- Infrastructure types appearing in a public domain signature.
- A shared contract directory that quietly imports an adapter.
