---
name: run-static-analysis
description: >-
  Use when the analyzer, linter or type checker reports findings in Expo. Triggers on: "analyze", "lint",
  "typecheck", "warnings". Chains into: code-review. Runs the Expo analyzer with warnings treated as errors and
  zero suppressions: every finding is fixed in the code instead of being silenced with an inline ignore directive,
  and machine-generated files stay the only exemption.
argument-hint: "[scope or analyzer]"
license: MIT
metadata:
  framework: OAEF
  stack: expo
  version: 1.1.0
---

# Run Static Analysis (Expo)

> **Stack Profile:** Expo
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Run the Expo toolchain with findings treated as errors and zero suppressions. Every warning is fixed in the code, never silenced with an inline ignore. Machine-generated files are the only exemption, and they are never edited by hand.

## Territory
- `app/`, `src/` - the sources checked by `tsc` and the OAEF governance engine.
- `tsconfig.json`, `.eslintrc` - the checker configuration.
- `tool/governance.mjs` - the native governance entrypoint.

## Analyzer Invocation
1. Type check with no emit:

   ```bash
   npx tsc --noEmit
   ```

2. Lint the workspace:

   ```bash
   npx eslint .
   ```

3. Diagnose the Expo project and its dependencies:

   ```bash
   npx expo-doctor
   ```

4. Run the governance engine for the clean-code checks:

   ```bash
   node tool/governance.mjs clean-code
   ```

5. Portable equivalent: `oaef clean-code` and `oaef lint`.

## Zero-Suppression Policy
- No `// @ts-ignore`, `// @ts-expect-error`, or inline `eslint-disable` for a fixable finding.
- Fix the type, the nullability, or the control flow instead of escaping the checker.
- A scoped suppression is allowed only for a third-party deprecation during an active migration, with a linked issue.
- Machine-generated files (`*.generated.*`, `expo-env.d.ts`) are excluded by configuration, not by inline pragmas.
- The analyzer exit code gates the pull request; a non-zero exit blocks the merge.

## Repository Conformance Gate
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`) and clear every blocking finding.
- Run `oaef lint` and `oaef doctor`.
- Record any scoped, time-boxed suppression with its linked issue in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `npx tsc --noEmit`, `npx eslint .`, and `npx expo-doctor` exit clean.
- Zero unallowed suppressions remain in production sources.
- Every finding is fixed in code or has a documented, time-boxed exemption.

## Anti-Patterns
- Silencing a finding with an inline ignore instead of fixing it.
- Disabling a rule globally to pass the gate.
- Editing a machine-generated file by hand.
