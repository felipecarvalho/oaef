---
name: architecture-audit
description: >-
  Use when reviewing module boundaries, coupling or dependency direction in Swift. Triggers on: "architecture", "boundary", "coupling", "cycle". Chains into: conformance-audit, code-review. Audits layer boundaries, cyclic dependencies and Clean Sizing inside Swift: domain code never reaches outward, infrastructure never leaks inward, and every module keeps a single reason to change.
argument-hint: "[module path or boundary name]"
license: MIT
metadata:
  framework: OAEF
  stack: swift
  version: 1.1.0
---

# Architecture Audit (Swift)

> **Stack Profile:** Swift
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Verify that dependencies point inward and that each Swift target keeps one reason to change. The audit reports boundary, coupling and cycle findings with the exact file and line; it never rewrites behavior.

## Territory
- `Sources/<Module>/{Domain,Data,Presentation}` — the three layer roots.
- `Sources/<Module>/` — module-level types and composition.
- `Sources/<Module>/DI/` and `*Assembly.swift` — composition boundaries.
- `Package.swift` — target graph and declared dependencies.
- `Tests/` — target-to-target test imports that can hide a cycle.

## Boundary Checklist
- Domain imports no `Presentation` and no `Data` type.
- Data conforms to a domain-owned protocol; the domain never imports the concrete client.
- Presentation resolves dependencies only through the composition root.
- No target imports a sibling it does not declare in `Package.swift`.
- Dependency direction points inward; an outward reach is a `[BLOCKER]`.
- Network and persistence types stay behind a protocol owned by the consumer.

## Sizing Bounds
- File at or below 300 lines.
- Function at or below 50 lines.
- One reason to change per type; a type with two responsibilities splits.
- A feature slice stays vertical: state, presentation and routing ship together.
- A shared module holds only what two or more slices actually consume.

## Repository Conformance Gate
- `oaef doctor`
- `oaef lint`
- `oaef clean-code` (native: `swift tool/governance.swift clean-code`)
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- No cyclic import remains across targets.
- Every outward dependency is inverted behind a domain-owned protocol.
- No file exceeds 300 lines and no function exceeds 50 lines.
- `swift build` resolves the full target graph without warnings.

## Anti-Patterns
- Domain importing `URLSession` or a concrete Data store directly.
- A "shared" module that every layer imports and that imports every layer back.
- A type that both formats presentation output and persists it.
- A target dependency that exists only to reach one private helper.
- Sizing exceptions recorded without a `// ponytail:` ceiling and evolution trigger.
