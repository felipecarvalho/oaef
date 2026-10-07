---
name: run-static-analysis
description: >-
  Use when the analyzer, linter or type checker reports findings in Kotlin & JVM. Triggers on: "analyze", "lint", "typecheck", "warnings". Chains into: code-review. Runs the Kotlin & JVM analyzer with warnings treated as errors and zero suppressions: every finding is fixed in the code instead of being silenced with an inline ignore directive, and machine-generated files stay the only exemption.
argument-hint: "[scope or analyzer]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin
  version: 1.1.0
---

# Run Static Analysis (Kotlin & JVM)

> **Stack Profile:** Kotlin & JVM
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Treat the analyzer as the first quality gate and warnings as errors. Every finding is
resolved in the code. A suppression is a decision that must be justified at the line, and
the default is not to suppress.

## Territory
- `src/main/`, `app/src/main/` — production sources under analysis.
- `src/test/`, `app/src/test/` — tests still obey the linter.
- `detekt.yml`, `.editorconfig`, `build.gradle.kts` — analyzer configuration.
- CI workflow running the analysis job.

## Analyzer Invocation
- Detekt: `./gradlew detekt`.
- ktlint: `./gradlew ktlintCheck`.
- Kotlin compiler warnings: `./gradlew compileKotlin --warning-mode all`.
- Run all three; a green detekt with a failing ktlint is not green.
- Treat findings as blocking: exit non-zero on any warning or error.
- Keep the configuration explicit; do not inherit a loose default profile.

```bash
./gradlew detekt ktlintCheck
```

## Zero-Suppression Policy
- No `@Suppress("...")` without a comment naming the reason and the tracked follow-up.
- No `// ktlint-disable`, `// noinspection` or blanket `all` suppressions.
- Prefer fixing the rule violation over widening the rule configuration.
- Machine-generated sources (`build/`, Hilt/KSP output, `*.g.*`) are the only exemption.
- Detekt baseline files must shrink over time, never grow silently.

## Repository Conformance Gate
- Run `oaef doctor` (native: `kotlinc -script tool/governance.main.kts doctor`).
- Run `oaef lint` and `oaef clean-code` (native: `... governance.main.kts clean-code`).
- Record any justified suppression and its follow-up in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Detekt, ktlint and the compiler complete with zero findings and zero warnings.
- Any remaining suppression is documented with a reason and a tracked follow-up.
- Detekt baseline size is stable or shrinking.
- CI runs the analysis with warnings treated as errors.

## Anti-Patterns
- `@Suppress("all")` or `// ktlint-disable` on a whole file.
- Growing a detekt baseline to hide new findings.
- Disabling a rule project-wide because one call site violated it.
- Fixing the formatting but leaving the semantic warning.
