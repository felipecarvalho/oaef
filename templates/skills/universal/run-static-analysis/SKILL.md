---
name: run-static-analysis
description: >-
  Use when the analyzer, linter or type checker reports findings in Universal / Polyglot. Triggers on: "analyze", "lint", "typecheck", "warnings". Chains into: code-review. Runs the Universal / Polyglot analyzer with warnings treated as errors and zero suppressions: every finding is fixed in the code instead of being silenced with an inline ignore directive, and machine-generated files stay the only exemption.
argument-hint: "[scope or analyzer]"
license: MIT
metadata:
  framework: OAEF
  stack: universal
  version: 1.1.0
---

# Run Static Analysis (Universal / Polyglot)

> **Stack Profile:** Universal / Polyglot
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Drive every embedded language to a clean analyzer run, treating warnings as errors and fixing rather than suppressing.

## Territory
- Repository root and every embedded-language source tree.
- Analyzer configuration: `analysis_options.yaml`, `tsconfig.json`/eslint config, `pyproject.toml`/`ruff.toml`, `go vet` config, `clippy` config, detekt/ktlint config, `.swiftlint.yml`, `.editorconfig`.
- The portable entrypoint: `bash lint.sh`.

## Analyzer Invocation
- Dart/Flutter: `dart analyze --fatal-infos` / `flutter analyze`.
- TypeScript: `npx tsc --noEmit` and `npx eslint .`.
- Python: `ruff check .` and `mypy .`.
- Go: `go vet ./...` and `golangci-lint run`.
- Rust: `cargo clippy --all-targets -- -D warnings`.
- Kotlin: `./gradlew detekt` and `./gradlew ktlintCheck`.
- Swift: `swiftlint`.
- .NET: `dotnet build /warnaserror`.
- Run `bash lint.sh` first; it aggregates the per-language runs for this repository.

## Zero-Suppression Policy
- An inline ignore (`# noqa`, `eslint-disable`, `@Suppress`, `//nolint`, `#[allow(`) is a rejected change.
- Fix the code or fix the rule in the shared configuration; never silence a single line.
- The only exemption is machine-generated output: `*.g.*`, `*_pb2.py`, `*.min.js`, `*.generated.*`.
- Every finding is resolved in the same change that introduced it.

## Repository Conformance Gate
- `oaef doctor` and `oaef lint` clean for the touched repository.
- `oaef clean-code` (native: `bash tool/governance.sh clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `bash lint.sh` exits 0 for every touched language.
- Zero new suppressions across the change.
- Remaining warnings are fixed, not deferred.

## Anti-Patterns
- Adding an inline ignore to close a warning.
- Weakening the shared analyzer configuration to pass a build.
- Leaving a warning because "it is pre-existing".
