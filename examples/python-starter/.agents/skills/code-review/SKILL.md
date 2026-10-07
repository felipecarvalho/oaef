---
name: code-review
description: >-
  Use when reviewing a change or preparing a pull request in Python 3. Triggers on: "review", "PR", "checklist", "pre-PR". Chains into: none (terminal skill of every recipe). Performs the pre-PR self-review for Python 3: Step 0 ingests the canonical truth from the main branch, the severity taxonomy separates blockers from nits, and every finding is remediated holistically across the pull request and its sibling branches.
argument-hint: "[PR scope or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: python
  version: 1.1.0
---

# Code Review (Python 3)

> **Stack Profile:** Python 3
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Perform the pre-PR self-review against the canonical truth, classify every finding by
severity, and remediate each finding holistically across the whole change.

## Territory
- The diff of the pull request under review.
- `docs/standards/` — the canonical coding, testing, logging and governance standards.
- `docs/adr/` — accepted architecture decisions.
- `docs/wiki/` — log, handoff and metrics context.

## Step 0 — Pre-Review Canonical Truth Ingestion
- Run `git fetch origin main` before reading the diff.
- Absorb `AGENTS.md`, the accepted ADRs in `docs/adr/`, the documents under
  `docs/standards/` and the current `docs/wiki/` state.
- Re-base the review lens on the current main, not on a stale local branch.
- Any finding already resolved upstream is not repeated.

## Cascade Remediation
- A finding is not fixed until it is hunted across the entire pull request.
- `grep -rn` each pattern flagged once; fix every equivalent occurrence in the change.
- Check sibling branches touching the same module; report the same defect there.
- Never leave an isolated point fix when the pattern repeats in the same change.

## Ponytail Anti-Slop Hunt
Tag every simplification opportunity:
- `[DELETE]` dead code, unused imports, unreachable branches, commented-out blocks.
- `[STDLIB]` hand-rolled logic a stdlib primitive already provides.
- `[NATIVE]` a wrapper hiding a platform or framework capability.
- `[YAGNI]` speculative options, flags or hooks with no caller.
- `[SHRINK]` duplicated blocks that should share one guard.
Also flag surviving `# ponytail:` markers whose evolution trigger has been met.

## DRY Factory Audit
- One factory per entity; duplicated builders across test modules are a finding.
- Every factory parameter must be varied by at least one test; dead parameters are removed.
- Factories must default collection parameters to a constant empty collection.

## Severity Taxonomy
- Tier 1 `[BLOCKER]` — correctness, silent exception swallowing, dependency inversion
  breach, nullable collection in a public signature, unimplemented placeholder.
- Tier 2 `[MAJOR]` — missing error-branch test, duplicated pattern, naming violation.
- Tier 3 `[MINOR]`/`[NIT]`/`[PRAISE]` — style, readability, and explicit acknowledgment
  of a well-executed decision.

## Repository Conformance Gate
- `oaef doctor` — structural conformance.
- `oaef lint` — governance findings.
- `oaef clean-code` (native: `python3 tool/governance.py clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every Tier 1 and Tier 2 finding is remediated in the change, not deferred.
- Cascade remediation covers all sibling occurrences and branches.
- The review comment set names each finding with its severity tag.

## Anti-Patterns
- Reviewing against a stale local branch and reporting resolved findings.
- Fixing one occurrence while the pattern repeats elsewhere in the diff.
- Approving a change whose failing tests are only disabled or skipped.
- Subjective style preferences raised without a standard backing them.
- Leaving a blocker as an open comment instead of fixing it in the change.
