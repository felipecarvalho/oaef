---
name: conformance-audit
description: >-
  Use when verifying that the repository, its skills or its governance artifacts conform to the framework in Universal / Polyglot. Triggers on: "conformance", "doctor", "parity", "frontmatter". Chains into: code-review. Audits repository conformance: structure, mirror parity, the 13 skills with their frontmatter and harness mirrors, governance entrypoints and community files, then reports every divergence as a blocking finding.
argument-hint: "[scope: repository|skills|docs]"
license: MIT
metadata:
  framework: OAEF
  stack: universal
  version: 1.1.0
---

# Conformance Audit (Universal / Polyglot)

> **Stack Profile:** Universal / Polyglot
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Prove the repository conforms to the framework: structure, skills, mirrors, governance entrypoints and community files. Every divergence is reported as a blocking finding.

## Territory
- Root meta-files: `AGENTS.md`, `CLAUDE.md`, `llms.txt`, `oaef.context.json`.
- `.agents/skills/**` and the harness mirror directories.
- `docs/**`, `docs/standards/**`, `docs/wiki/**` and `.github/**`.

## What This Skill Verifies
1. **Structure** — `AGENTS.md`, `CLAUDE.md`, `llms.txt`, `oaef.context.json` and the full `docs/` tree exist.
2. **Mirror parity** — `CLAUDE.md` mirrors `AGENTS.md`; harness mirrors match `.agents/skills/`.
3. **Skills** — the 13 canonical skills exist with valid frontmatter.
4. **Governance entrypoints** — `bash tool/governance.sh` exists and is executable.
5. **Community files** — `.github/` templates, CI workflow, `CONTRIBUTING.md`, `SECURITY.md`, `.gitignore`.
6. **Hygiene** — no unresolved `{{...}}` placeholders, no secrets, no unallowed suppressions.

## Deterministic Procedure
1. `oaef doctor` (native: `bash tool/governance.sh doctor`).
2. `oaef skills audit` and `oaef skills audit --selftest` (frontmatter quality and the routing fixture table, `SK-06`).
3. `oaef skills route "<prompt>"` for a spot check of dispatch resolution.
4. `oaef skills sync-mirrors --check` for mirror parity (`SK-05`).
5. `oaef lint` and `oaef audit` (native: `bash tool/governance.sh lint` / `bash tool/governance.sh quality-gate`).
6. Resolve every finding: restore from the framework templates, `oaef sync` on divergence, re-run the installer on a placeholder, raise the floor on a coverage miss.
7. Record the outcome in `docs/wiki/memory/handoff.md`.

## Repository Conformance Gate
- `oaef doctor`, `oaef lint` and `oaef clean-code` (native: `bash tool/governance.sh clean-code`) clean.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `oaef doctor` exits 0.
- `oaef skills audit --selftest` passes and mirrors are in parity.
- Zero parity, secret or suppression findings remain.

## Anti-Patterns
- Declaring completion with a failing conformance audit.
- Editing `CLAUDE.md` directly instead of `AGENTS.md` plus `oaef sync`.
- Lowering a baseline floor to make the audit pass.
