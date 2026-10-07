<!-- oaef:section:standard:review -->
# Code Review Standard

> The working reference for review findings: severity taxonomy, the actionable-suggestion requirement, holistic cascade remediation and the canonical-truth ingestion that precedes every review. The law lives in `AGENTS.md` §4.13 and §4.19.

---

## 1. Severity Taxonomy

Every finding opens with exactly one tag, in brackets, on its own line before the explanation.

| Tag | Meaning | Escalation rule |
| :--- | :--- | :--- |
| `[BLOCKER]` | Correctness, security, privacy or a failed Quality Gate. The change must not merge as-is. | Always resolves before merge; never downgraded to keep the branch moving. |
| `[MAJOR]` | A real defect or a violated invariant that will cause a follow-up fix. | Blocks merge on the same change set; may be tracked only with an explicit debt marker. |
| `[MINOR]` | A maintainability or clarity problem with a clear fix. | Fix in this change set unless the author records the reason to defer. |
| `[NIT]` | A cosmetic preference the toolchain does not enforce. | Optional; never a merge gate. |
| `[PRAISE]` | A specific good decision worth naming, so the pattern is reused. | None. |

**Escalation rule** — severity may be raised, never silently lowered. A `[BLOCKER]` becomes a `[MAJOR]` only with a written justification and a linked follow-up; a finding is never disappeared by re-tagging it a `[NIT]`.

---

## 2. Actionable Suggestion Requirement

A review states the problem, why it matters, and a concrete fix. Every behavioral finding carries a suggestion block the author can apply directly:

```suggestion
processEvents(events: List<Event> = emptyList)
```

A suggestion replaces the exact lines it is anchored to. When a suggestion is not possible (architectural change, missing context), the finding names the file:line and the canonical standard to follow instead of leaving prose to interpret.

---

## 3. Friendly Peer Tone

Review the change, not the person. Be direct and specific: name the pattern and the file, explain the consequence, propose the fix. No sarcasm, no "obviously", no personal attribution — say "this block swallows the error" rather than "you swallowed the error". Assume the author had a reason; ask when the reason is not evident.

---

## 4. Zero Emojis

Zero emojis appear in a review — not in the summary line, the tag, the finding body or the suggestion. Severity is carried by the tags of §1, not by decoration. This is enforced across the template and every review artifact.

---

## 5. Holistic Pattern Remediation (Cascade)

A finding is a pattern, not a line. When a defect is found:

1. Hunt the same pattern across the whole pull request and its sibling pull requests.
2. Correct every equivalent file in the same change set, or record the exception in `docs/wiki/memory/handoff.md`.
3. Name the pattern in the comment, so the fix generalizes rather than being applied at one call site.

A point fix that leaves the same defect one file over is an incomplete review.

---

## 6. Pre-Review Canonical Truth Ingestion (Step 0)

**Step 0** runs before the first comment. A review that skipped it is not a review.

1. `git fetch origin main` and absorb the canonical baseline: `AGENTS.md`, the accepted ADRs under `docs/adr/`, every file in `docs/standards/`, and `docs/wiki/`.
2. Rebase-awareness: never report a finding that exists only because the branch is stale — a false positive from an un-fetched `main` is a review defect, not an author defect.
3. Record the ingestion in the review entry point (the `Governing Skills` declaration and the PR checklist).

---

## 7. What a Review Is Not

* **Not subjective taste** — a preference that the toolchain does not enforce is a `[NIT]` at most; it never blocks and it never blocks on repetition.
* **Not isolated point fixes** — see §5; a single-line correction that ignores the pattern is incomplete.
* **Not formatting wars** — indentation, spacing, line wrapping and import ordering are the formatter's job; the reviewer does not re-litigate decisions already enforced by the toolchain.
* **Not a re-run of the static analysis** — `CC-*`, secret scanning and mirror parity are automated barriers (`oaef lint`, `oaef clean-code`); the reviewer cites the barrier instead of restating it.

Related standards: [`review.md`](review.md), [`governance_checks.md`](governance_checks.md), [`coding_patterns.md`](coding_patterns.md).

<!-- /oaef:section:standard:review -->
