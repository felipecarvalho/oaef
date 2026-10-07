---
name: nullable-types
description: >-
  Use when a value can be absent, nil, null or optional in Python 3. Triggers on: "null", "optional", "nil", "guard clause", "defensive". Chains into: test-generator, run-static-analysis. Owns defensive null handling and non-nullable collection defaults in Python 3: absence carries business meaning, guard clauses return early instead of nesting, and a collection parameter defaults to a constant empty collection rather than an optional list.
argument-hint: "[path or type name]"
license: MIT
metadata:
  framework: OAEF
  stack: python
  version: 1.1.0
---

# Nullability Minimization (Python 3)

> **Stack Profile:** Python 3
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Make absence explicit and rare. `None` is a business signal, not a default placeholder,
and a collection parameter never asks callers to distinguish "missing" from "empty".

## Territory
- `src/<package>/` — production modules and type-annotated signatures.
- `<package>/features/<feature>/{domain,data}` — domain models and repositories.
- `src/<package>/di/`, `main.py` — composition root wiring.
- `tests/` — fixtures asserting the absent and empty cases.

## Conventions
- Type-hint with `T | None` and use `from __future__ import annotations` for modern unions.
- Reserve `None` for a meaningful state: unknown value, optional association, absent relation.
- Never use `None` as a stand-in for an empty string, empty list or zero.
- Never use `None` as a sentinel meaning "not provided yet"; return early or require the value.
- A function returning `X | None` must document the meaning of the absent branch.
- `Optional[Element]` in SQLAlchemy or dataclass fields requires a business reason in a comment.
- Prefer `dataclasses` and frozen models so absence is declared once and enforced by the type checker.

## Non-Nullable Collections
- A collection parameter defaults to a constant empty collection, never `None`:
  `items: Sequence[Item] = ()` or `items: Mapping[str, int] = MappingProxyType({})`.
- Never declare `items: list[Item] | None = None` in a public signature.
- Reject `Optional[list[...]]`, `Optional[dict[...]]`, `Optional[set[...]]` in signatures.
- For mutable defaults use `field(default_factory=list)`, never a shared mutable literal.
- Iterate the default directly; do not branch on `if items is None:` inside the body.
- The governance check `CC-08` blocks nullable collection parameters without a constant default.

## Guard Clauses
- Return or raise early at the top of the function; keep the happy path unindented.
- Prefer `if value is None: raise DomainError(...)`/`return default` over nested `if value:` blocks.
- Use `match` for multi-branch absence handling when it reads as a decision table.
- Collapse defensive chains: one guard at the boundary, not one per helper call.
- Do not swallow the absent case: route it to a logged domain error or a typed `Result`.
- A guard clause that only logs and continues is a defect; it must return or raise.

## Repository Conformance Gate
- `oaef doctor` — structural conformance.
- `oaef lint` — governance findings.
- `oaef clean-code` (native: `python3 tool/governance.py clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- No public signature exposes an optional collection without a constant empty default.
- Every `None` branch carries a documented business meaning.
- `mypy .` passes under strict optional checking with zero new `# type: ignore`.

## Anti-Patterns
- `def load(ids: list[int] | None = None):` requiring callers to pass an empty list.
- Using `None` to mean "empty" and forcing `if x is not None` checks downstream.
- Nested `if` pyramids where a single guard clause would return early.
- A locale/date formatting call that silently returns `None` and is then string-concatenated.
- Catch blocks that convert an exception into `None` without logging.
