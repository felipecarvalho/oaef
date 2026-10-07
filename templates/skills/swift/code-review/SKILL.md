---
name: code-review
description: >-
  Use when reviewing a change or preparing a pull request in Swift. Triggers on: "review", "PR", "checklist", "pre-PR". Chains into: none (terminal skill of every recipe). Performs the pre-PR self-review for Swift: Step 0 ingests the canonical truth from the main branch, the severity taxonomy separates blockers from nits, and every finding is remediated holistically across the pull request and its sibling branches.
argument-hint: "[PR scope or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: swift
  version: 1.1.0
---

# Code Review (Swift)

> **Stack Profile:** Swift
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Perform the pre-PR self-review for a Swift change. The review ingests the canonical truth first, separates blockers from nits with a fixed taxonomy, and remediates each finding across the whole pull request rather than at one line.

## Territory
- Whole pull request diff across `Sources/`, `Tests/` and `Package.swift`.
- `docs/standards/` and `docs/adr/` — the canonical rules under review.
- `docs/wiki/memory/handoff.md` — findings that outlive the pull request.
- Sibling branches that share the same pattern.

## Step 0 — Pre-Review Canonical Truth Ingestion
- Run `git fetch origin main` and absorb the current `AGENTS.md`.
- Read accepted ADRs and every `docs/standards/*` document touched by the change.
- Read `docs/wiki/` for the current handoff and open findings.
- Reconcile the diff against that truth before reading the change as an author would.
- A review that skips Step 0 is a level-1 contract failure.

## Cascade Remediation
- Every finding is hunted across the whole pull request and its sibling branches.
- A defect in one view is checked in every equivalent view before the review closes.
- A recurring finding is elevated to a canonical rule only with human approval.
- Fixes land holistically; isolated point fixes are not accepted.

## Ponytail Anti-Slop Hunt
- Tag each candidate with `[DELETE]`, `[STDLIB]`, `[NATIVE]`, `[YAGNI]` or `[SHRINK]`.
- `[DELETE]` dead code, `[STDLIB]` reinvention of a stdlib primitive.
- `[NATIVE]` reinvention of a platform capability, `[YAGNI]` speculative abstraction.
- `[SHRINK]` a diff larger than the requirement demands.
- Flag any `// ponytail:` marker that hides a reachable fix.

## DRY Factory Audit
- One `make<Entity>` factory per entity in `Tests/`.
- Flag factories with parameters no test overrides.
- Flag `nil` collection parameters where a constant empty collection suffices.

## Severity Taxonomy
- Tier 1 `[BLOCKER]` — correctness, security, data loss, boundary violation, coverage floor.
- Tier 2 `[MAJOR]` — design, coupling, silent swallowing, missing error branch.
- Tier 3 `[MINOR]` — naming, readability; `[NIT]` — style; `[PRAISE]` — noteworthy quality.
- Every suggestion is actionable and includes a `suggestion` block where applicable.
- Tone is peer-to-peer; review is technical, never personal.

## Repository Conformance Gate
- `oaef doctor`
- `oaef lint`
- `oaef clean-code` (native: `swift tool/governance.swift clean-code`)
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Step 0 completed against the current main branch.
- Every finding carries a severity tier and an actionable suggestion.
- Findings are remediated across the pull request and its siblings.
- No `[BLOCKER]` remains open.

## Anti-Patterns
- A stale-branch review that flags code already fixed on main.
- Subjective taste presented as a blocker.
- A point fix that leaves the same defect in a sibling file.
- A finding with no actionable suggestion.
- An empty catch that is approved because "the error cannot happen".
