---
name: code-review
description: >-
  Use when reviewing a change or preparing a pull request in Universal / Polyglot. Triggers on: "review", "PR", "checklist", "pre-PR". Chains into: none (terminal skill of every recipe). Performs the pre-PR self-review for Universal / Polyglot: Step 0 ingests the canonical truth from the main branch, the severity taxonomy separates blockers from nits, and every finding is remediated holistically across the pull request and its sibling branches.
argument-hint: "[PR scope or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: universal
  version: 1.1.0
---

# Code Review (Universal / Polyglot)

> **Stack Profile:** Universal / Polyglot
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Perform the pre-PR self-review across every language touched by the change: ingest canonical truth first, separate blockers from nits, and remediate every finding across the whole pull request.

## Territory
- The whole pull request diff, across `.dart`, `.ts`, `.tsx`, `.js`, `.mjs`, `.cjs`, `.jsx`, `.py`, `.go`, `.rs`, `.kt`, `.kts`, `.swift`, `.cs`, `.sh`, `.bash`.
- Sibling branches that share the same pattern defect.

## Step 0 — Pre-Review Canonical Truth Ingestion
1. `git fetch origin main` and read `AGENTS.md`, accepted ADRs, `docs/standards/*` and `docs/wiki/` from the fetched main.
2. Reconcile the diff against that truth before reading a single hunk.
3. A finding that contradicts main is a finding against the author, not against the branch.

## Cascade Remediation
- A finding is hunted across the whole PR and every sibling branch.
- Fix the pattern holistically in every equivalent file; a one-file fix with siblings left broken is incomplete.
- The root cause is corrected once, in the shared location, not per call site.

## Ponytail Anti-Slop Hunt
Flag and delete, using the five remediation tags:
- `[DELETE]` — code with no consumer.
- `[STDLIB]` — hand-rolled logic a stdlib primitive replaces.
- `[NATIVE]` — custom code the platform already provides.
- `[YAGNI]` — speculative abstraction or unused extension point.
- `[SHRINK]` — a diff larger than the correct change requires.

## DRY Factory Audit
- Every test entity is built by one `make*` factory; duplicated arrange blocks are collapsed.
- Factories take only varying parameters; dead arguments are removed.
- Collection parameters default to a constant empty collection.

## Severity Taxonomy
- **Tier 1 `[BLOCKER]`** — correctness, security, data loss, a failed gate; must be fixed before merge.
- **Tier 2 `[MAJOR]`** — maintainability defect that will cost the next reader; fix in this PR.
- **Tier 3 `[MINOR]` / `[NIT]` / `[PRAISE]`** — style preference, small polish, or explicit recognition.

## Repository Conformance Gate
- `oaef doctor` and `oaef lint` clean for the touched repository.
- `oaef clean-code` (native: `bash tool/governance.sh clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Zero open Tier 1 findings; Tier 2 findings resolved or explicitly deferred with an owner.
- Every cascade sibling remediated.
- The PR body records the decisions and tradeoffs behind the change.

## Anti-Patterns
- Reviewing against a stale branch.
- Fixing one instance of a repeated defect.
- Raising a taste preference as a blocker.
