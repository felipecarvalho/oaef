---
name: code-review
description: >-
  Use when reviewing a change or preparing a pull request in Rust. Triggers on: "review", "PR",
  "checklist", "pre-PR". Chains into: none (terminal skill of every recipe). Performs the pre-PR
  self-review for Rust: Step 0 ingests the canonical truth from the main branch, the severity taxonomy
  separates blockers from nits, and every finding is remediated holistically across the pull request and
  its sibling branches.
argument-hint: "[PR scope or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: rust
  version: 1.1.0
---

# Pre-PR Self-Review (Rust)

> **Stack Profile:** Rust
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Review a Rust change before it is opened for review: ingest the current canonical rules, hunt anti-slop
and defects, and remediate every finding holistically across the pull request.

## Territory
- The whole pull request diff across `src/`, `tests/`, `examples/` and `Cargo.toml`.
- `docs/**` — any documentation touched by the change.
- Sibling branches that contain the same pattern under review.

## Step 0 — Pre-Review Canonical Truth Ingestion
- Run `git fetch origin main` and read `AGENTS.md`, accepted ADRs under `docs/adr/`, `docs/standards/*`
  and `docs/wiki/` from `main` before judging the diff.
- Confirm the branch is rebased on `main`; ignore findings already fixed upstream.

## Cascade Remediation
- A finding is hunted across the whole PR and its sibling branches, not only the touched lines.
- Fix every equivalent occurrence in the same change; a point fix that leaves the pattern elsewhere is
  incomplete.
- Record the incident in `docs/wiki/log.md` when a recurring finding is elevated to a rule.

## Ponytail Anti-Slop Hunt
Tag findings with the five remediation tags:
- `[DELETE]` — dead code, unused `pub fn`, unreachable arm.
- `[STDLIB]` — hand-rolled logic the stdlib already provides.
- `[NATIVE]` — copies or buffers that ownership and borrowing remove.
- `[YAGNI]` — speculative trait, generic or configuration with one caller.
- `[SHRINK]` — statements that reduce to one idiomatic expression.

## DRY Factory Audit
- Every entity under test has exactly one `make_<entity>()` factory.
- Factories expose only the parameters their suite varies; no dead parameters, no unused `Option` knobs.
- Duplicated literal construction across tests is a simplification finding.

## Severity Taxonomy
- Tier 1 `[BLOCKER]` — correctness, security, silent error swallowing, boundary or contract violation.
- Tier 2 `[MAJOR]` — Clean Sizing breach, missing error-branch test, suppressions, broken layering.
- Tier 3 `[MINOR]` / `[NIT]` / `[PRAISE]` — style, naming, wording; acknowledge good simplifications.
- Every finding carries an actionable suggestion, not a vague remark.

## Repository Conformance Gate
- `cargo run --bin governance -- clean-code`
- `oaef lint`, `oaef doctor`, `oaef audit`
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Zero open blockers; every Tier-1 and Tier-2 finding is fixed in the PR.
- The diff is rebased on `main` and reviewed holistically, not line by line.

## Anti-Patterns
- Reviewing without ingesting the current rules from `main`.
- Fixing one occurrence while sibling branches keep the defect.
- Subjective taste remarks without an actionable suggestion.
- Approving a change with an inline `#[allow]` or an empty error handler.
