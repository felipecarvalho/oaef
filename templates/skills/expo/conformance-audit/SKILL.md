---
name: conformance-audit
description: >-
  Use when verifying that the repository, its skills or its governance artifacts conform to the framework in Expo.
  Triggers on: "conformance", "doctor", "parity", "frontmatter". Chains into: code-review. Audits repository
  conformance: structure, mirror parity, the 13 skills with their frontmatter and harness mirrors, governance
  entrypoints and community files, then reports every divergence as a blocking finding.
argument-hint: "[scope: repository|skills|docs]"
license: MIT
metadata:
  framework: OAEF
  stack: expo
  version: 1.1.0
---

# Conformance Audit (Expo)

> **Stack Profile:** Expo
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Verify that the installed repository conforms to OAEF: structure, entrypoint parity, the 13 skills with valid frontmatter and harness mirrors, the governance runtime, and community files. Every divergence is a blocking finding.

## Territory
- Repository root meta-files: `AGENTS.md`, `CLAUDE.md`, `llms.txt`, `oaef.context.json`.
- `.agents/skills/` and the harness mirrors (`.claude/skills/`, `.cursor/rules/`, `.windsurf/skills/`, `.cline/skills/`, `.grok/agents/`).
- `tool/governance.mjs` - the native governance entrypoint.
- `docs/`, `.github/`, `CONTRIBUTING.md`, `SECURITY.md`, `.gitignore`.

## What This Skill Verifies
1. **Structure** - every canonical file and directory exists.
2. **Mirror parity** - `CLAUDE.md` is an exact mirror of `AGENTS.md`.
3. **Skills** - the 13 canonical skills exist under `.agents/skills/` with valid frontmatter.
4. **Harness mirrors** - each present mirror directory matches `.agents/skills/` byte for byte.
5. **Governance runtime** - `tool/governance.mjs` is present and executable.
6. **Community files** - `.github/` templates, the CI workflow, `CONTRIBUTING.md`, `SECURITY.md`, `.gitignore`.
7. **Hygiene** - no unresolved `{{...}}` placeholders, no secrets, no unallowed suppressions.

## Deterministic Procedure
1. Run the conformance audit: `oaef doctor` (native: `node tool/governance.mjs doctor`).
2. Audit the skill catalog and frontmatter quality: `oaef skills audit` (`node tool/governance.mjs skills-audit`).
3. Run the routing self-test: `oaef skills audit --selftest` (fails with `SK-06` on any divergence).
4. Probe the router: `oaef skills route "<prompt>"` must resolve the expected primary skill.
5. Validate harness mirrors: `oaef skills sync-mirrors --check` (`SK-05` on divergence).
6. Run `oaef lint` and `oaef audit`; resolve parity, secret, and suppression findings.
7. Fix each divergence: restore missing artifacts, `oaef sync` for mirror drift, `oaef skills sync-mirrors` for mirror repair, and raise baseline floors (never lower).
8. Record the outcome and every unresolved divergence in `docs/wiki/memory/handoff.md`.

## Repository Conformance Gate
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`) and fix every blocking finding.
- Run `oaef lint` and `oaef doctor`.
- Record the audit result and any deferred divergence in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `oaef doctor` exits 0 with all structural and skill checks passing.
- `oaef skills audit --selftest` and `oaef skills sync-mirrors --check` exit 0.
- `oaef lint` reports zero parity, secret, or suppression findings.

## Anti-Patterns
- Declaring a task complete with a failing conformance audit.
- Editing `CLAUDE.md` directly instead of `AGENTS.md` plus `oaef sync`.
- Silencing a failing gate by lowering a baseline floor.
