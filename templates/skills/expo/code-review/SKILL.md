---
name: code-review
description: >-
  Use when reviewing a change or preparing a pull request in Expo. Triggers on: "review", "PR", "checklist",
  "pre-PR". Chains into: none (terminal skill of every recipe). Performs the pre-PR self-review for Expo: Step 0
  ingests the canonical truth from the main branch, the severity taxonomy separates blockers from nits, and every
  finding is remediated holistically across the pull request and its sibling branches.
argument-hint: "[PR scope or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: expo
  version: 1.1.0
---

# Code Review (Expo)

> **Stack Profile:** Expo
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Self-review a change before it becomes a pull request. Ingest the canonical truth first, separate blockers from nits with an explicit severity taxonomy, and remediate every finding across the whole change set instead of the single line where it was noticed.

## Territory
- The whole pull request across `app/`, `src/`, `__tests__/`, and `test/`.
- `docs/standards/` and `docs/wiki/` - the standards and memory the review must respect.
- Sibling branches of the current change, when the same pattern repeats.

## Step 0 - Pre-Review Canonical Truth Ingestion
1. Fetch and absorb the canonical truth before reviewing:

   ```bash
   git fetch origin main
   ```

2. Read `AGENTS.md`, accepted ADRs, `docs/standards/*` (including `governance_checks.md`), and `docs/wiki/`.
3. Confirm the branch is not stale against `origin/main`; rebase before judging.
4. Reject findings that only reflect a stale branch.

## Cascade Remediation
- A finding is fixed wherever the pattern appears, not only where it was spotted.
- Hunt the same pattern across the pull request and its sibling branches in the same change set.
- Every equivalent Expo file receives the correction, or the exception is recorded in `docs/wiki/memory/handoff.md`.
- Name the pattern, not the line, so the fix generalizes.

## Ponytail Anti-Slop Hunt
Apply the five remediation tags to every changed file:
- `[DELETE]` - dead weight, commented-out code, pass-through wrappers.
- `[STDLIB]` - custom code replacing a TypeScript stdlib primitive.
- `[NATIVE]` - custom code replacing a React Native or Expo platform capability.
- `[YAGNI]` - speculative features, single-implementation interfaces with no mock need.
- `[SHRINK]` - a multi-line construct reducible to one idiomatic line.

## DRY Factory Audit
- One `make<Entity>` factory per entity per suite; no duplicated literals across tests.
- No dead parameters and no optional collection without a constant-empty default.
- Deterministic fixtures only: no clock, randomness, or network.

## Severity Taxonomy
- **Tier 1 `[BLOCKER]`** - a Quality Gate fails, a contract is violated, or data can be lost; blocks the merge.
- **Tier 2 `[MAJOR]`** - a design defect (coupling, swallowed error, DI leak) that must be fixed before merge.
- **Tier 3 `[MINOR]` / `[NIT]` / `[PRAISE]`** - style, naming, and recognition; never blocks.
- Every non-trivial suggestion ships an actionable block in the review comment.

## Repository Conformance Gate
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`) and fix every blocking finding.
- Run `oaef lint` and `oaef doctor`.
- Record accepted findings and deferred work in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every Tier 1 and Tier 2 finding is resolved before the pull request opens.
- The change set is not stale against `origin/main`.
- Cascade remediation is complete across the pull request and sibling branches.

## Anti-Patterns
- Reviewing a stale branch and reporting false positives.
- Fixing one instance of a pattern while identical instances remain.
- Subjective taste presented as a blocker.
