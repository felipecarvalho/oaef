---
name: run-static-analysis
description: >-
  Use when the analyzer, linter or type checker reports findings in React Native. Triggers on: "analyze", "lint", "typecheck", "warnings". Chains into: code-review. Runs the React Native analyzer with warnings treated as errors and zero suppressions: every finding is fixed in the code instead of being silenced with an inline ignore directive, and machine-generated files stay the only exemption.
argument-hint: "[scope or analyzer]"
license: MIT
metadata:
  framework: OAEF
  stack: react-native
  version: 1.1.0
---

# Run Static Analysis (React Native)

> **Stack Profile:** React Native
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Drive the type checker and linter to zero findings without a single suppression. A warning that is silenced is a defect that is deferred.

## Territory
- `src/**/*.{ts,tsx}` — analysed source.
- `tsconfig.json`, `.eslintrc.*` / `eslint.config.*` — analyzer configuration.
- `package.json` — scripts and dependency versions.
- generated types (for example `src/**/__generated__/**`) — the only exemption.

## Analyzer Invocation
- Type check: `npx tsc --noEmit`.
- Lint: `npx eslint .`.
- Governance aggregate: `oaef lint` (native: `node tool/governance.mjs lint`).
- Run type check before lint: a type error often explains a cascade of lint findings.
- Capture the full output; fix findings by category rather than one by one.

## Zero-Suppression Policy
- No `eslint-disable`, `@ts-ignore` or `@ts-expect-error` in `src/**`; fix the code instead.
- No `as any`, no non-null `!` assertion, no implicit `any` left in exported signatures.
- When a third-party type is genuinely wrong, isolate it behind a typed adapter with a comment naming the dependency and the reason; never suppress inline at the call site.
- Generated files are the only exemption and must be excluded via `.eslintignore` / `eslint.config.*`, not per-line directives.
- The governance check `oaef clean-code` flags raw debug output (`console.log`) as a production violation (`CC-05`); route it through the logger interface.

## Repository Conformance Gate
- Run `oaef doctor` (native: `node tool/governance.mjs doctor`).
- Run `oaef lint` (native: `npx eslint .`).
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `npx tsc --noEmit` exits 0 with no output.
- `npx eslint .` exits 0 with zero suppressions.
- No `console.log` or debug output remains in production directories.

## Anti-Patterns
- An `eslint-disable-next-line` added to land a change.
- `@ts-ignore` above a line whose type could be fixed.
- Widening a signature to `any` to quiet the checker.
- Excluding a directory from analysis to hide findings.
