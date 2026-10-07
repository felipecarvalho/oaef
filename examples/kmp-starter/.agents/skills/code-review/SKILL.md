---
name: code-review
description: >-
  Use when reviewing a change or preparing a pull request in Kotlin Multiplatform. Triggers on: "review", "PR", "checklist", "pre-PR". Chains into: none (terminal skill of every recipe). Performs the pre-PR self-review for Kotlin Multiplatform: Step 0 ingests the canonical truth from the main branch, the severity taxonomy separates blockers from nits, and every finding is remediated holistically across the pull request and its sibling branches.
argument-hint: "[PR scope or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.1.0
---

# Code Review (Kotlin Multiplatform)

> **Stack Profile:** Kotlin Multiplatform
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Review the change against the canonical rules of the repository, not against taste, and remediate every finding across the whole pull request before it is opened.

## Territory
- The whole pull request diff across `src/commonMain/`, `src/androidMain/`, `src/iosMain/`, `src/desktopMain/`.
- `src/commonTest/`, `src/androidUnitTest/`, `src/iosTest/` - test changes are reviewed with the same rigor.
- `build.gradle.kts`, `gradle/libs.versions.toml` - dependency and target changes.
- `docs/**` - standards, ADRs and wiki entries touched by the change.

## Step 0 - Pre-Review Canonical Truth Ingestion
- Run `git fetch origin main` and read `AGENTS.md`, the accepted ADRs, `docs/standards/*` and `docs/wiki/` before reading the diff.
- Declare the governing skills first: `> Governing Skills: [.agents/skills/ponytail/SKILL.md, ...]`.
- Rebase or merge `main` mentally: a finding that already exists on `main` is not introduced by this PR and is reported as pre-existing.
- Confirm the branch is current; reviewing a stale branch produces false positives.
- Never review against remembered rules; always against the ingested canonical text.

## Cascade Remediation
- Every finding is hunted across the entire PR and its sibling branches, not fixed only where it was spotted.
- A pattern defect (the same anti-pattern in three files) is fixed in all three in this change, or filed with an owner.
- Applying a fix to one call site while leaving its siblings is a blocker.
- Prefer the shared root fix over the per-call-site fix (`ponytail`).
- Re-scan after remediation; a cascade is complete only when the pattern is gone from the tree.

## Ponytail Anti-Slop Hunt
- `[DELETE]` - dead code, unused parameter, unreachable branch, commented-out block.
- `[STDLIB]` - a hand-rolled fold/map/filter where `kotlin` stdlib or `Flow` operators exist.
- `[NATIVE]` - a platform fork where `expect/actual` or a Compose primitive suffices.
- `[YAGNI]` - an interface, generic or configuration seam with a single implementation and no mock need.
- `[SHRINK]` - an oversized file or composable that decomposes into smaller units.
- Report each candidate as `[TAG] <path>:<line> - <reason>`, matching `oaef ponytail audit`.

## DRY Factory Audit
- Each test entity has exactly one `make<Entity>` factory.
- No factory parameter is dead; no `null` default stands in for a real value.
- Optional collections in factories default to `emptyList()`, never `null`.
- Two factories for the same entity, or copy-pasted literals across tests, are blockers.

## Severity Taxonomy
- **Tier 1 `[BLOCKER]`** - correctness, silent exception swallowing (`CC-06`), container leakage (`CC-07`), unimplemented placeholders (`CC-09`), a nullable collection (`CC-08`), a broken target build, a broken test, a lowered coverage floor.
- **Tier 2 `[MAJOR]`** - boundary violation, cyclic dependency, missing error-branch test, oversized file, ceremony layer, missing preview for a public surface.
- **Tier 3 `[MINOR]` / `[NIT]` / `[PRAISE]`** - naming, formatting, optional polish, and explicit acknowledgment of good work.
- Every finding names the file, the line and the concrete correction; subjective taste is not a finding.

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint`, `oaef clean-code` (native: `kotlinc -script tool/governance.main.kts clean-code`) and `oaef skills audit --selftest`.
- Run `./gradlew detekt` and `./gradlew allTests`.
- Record unresolved non-blocking findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Zero Tier 1 and Tier 2 findings remain open at submission.
- Every finding has a suggested concrete edit, not a vague complaint.
- The PR description names the governing skills and the ponytail decisions taken.

## Anti-Patterns
- Reviewing a stale branch and reporting already-merged findings.
- Fixing an instance without cascading the fix to its siblings.
- Reporting style preferences as blockers.
