---
name: code-review
description: >-
  Use when reviewing a change or preparing a pull request in Go. Triggers on: "review", "PR", "checklist", "pre-PR". Chains into: none (terminal skill of every recipe). Performs the pre-PR self-review for Go: Step 0 ingests the canonical truth from the main branch, the severity taxonomy separates blockers from nits, and every finding is remediated holistically across the pull request and its sibling branches.
argument-hint: "[PR scope or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: go
  version: 1.1.0
---

# Code Review (Go)

> **Stack Profile:** Go
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Perform the pre-PR self-review for a Go change: ingest the canonical truth first, hunt anti-slop, audit test factories, and remediate every finding holistically before opening the pull request.

## Territory
- The whole pull request — every `*.go` file it touches.
- Sibling branches that repeat the same pattern.
- `docs/wiki/memory/handoff.md` and `docs/wiki/log.md` — the living memory updated by the review.

## Step 0 — Pre-Review Canonical Truth Ingestion
- `git fetch origin main` and rebase the review surface onto the canonical head.
- Re-read `AGENTS.md`, the accepted ADRs under `docs/adr/`, `docs/standards/*` and `docs/wiki/` before judging the diff.
- A stale-branch false positive (flagging something `main` already changed) is a review defect, not a code defect.
- Declare the governing skills read for this review on one line before any comment.

## Cascade Remediation
- Every finding is hunted across the entire pull request and its sibling branches.
- A pattern fixed in one file is fixed in every equivalent file; an isolated point fix is incomplete.
- Re-run `go vet ./...`, `golangci-lint run` and `oaef clean-code` after the cascade.

## Ponytail Anti-Slop Hunt
Apply the five remediation tags to every added line:
- `[DELETE]` — dead function, unused export, unreachable branch.
- `[STDLIB]` — hand-rolled helper replaced by `slices`, `maps` or `strings`.
- `[NATIVE]` — custom machinery replaced by `context`, `net/http` or the toolchain.
- `[YAGNI]` — speculative genericity or an interface with one caller.
- `[SHRINK]` — code kept but reduced to its minimum correct form.

## DRY Factory Audit
- One `make<Entity>` factory per entity; only varying fields are parameters.
- No dead parameters, no nil collections passed at the call site.
- Deterministic data only; no real clock or network.
- Optional collection defaults come from the factory, not the test body.

## Severity Taxonomy
- **Tier 1 `[BLOCKER]`** — correctness, silent error swallowing, `CC-*` blocking finding, failing Quality Gate, security or data loss. Blocks the pull request.
- **Tier 2 `[MAJOR]`** — architectural violation, missing error branch, duplicated logic, oversized file or function. Must be fixed before merge.
- **Tier 3 `[MINOR]` / `[NIT]` / `[PRAISE]`** — naming, comment wording, style; `[PRAISE]` records a good decision. Never blocks.
- Every actionable finding carries a concrete suggestion, never a bare criticism.

## Repository Conformance Gate
- Run `oaef doctor` (native: `go run tool/governance.go doctor`).
- Run `oaef lint` (native: `go run tool/governance.go lint`).
- Run `oaef clean-code` (native: `go run tool/governance.go clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Step 0 ran against the canonical head; no stale-branch findings remain.
- Every Tier 1 and Tier 2 finding is remediated across the whole PR.
- The review closes with `oaef doctor` and `oaef clean-code` both green.

## Anti-Patterns
- Reviewing against a stale `main`.
- A subjective taste comment presented as a blocker.
- Fixing a pattern at one site and leaving its siblings.
- Approving a diff with a silent `catch`/error discard or a failed Quality Gate.
