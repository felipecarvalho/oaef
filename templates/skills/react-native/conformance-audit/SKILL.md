---
name: conformance-audit
description: Repository conformance audit skill for React Native under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: react-native
  version: 1.0.0
---

# Conformance Audit (React Native)

> **Stack Profile:** React Native  
> **Trigger:** Before declaring any task complete, before a Pull Request, or when onboarding an existing repository.

## What This Skill Verifies
1. **Structure** — `AGENTS.md`, `CLAUDE.md`, `llms.txt`, `oaef.context.json`, the full `docs/` tree, `docs/HARNESSES.md`.
2. **Mirror parity** — `CLAUDE.md` is an exact mirror of `AGENTS.md`.
3. **Skills** — the 11 canonical skills exist under `.agents/skills/`.
4. **Governance runtime** — `tool/governance.*` is present and executable.
5. **Community files** — `.github/` templates, CI workflow, `CONTRIBUTING.md`, `SECURITY.md`, `.gitignore`.
6. **Hygiene** — no unresolved `{{...}}` placeholders, no secrets, no unallowed suppressions.

## Deterministic Procedure
1. Run the conformance audit:
   `oaef doctor` (native: `node tool/governance.mjs doctor`).
2. Run the quality audits:
   `oaef lint` and `oaef audit` (native: `node tool/governance.mjs lint` / `node tool/governance.mjs quality-gate`).
3. Resolve every ❌:
   - Missing artifact → restore it from the OAEF framework templates.
   - Mirror divergence → `oaef sync`.
   - Unresolved placeholder → re-run the installer with `--backup --force` or fix the file manually.
   - Baseline/coverage failure → follow `docs/wiki/metrics/baseline.json` (Monotonic Ratchet: raise the floor, never lower it).
4. Record the audit outcome (pass/fail + findings) in `docs/wiki/memory/handoff.md`.
5. NEVER silence a failing gate; the Inviolable Trust Hierarchy always prevails.

## Exit Criteria
- `oaef doctor` exits 0 (all checks passed).
- `oaef lint` reports zero parity, secret, or suppression findings.
- `oaef audit` satisfies the baseline coverage and clean sizing floors.

## Anti-Patterns
- Declaring a task complete with a failing conformance audit.
- Editing `CLAUDE.md` directly instead of `AGENTS.md` + `oaef sync`.
- Loosening `baseline.json` floors to make the audit pass.
