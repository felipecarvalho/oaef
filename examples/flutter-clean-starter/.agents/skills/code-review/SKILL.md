---
name: code-review
description: >-
  Use when reviewing a change or preparing a pull request in Dart & Flutter. Triggers on: "review", "PR", "checklist", "pre-PR".
  Chains into: none (terminal skill of every recipe). Performs the pre-PR self-review for Dart & Flutter: Step 0 ingests the canonical truth from the main branch, the severity taxonomy separates blockers from nits, and every finding is remediated holistically across the pull request and its sibling branches.
argument-hint: "[PR scope or file path]"
license: MIT
metadata:
  framework: OAEF
  stack: dart-flutter
  version: 1.1.0
---

# Code Review (Dart & Flutter)

> **Stack Profile:** Dart & Flutter
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Perform the pre-PR self-review for a Dart and Flutter change. The review ingests canonical truth first, hunts anti-slop and factory duplication, classifies each finding by severity, and remediates every pattern holistically across the pull request.

## Territory
- the whole pull request — `lib/**`, `test/**`, `analysis_options.yaml`, `pubspec.yaml`.
- `docs/standards/**`, `docs/wiki/**` — the standards and memory the review validates against.
- `AGENTS.md`, `docs/adr/**` — the contract and accepted decisions ingested in Step 0.

## Step 0 — Pre-Review Canonical Truth Ingestion
Before reading the diff:
1. `git fetch origin main` and absorb `AGENTS.md` §3 and §4, the accepted ADRs in `docs/adr/**`, and the standards in `docs/standards/**`.
2. Re-read the operational memory in `docs/wiki/memory/handoff.md` and `docs/wiki/log.md`.
3. Rebase the review on the fresh `main` so stale-branch false positives do not appear.
4. Confirm the governing skills declared for the change match the territorial scope.

## Cascade Remediation
A finding is never fixed at a single point. When a defect is identified, grep the whole pull request and its sibling branches for the same pattern and remediate every occurrence in the same pass.

```bash
grep -rn "getIt<" lib/ | grep -v "lib/di/"
```

- A root cause fixed in one call site but not its siblings is an incomplete review.
- Flag the pattern with its remediation tag; do not accept a partial fix.

## Ponytail Anti-Slop Hunt
Sweep the diff for speculative and decorative code, tagging each occurrence:
- `[DELETE]` — narration comments, commented-out code, dead helpers, one-line pass-through layers.
- `[STDLIB]` — hand-rolled logic replaced by a `dart:core` primitive (`Iterable`, records, `switch` expression, `StringBuffer`).
- `[NATIVE]` — bespoke code replaced by a framework capability (`LayoutBuilder`, `TextScaler`, `SliverList`, theme lookup).
- `[YAGNI]` — a generic utility or single-implementation interface with no second caller.
- `[SHRINK]` — a per-call-site defensive branch that belongs at the shared root guard.

## DRY Factory Audit
- Exactly one `make<Entity>` factory per entity, shared by every suite; a duplicate factory is a `[MAJOR]` finding.
- Factories must not carry parameters no assertion observes (dead parameters).
- Fixtures are deterministic; a factory reading the wall clock or a random id is a `[BLOCKER]`.
- Optional collections in factories default to a constant empty collection (`CC-08`).

## Severity Taxonomy
- **Tier 1 `[BLOCKER]`** — correctness, security, silent exception swallowing, container or client leakage in domain code, nullable collections, unimplemented placeholders, failing analyzer or tests.
- **Tier 2 `[MAJOR]`** — boundary violations, duplicated factories, missing error-branch coverage, sizing breaches, root cause fixed at one site only.
- **Tier 3 `[MINOR]` / `[NIT]` / `[PRAISE]`** — naming, readability, consistency; `[PRAISE]` marks a notably clean simplification.

## Repository Conformance Gate
- `oaef doctor` — structural, skill and entrypoint conformance.
- `oaef lint` — `CC-*` advisory sweep plus `SK-01`…`SK-06` and secret detection.
- `oaef clean-code` (native: `dart run tool/governance.dart clean-code`) — blocking under the `strict` profile.
- `flutter test --coverage` and `dart analyze --fatal-infos` — both clean before approval.
- Unresolved findings are recorded in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every Tier 1 blocker is resolved or explicitly escalated with justification.
- No cascade finding remains unfixed in the pull request.
- The anti-slop tags are applied and their findings addressed.
- The PR template checkboxes are complete and the analyzer, tests and coverage gates pass.

## Anti-Patterns
- Reviewing on a stale branch and reporting already-fixed findings.
- Fixing one call site and ignoring the sibling occurrences of the same pattern.
- Marking a silent catch or a container leak as a nit.
- Subjective taste findings with no actionable suggestion.
- Accepting a duplicated factory or a dead parameter to keep the diff small.
