---
name: collect-coverage
description: >-
  Use when measuring, collecting or enforcing coverage for Universal / Polyglot. Triggers on: "coverage", "lcov", "jacoco", "cobertura", "branches". Chains into: run-static-analysis, code-review. Extracts native Universal / Polyglot coverage (LCOV, JaCoCo, Cobertura or Coverlet), compares the result with the baseline floors of the repository, and applies the Monotonic Ratchet so quality can only move up.
argument-hint: "[coverage artifact or scope]"
license: MIT
metadata:
  framework: OAEF
  stack: universal
  version: 1.1.0
---

# Collect Coverage (Universal / Polyglot)

> **Stack Profile:** Universal / Polyglot
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Collect coverage per embedded language, reconcile it with the repository floors, and never let the number move down.

## Territory
- Artifact directories: `coverage/`, `cover/`, `TestResults/`, `build/reports/`, `target/`.
- Artifact formats: LCOV, JaCoCo XML, Cobertura XML, Coverlet cobertura XML.
- Baseline: `docs/wiki/metrics/baseline.json`.

## Coverage Extraction
- Dart/Flutter: `flutter test --coverage` → `coverage/lcov.info`.
- Node/TypeScript: `npm test -- --coverage` → `coverage/lcov.info`.
- Python: `pytest --cov` → `coverage.xml`.
- Go: `go test ./... -coverprofile=coverage.out`.
- Rust: `cargo tarpaulin` or `cargo llvm-cov`.
- Kotlin: `./gradlew jacocoTestReport` → JaCoCo XML.
- Swift: coverage from Xcode or `llvm-cov`.
- .NET: `dotnet test --collect:"XPlat Code Coverage"` → Cobertura XML.
- Per-language reports are merged into one repository number before comparison.

## Monotonic Ratchet
- Compare collected coverage against the floors in `baseline.json`.
- A floor may only rise; lowering it is a rejected change.
- When coverage increases materially, raise the floor to lock the gain.
- A missing artifact is treated as a floor miss, not as a pass.

## Repository Conformance Gate
- `oaef doctor` and `oaef lint` clean for the touched repository.
- `oaef clean-code` (native: `bash tool/governance.sh clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Coverage artifacts exist for every language family that changed.
- The merged number meets or exceeds every floor in `baseline.json`.
- Any raised floor is committed with the change that earned it.

## Anti-Patterns
- Excluding a module from coverage to pass the gate.
- Lowering a floor to unblock a pull request.
- Reporting coverage from a stale artifact.
