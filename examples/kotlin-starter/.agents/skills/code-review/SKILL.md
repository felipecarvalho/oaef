---
name: code-review
description: >-
  Use when reviewing a change or preparing a pull request in Kotlin & JVM. Triggers on: "review", "PR", "checklist", "pre-PR". Chains into: none (terminal skill of every recipe). Performs the pre-PR self-review for Kotlin & JVM: Step 0 ingests the canonical truth from the main branch, the severity taxonomy separates blockers from nits, and every finding is remediated holistically across the pull request and its sibling branches.
argument-hint: "[PR scope or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin
  version: 1.1.0
---

# Code Review (Kotlin & JVM)

> **Stack Profile:** Kotlin & JVM
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Run the pre-PR self-review against the canonical rules before opening the pull request.
Findings are separated by severity, remediated holistically, and never left as a list of
unfixed nits. The review is peer-toned, evidence-backed and emoji-free.

## Territory
- The whole pull request diff, plus sibling branches that share the same pattern.
- `src/main/`, `app/src/main/`, `src/test/`, `app/src/test/` — all touched sources.
- `docs/standards/*`, `docs/adr/` — the canonical rules being enforced.
- `docs/wiki/` — handoff and log that the change must update.

## Step 0 — Pre-Review Canonical Truth Ingestion
- `git fetch origin main` and rebase the review onto the current main.
- Re-read `AGENTS.md`, accepted ADRs under `docs/adr/`, and every `docs/standards/*`.
- A finding that contradicts canonical truth is not a finding; drop it.
- Only then begin reading the diff, so stale-branch false positives are avoided.

## Cascade Remediation
- Every finding is hunted across the whole PR, not just the flagged line.
- Search sibling branches and equivalent files for the same pattern.
- Fix the pattern holistically once; a single-point fix leaves latent duplicates.
- Document the rule elevated from the recurring finding when it applies more than twice.

## Ponytail Anti-Slop Hunt
Tag each candidate finding with one of the five tags:
- `[DELETE]` — dead code, unused symbol, orphaned file.
- `[STDLIB]` — hand-rolled logic the Kotlin stdlib already provides.
- `[NATIVE]` — custom widget the platform/Compose already offers.
- `[YAGNI]` — abstraction, flag or layer with no present caller.
- `[SHRINK]` — logic that fits in fewer lines without losing clarity.

## DRY Factory Audit
- One `make*` factory per test entity; no duplicated literal fixtures.
- No dead parameters and no `null` defaults standing in for "unused".
- Optional collections default to `emptyList()`/`emptyMap()` constants.

## Severity Taxonomy
- Tier 1 `[BLOCKER]` — correctness, security, privacy, data loss, failing gate.
- Tier 2 `[MAJOR]` — Clean Sizing breach, DI leak, swallowed exception, missing test.
- Tier 3 `[MINOR]`/`[NIT]`/`[PRAISE]` — naming, style, optional polish, good craft.
Each finding states the tier, the file:line, the rule, and a concrete suggestion block.

## Repository Conformance Gate
- Run `oaef doctor` (native: `kotlinc -script tool/governance.main.kts doctor`).
- Run `oaef lint`, `oaef clean-code` and `oaef quality-gate`.
- Record unresolved findings in `docs/wiki/memory/handoff.md` and append to `docs/wiki/log.md`.

## Exit Criteria
- Every `[BLOCKER]` and `[MAJOR]` finding is fixed, not merely listed.
- Cascade remediation applied across the PR and siblings.
- Handoff and log updated; no secrets, tokens or PII in the diff.
- The PR template has no empty checkboxes.

## Anti-Patterns
- Reviewing against a stale main and reporting resolved issues.
- Listing nits without fixing the blockers.
- Subjective taste presented as a rule; emojis or informal tone.
- Fixing one occurrence of a repeated pattern and moving on.
