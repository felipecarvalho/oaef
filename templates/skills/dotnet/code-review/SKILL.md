---
name: code-review
description: >-
  Use when reviewing a change or preparing a pull request in C# / .NET. Triggers on: "review", "PR", "checklist", "pre-PR". Chains into: none (terminal skill of every recipe). Performs the pre-PR self-review for C# / .NET: Step 0 ingests the canonical truth from the main branch, the severity taxonomy separates blockers from nits, and every finding is remediated holistically across the pull request and its sibling branches.
argument-hint: "[PR scope or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: dotnet
  version: 1.1.0
---

# Code Review (C# / .NET)

> **Stack Profile:** C# / .NET
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Perform the pre-PR self-review that turns a working change into a mergeable one: canonical truth first, holistic remediation, and a severity taxonomy that separates blockers from nits.

## Territory
- The whole pull request across `src/**/*.cs`, `tests/**/*.cs`, `*.csproj`.
- `docs/standards/*`, `docs/adr/*` — the rules the review cites.
- `docs/wiki/memory/handoff.md` — the record of unresolved findings.

## Step 0 — Pre-Review Canonical Truth Ingestion
- `git fetch origin main` and absorb `AGENTS.md`, accepted ADRs, `docs/standards/*` and `docs/wiki/`.
- Rebase mentally on the current main; a finding that only exists on a stale branch is not a finding.
- Confirm the governing skills declared in the PR before reviewing code.

## Cascade Remediation
- Fix a finding everywhere it occurs in this PR and in sibling branches, not only the reported line.
- Name the pattern in the comment so the fix generalizes.
- Record any intentional exception in `docs/wiki/memory/handoff.md`.

## Ponytail Anti-Slop Hunt
Tag each simplification opportunity:
- `[DELETE]` dead weight: unused member, unreferenced project, commented-out block.
- `[STDLIB]` replace custom code with a BCL primitive (`record`, `LINQ`, `Span<T>`).
- `[NATIVE]` use a platform capability instead of hand-rolled logic.
- `[YAGNI]` speculative feature with no caller.
- `[SHRINK]` shrink a multi-line construct to one idiomatic line.

## DRY Factory Audit
- Every entity has one `Make<Entity>()` factory shared across suites and previews.
- No dead parameters; collections default to a constant empty instance.
- Test data is deterministic.

## Severity Taxonomy
- Tier 1 `[BLOCKER]` — correctness, security, build failure, swallowed exception (`CC-06`), DI leak (`CC-07`), unimplemented placeholder (`CC-09`).
- Tier 2 `[MAJOR]` — boundary/sizing violation, missing branch coverage, nullable collection (`CC-08`).
- Tier 3 `[MINOR]` / `[NIT]` / `[PRAISE]` — naming, style, and genuine praise.

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint`, `oaef clean-code` or `dotnet run --project tool/Governance.csproj clean-code`, plus `dotnet build /warnaserror`.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every `[BLOCKER]` resolved before the PR opens; nits either fixed or explicitly deferred.
- Findings remediated across the whole PR, not just the reviewed line.
- The Quality Gate and PR checklist are attached as evidence.

## Anti-Patterns
- Subjective taste presented as a blocker.
- Point-fixing a pattern found in three other files.
- Reviewing against a stale main branch.
