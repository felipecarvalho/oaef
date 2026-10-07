# Working Agreement for legacy-sample

> PROJECT-SPECIFIC-CONVENTIONS: this file is owned by the team. OAEF must never delete or rewrite it.

## 1. Project Conventions

- Report names are snake_case; API fields are snake_case; payload keys are frozen by the billing contract.
- Never touch the `billing_legacy` package without a migration note.

## 2. Build & Run

```bash
python3 -m legacy_reporting --date 2026-01-31
pytest -q
```

## 3. Team Rules

- Reviews need two approvals.
- Deploys happen on Tuesdays only.
- The `reporting_cache` table is pruned by the nightly job; do not add indexes without a DBA review.
