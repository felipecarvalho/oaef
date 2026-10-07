---
name: architecture-audit
description: >-
  Use when reviewing module boundaries, coupling or dependency direction in Kotlin & JVM. Triggers on: "architecture", "boundary", "coupling", "cycle". Chains into: conformance-audit, code-review. Audits layer boundaries, cyclic dependencies and Clean Sizing inside Kotlin & JVM: domain code never reaches outward, infrastructure never leaks inward, and every module keeps a single reason to change.
argument-hint: "[module path or boundary name]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin
  version: 1.1.0
---

# Architecture Audit (Kotlin & JVM)

> **Stack Profile:** Kotlin & JVM
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Verify that package and module dependencies point inward. Domain stays free of framework
types, data access stays behind interfaces, and no cycle links two slices. Structure is
audited before it is extended, not after it breaks.

## Territory
- `**/features/<feature>/{presentation,domain,data}` — slice boundaries.
- `**/core/**`, `**/domain/**`, `**/data/**`, `**/infra/**` — layer packages.
- `settings.gradle.kts`, `build.gradle.kts` — module graph and declared dependencies.
- `src/main/` — composition root wiring direction.

## Boundary Checklist
- Domain depends on nothing but the Kotlin stdlib and other domain types.
- Data access returns domain models; it never returns framework or HTTP types.
- Presentation depends on domain abstractions, never on concrete repositories.
- Infrastructure implements interfaces owned by domain (dependency inversion).
- No presentation type leaks into domain; no serialization annotation crosses inward.
- Module dependencies in Gradle point one way; a reverse edge is a defect.
- Detect cycles with `./gradlew :app:dependencies` plus a package-dependency scan.

```kotlin
// domain owns the contract; data implements it.
interface BookingRepository { suspend fun byId(id: BookingId): Booking? }
class BookingRepositoryImpl(private val api: BookingApi) : BookingRepository { /* ... */ }
```

## Sizing Bounds
- Zero production files above 300 lines.
- Zero functions above 50 lines.
- One public top-level declaration per file where practical; extensions grouped by receiver.
- A package with a single file and no dependents is a candidate for deletion (see `ponytail`).
- Oversized slices are split by capability, not by technical layer duplication.

## Repository Conformance Gate
- Run `oaef doctor` (native: `kotlinc -script tool/governance.main.kts doctor`).
- Run `oaef lint` and `oaef clean-code`; `CC-07` and `CC-10` boundary findings are blocking.
- Record unresolved structural findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- No cyclic dependency between feature slices or Gradle modules.
- Every layer edge points inward; the module graph is acyclic.
- Files and functions respect the Clean Sizing bounds.

## Anti-Patterns
- A `domain` package importing Compose, OkHttp or a serialization library.
- Data objects crossing into presentation unchanged, leaking transport concerns.
- Gradle modules with bidirectional dependencies "for convenience".
- A shared `util` package that becomes a hidden coupling hub.
