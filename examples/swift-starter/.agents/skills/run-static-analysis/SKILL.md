---
name: run-static-analysis
description: >-
  Use when the analyzer, linter or type checker reports findings in Swift. Triggers on: "analyze", "lint", "typecheck", "warnings". Chains into: code-review. Runs the Swift analyzer with warnings treated as errors and zero suppressions: every finding is fixed in the code instead of being silenced with an inline ignore directive, and machine-generated files stay the only exemption.
argument-hint: "[scope or analyzer]"
license: MIT
metadata:
  framework: OAEF
  stack: swift
  version: 1.1.0
---

# Run Static Analysis (Swift)

> **Stack Profile:** Swift
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Run the Swift analyzer and compiler with warnings treated as errors and zero suppressions. A finding is fixed at its source; an inline disable directive is a finding of its own.

## Territory
- `Sources/` — the analyzed production targets.
- `Tests/` — the analyzed test targets.
- `Package.swift` — build settings and warning configuration.
- `.swiftlint.yml` — rule configuration, reviewed for disabled rules.
- Generated files — the only sanctioned exemption.

## Analyzer Invocation
- Build with `swift build -Xswiftc -warnings-as-errors`.
- Lint with `swiftlint --strict` over `Sources/` and `Tests/`.
- Run `oaef lint` for the framework checks alongside the native tools.
- Run `oaef clean-code` (native: `swift tool/governance.swift clean-code`) for the governance checks.
- Capture the full report before editing; fix by category, not by line order.
- Re-run until the report is empty.

## Zero-Suppression Policy
- No `// swiftlint:disable`, `@available` shrug or `#warning` left to silence a real finding.
- A suppression requires a recorded justification and a task in the handoff.
- `try?` that discards the error is treated as a suppression of failure handling.
- Machine-generated files are excluded by path, never by inline directive.
- A disabled rule in `.swiftlint.yml` must name the compensating control.

## Repository Conformance Gate
- `oaef doctor`
- `oaef lint`
- `oaef clean-code` (native: `swift tool/governance.swift clean-code`)
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `swift build -Xswiftc -warnings-as-errors` completes with zero warnings.
- `swiftlint --strict` reports zero violations.
- `oaef lint` reports zero blocking findings.
- No unsanctioned inline suppression remains.

## Anti-Patterns
- `// swiftlint:disable` on a line to hide a real defect.
- Downgrading a warning to a note in `Package.swift` to pass the gate.
- Fixing warnings file-by-file without grepping siblings for the same cause.
- Committing a generated file with warnings left unexcluded.
- Treating the analyzer report as advisory rather than blocking.
