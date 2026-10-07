---
name: code-review
description: >-
  Use when reviewing a change or preparing a pull request in TypeScript & Web. Triggers on: "review", "PR", "checklist", "pre-PR". Chains into: none (terminal skill of every recipe). Performs the pre-PR self-review for TypeScript & Web: Step 0 ingests the canonical truth from the main branch, the severity taxonomy separates blockers from nits, and every finding is remediated holistically across the pull request and its sibling branches.
argument-hint: "[PR scope or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: typescript-web
  version: 1.1.0
---

# Code Review (TypeScript & Web)

> **Stack Profile:** TypeScript & Web
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission

Perform the pre-PR self-review before a change is proposed: ingest the current canonical
truth, hunt defects and slop across the whole change, and remediate holistically. Every
finding gets a suggestion, not just a complaint.

## Territory

- The whole pull request diff across `src/**`, `test/**`, `tool/**`.
- `AGENTS.md`, `docs/standards/**`, `docs/adr/**` — the canonical truth to ingest.
- `docs/wiki/log.md`, `docs/wiki/memory/handoff.md` — the living memory to update.

## Step 0 — Pre-Review Canonical Truth Ingestion

Before reviewing any line:

1. `git fetch origin main` and rebase or merge so the branch is current.
2. Absorb `AGENTS.md`, the accepted ADRs under `docs/adr/`, every `docs/standards/*`
   document and the `docs/wiki/` notes.
3. Reconcile the diff against the ingested truth: a rule that changed on `main` invalidates
   findings raised against the old rule.
4. Re-run the gates on the updated base to avoid stale-branch false positives.
5. Only then begin the review.

## Cascade Remediation

- Every finding is hunted across the entire pull request and across sibling branches that
  share the pattern.
- Fix the pattern holistically in every equivalent file in the same pass; an isolated
  point fix on one occurrence is a rejected review.
- When the same defect recurs, elevate the rule: a repeated review finding becomes a
  canonical rule or standard, never a recurring comment.

## Ponytail Anti-Slop Hunt

Scan the diff for each tag and resolve it:

- `[DELETE]` — dead code, unused exports, commented-out blocks, obsolete helpers.
- `[STDLIB]` — hand-rolled logic a stdlib primitive already covers.
- `[NATIVE]` — JavaScript reimplementing a DOM/CSS capability (queries, `clamp()`,
  validation, `Intl`).
- `[YAGNI]` — speculative abstraction, a layer or dependency built for one consumer.
- `[SHRINK]` — behaviour correct but the diff larger than necessary.

## DRY Factory Audit

- Confirm one `make<Entity>` factory per entity, defined locally in its suite.
- Remove any parameter every caller sets to the same value (dead parameter).
- Confirm no factory passes `null` for a domain-guaranteed field and that optional
  collections default to `Object.freeze([])`.
- Confirm mocks live only at process boundaries, not around the domain.

## Severity Taxonomy

- Tier 1 `[BLOCKER]` — correctness, security, data loss, a broken gate, a swallowed
  exception, a layer-boundary violation. Must be fixed before merge.
- Tier 2 `[MAJOR]` — maintainability, missing tests for an error branch, non-idiomatic
  code, a missed cascade occurrence. Should be fixed in this PR.
- Tier 3 `[MINOR]`, `[NIT]`, `[PRAISE]` — style, naming, optional polish, and explicit
  recognition of good work. Non-blocking.

Each non-trivial finding carries an actionable suggestion block, phrased in a friendly
peer tone, with zero emojis and zero subjective taste.

## Repository Conformance Gate

- Run `oaef doctor`, `oaef lint`, `oaef clean-code` (native:
  `node tool/governance.mjs doctor|lint|clean-code`).
- Run `npx tsc --noEmit`, `npx eslint src --max-warnings 0` and `npm test -- --coverage`.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria

- Step 0 completed against a current base; no stale-branch finding remains.
- Every Tier 1 and Tier 2 finding is fixed, with cascades resolved repository-wide.
- Unresolved items are Tier 3 with a recorded rationale.

## Anti-Patterns

- Reviewing against a stale branch and reporting already-fixed issues.
- A point fix on one occurrence while siblings keep the same defect.
- Raising personal style preferences as blockers.
- A finding with no suggestion and no severity tag.
