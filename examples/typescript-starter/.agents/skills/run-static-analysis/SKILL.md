---
name: run-static-analysis
description: >-
  Use when the analyzer, linter or type checker reports findings in TypeScript & Web. Triggers on: "analyze", "lint", "typecheck", "warnings". Chains into: code-review. Runs the TypeScript & Web analyzer with warnings treated as errors and zero suppressions: every finding is fixed in the code instead of being silenced with an inline ignore directive, and machine-generated files stay the only exemption.
argument-hint: "[scope or analyzer]"
license: MIT
metadata:
  framework: OAEF
  stack: typescript-web
  version: 1.1.0
---

# Run Static Analysis (TypeScript & Web)

> **Stack Profile:** TypeScript & Web
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission

Drive the analyzer to zero findings with warnings treated as errors and no suppressions.
A finding is a defect signal: fix the code, never the report.

## Territory

- `src/**` — the analyze scope.
- `tsconfig.json` — compiler strictness flags.
- `eslint.config.*` / `.eslintrc.*` — lint rule set.
- `tool/governance.mjs` — the native governance entry.

## Analyzer Invocation

1. Type check: `npx tsc --noEmit`. `strict` is on; do not weaken it per file.
2. Lint: `npx eslint src` with `--max-warnings 0`.
3. Governance lint: `oaef lint` (native: `node tool/governance.mjs lint`), which adds the
   governance checks and secret scanning.
4. Read the findings grouped by rule; fix the highest-severity class first.
5. Re-run until zero. A partially fixed run is not done.

## Zero-Suppression Policy

- No `// eslint-disable`, `// @ts-ignore`, `// @ts-expect-error` or `// @ts-nocheck` in
  production code. If a rule fires, fix the code or change the rule globally with a
  recorded justification.
- `@ts-expect-error` is permitted only in a test that deliberately proves a type error
  and must be followed by the assertion that consumes it; never in `src/`.
- No inline rule relaxation inside a file to bypass a real defect.
- Machine-generated files are the only exemption; keep them listed in the ignore config,
  never `src/**` code you wrote.
- Do not add `eslint-disable-next-line` "temporarily"; a temporary suppression becomes
  permanent.
- A rule that produces a false positive is fixed in the rule configuration once, for the
  whole repository, not patched at each site.

## Repository Conformance Gate

- Run `oaef doctor`, `oaef lint`, `oaef clean-code` (native:
  `node tool/governance.mjs doctor|lint|clean-code`).
- Run `npx tsc --noEmit` and `npx eslint src --max-warnings 0`.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria

- `npx tsc --noEmit` and `npx eslint src --max-warnings 0` both exit 0.
- Zero suppression directives exist in `src/`.
- Every rule relaxation is a recorded, repository-wide configuration decision.

## Anti-Patterns

- Adding `// @ts-ignore` to move past a type error instead of fixing the type.
- Loosening `tsconfig.json` (`strict: false`, `noImplicitAny: false`) to silence errors.
- Excluding the noisiest directory from the lint scope.
- Leaving "temporary" `eslint-disable-next-line` comments in the diff.
