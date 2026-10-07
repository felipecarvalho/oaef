---
name: architecture-audit
description: >-
  Use when reviewing module boundaries, coupling or dependency direction in Kotlin Multiplatform. Triggers on: "architecture", "boundary", "coupling", "cycle". Chains into: conformance-audit, code-review. Audits layer boundaries, cyclic dependencies and Clean Sizing inside Kotlin Multiplatform: domain code never reaches outward, infrastructure never leaks inward, and every module keeps a single reason to change.
argument-hint: "[module path or boundary name]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.1.0
---

# Architecture Audit (Kotlin Multiplatform)

> **Stack Profile:** Kotlin Multiplatform
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Prove that dependency arrows point inward and that no source set, feature package or Gradle module is doing two jobs. Report every violation with the path and the offending import.

## Territory
- `src/commonMain/kotlin/**/{domain,data,presentation}/**` - the three layers, wherever they live.
- `src/androidMain/kotlin/**`, `src/iosMain/kotlin/**`, `src/desktopMain/kotlin/**` - platform source sets.
- `**/features/<feature>/**` - vertical slices and their cross-feature edges.
- `build.gradle.kts`, `settings.gradle.kts` - module graph and dependency declarations.

## Boundary Checklist
- `domain` imports nothing outward: no Compose, no `android.*`, no `platform.*`, no `OkHttpClient`, no `expect/actual` implementation detail.
- `data` implements interfaces owned by `domain`; the interface lives inward, the implementation lives outward.
- `presentation` may depend on `domain`; `domain` never depends on `presentation`.
- `commonMain` never references a symbol declared only in `androidMain`/`iosMain`/`desktopMain`; that difference is an `expect/actual` pair declared in `commonMain`.
- No cyclic edges between feature packages: inspect with `grep -rn "import .*features\." src/commonMain`.
- No container resolution outside the composition root (`CC-07`): `inject<`, `KoinComponent`, `getKoin().get(`, `GlobalContext.get().get(` are allowed only in `**/di/**`, `*Module.kt`, `*Application*`, `*Activity*`.
- No concrete network client in domain or data (`CC-10`): `OkHttpClient(`, `HttpClient(` live behind an interface injected from the composition root.
- `expect/actual` pairs are one-to-one per target; an `expect` with no `actual` for a declared target is a build failure, not a warning.

## Sizing Bounds
- A production file is at most 300 lines; split by responsibility, not by alphabet.
- A function is at most 50 lines; a `@Composable` is at most 100 lines.
- One module and one class have a single reason to change; a second reason is a new type.
- Sizing is reported with the file, the line count and the narrowed responsibility.

## Repository Conformance Gate
- Run `oaef doctor` (structure and parity) and `oaef clean-code` (native: `kotlinc -script tool/governance.main.kts clean-code`).
- Run `./gradlew detekt` with warnings treated as errors.
- Record every deferred boundary violation in `docs/wiki/memory/handoff.md` with the target module.

## Exit Criteria
- Every documented boundary has zero inward-violating imports.
- No cyclic dependency remains between feature packages or Gradle modules.
- All oversized files are split or carry a `// ponytail:` ceiling marker with an owner.

## Anti-Patterns
- A `domain` type annotated with a serialization or Compose annotation.
- A feature package importing another feature's `data` implementation directly.
- An `expect` declaration whose only `actual` is a `TODO(`.
