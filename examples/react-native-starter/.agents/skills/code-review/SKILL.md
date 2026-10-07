---
name: code-review
description: >-
  Use when reviewing a change or preparing a pull request in React Native. Triggers on: "review", "PR", "checklist", "pre-PR". Chains into: none (terminal skill of every recipe). Performs the pre-PR self-review for React Native: Step 0 ingests the canonical truth from the main branch, the severity taxonomy separates blockers from nits, and every finding is remediated holistically across the pull request and its sibling branches.
argument-hint: "[PR scope or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: react-native
  version: 1.1.0
---

# Code Review (React Native)

> **Stack Profile:** React Native
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Perform the pre-PR self-review that a peer would perform, with evidence. Separate blockers from nits, and leave the branch conformant rather than merely commented.

## Territory
- The whole pull request diff across `src/**`, `app/**` and `__tests__/**`.
- `templates/*/docs/standards/**` — the standards the review cites.
- `docs/wiki/memory/handoff.md` — where unresolved findings are recorded.

## Step 0 — Pre-Review Canonical Truth Ingestion
Before reading the diff:
1. `git fetch origin main` and ingest `AGENTS.md`, accepted ADRs, `docs/standards/*` and `docs/wiki/`.
2. Compare the branch against current `main`, not against a stale local copy; discard findings already fixed upstream.
3. Declare the governing skills: `> Governing Skills: [.agents/skills/code-review/SKILL.md, ...]`.

## Cascade Remediation
- Every finding is hunted across the whole PR and across sibling branches: if a pattern is wrong in one place, fix every equivalent occurrence.
- Reclassify by pattern, not by file; one comment covers the class with a single remediation.
- Point fixes that leave the same defect elsewhere are rejected.

## Ponytail Anti-Slop Hunt
Tag every simplification opportunity during the review:
- `[DELETE]` — dead code, unused export, unreachable branch.
- `[STDLIB]` — hand-rolled logic a TypeScript/JavaScript primitive replaces.
- `[NATIVE]` — a wrapper where a React Native platform capability suffices.
- `[YAGNI]` — speculative option, config or abstraction with one caller.
- `[SHRINK]` — a function or file that should be smaller.

## DRY Factory Audit
- Verify one `make<Entity>` factory per entity; flag duplicated or over-parameterised factories.
- Check for dead parameters and `null` placeholders in test builders.

## Severity Taxonomy
- **Tier 1 `[BLOCKER]`** — correctness, silent exception swallowing, `any`/suppression, missing error branch, privacy leak.
- **Tier 2 `[MAJOR]`** — boundary violation, avoidable allocation in a hot path, missing test for a new branch.
- **Tier 3 `[MINOR]` / `[NIT]` / `[PRAISE]`** — naming, style, readability, and deserved acknowledgement.

## Repository Conformance Gate
- Run `oaef doctor` (native: `node tool/governance.mjs doctor`).
- Run `oaef lint` (native: `npx eslint .`).
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every Tier 1 and Tier 2 finding is remediated in the PR, not deferred.
- Every finding is applied holistically across equivalent code.
- The PR template's Agent Skills and Evidence sections are complete.

## Anti-Patterns
- Reviewing against a stale branch and reporting already-fixed issues.
- Subjective taste presented as a blocker.
- An isolated point fix that leaves the same defect elsewhere.
- A review comment with no actionable suggestion.
