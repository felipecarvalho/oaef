---
name: code-review
description: Specialized code-review skill for Python 3 & FastAPI under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: python
  version: 1.0.0
---

# Code Review (Python 3 & FastAPI)

> **Stack Profile:** Python 3 & FastAPI  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Perform comprehensive pre-PR self-audits on all Python 3 & FastAPI contributions before declaring task completion.

## Audit Checklist
1. **Inviolable Trust Hierarchy**:
   - Compiler/Typechecker passes cleanly (`ruff check && mypy --strict`).
   - All tests pass (`pytest --cov=. --cov-report=lcov`).
   - Zero linter suppressions or unallowed ignores.
2. **Clean Sizing Verification**:
   - Zero files exceeding 300 LOC.
   - Zero methods exceeding 50 LOC.
3. **Living Memory Updates**:
   - `docs/wiki/memory/handoff.md` updated with accomplishments and next tasks.
   - `docs/wiki/log.md` appended if a milestone was reached.
   - Zero secrets, tokens, or PII committed.
4. **PR Template Compliance**:
   - Why and How sections filled in.
   - Zero empty checkboxes (`- [ ]`).
