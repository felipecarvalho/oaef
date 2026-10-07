---
name: conformance-audit
description: >-
  Use when verifying that the repository, its skills or its governance artifacts conform to the framework in React Native. Triggers on: "conformance", "doctor", "parity", "frontmatter". Chains into: code-review. Audits repository conformance: structure, mirror parity, the 13 skills with their frontmatter and harness mirrors, governance entrypoints and community files, then reports every divergence as a blocking finding.
argument-hint: "[scope: repository|skills|docs]"
license: MIT
metadata:
  framework: OAEF
  stack: react-native
  version: 1.1.0
---

# Conformance Audit (React Native)

> **Stack Profile:** React Native
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Prove the repository still conforms to OAEF: structure, skills, mirrors, entrypoints and governance wiring. Conformance is executable, not asserted: every claim is backed by a command and its exit status.

## Territory
- `AGENTS.md`, `CLAUDE.md`, `llms.txt` — canonical contract and its mirror.
- `.agents/skills/**` — the 13 canonical skills.
- `.claude/skills/`, `.cursor/rules/`, `.windsurf/skills/`, `.cline/skills/`, `.grok/agents/` — harness mirrors.
- `docs/standards/**`, `docs/INDEX.md`, `docs/wiki/**` — standards and memory.
- `tool/` — governance entrypoint (`tool/governance.mjs`).

## What This Skill Verifies
- **Structure** — expected directories, standards documents and community files exist.
- **Skills** — the catalog holds exactly 13 skills; each `SKILL.md` name equals its directory.
- **Frontmatter quality** — `description` starts with `Use when`, contains `Triggers on:` and `Chains into:`, and is at least 150 characters dense.
- **Mirror parity** — every present harness directory carries the same skill content (hash-equal) as `.agents/skills/`.
- **Trigger coherence** — every dispatch-matrix keyword appears in the matching skill's frontmatter.
- **Routing self-test** — the canonical prompt-to-skill fixtures resolve exactly.
- **Entrypoint parity** — `llms.txt` lists all skills and `README.md`/`docs/INDEX.md` reference it.

## Deterministic Procedure
1. `oaef doctor` (native: `node tool/governance.mjs doctor`) — structure, standards, entrypoints.
2. `oaef skills audit` — catalog, frontmatter quality, trigger coherence, mirror parity.
3. `oaef skills audit --selftest` — routing fixture table; fails with `SK-06` on any divergence.
4. `oaef skills route "<prompt>"` — spot-check dispatch for a representative intent.
5. `oaef skills sync-mirrors --check` — validate harness mirrors without writing; `oaef skills sync-mirrors` repairs them.
6. `oaef lint` (native: `npx eslint .`) and `oaef clean-code` (native: `node tool/governance.mjs clean-code`) — governance checks.
7. Record every unresolved divergence in `docs/wiki/memory/handoff.md`.

## Repository Conformance Gate
- Run `oaef doctor` (native: `node tool/governance.mjs doctor`).
- Run `oaef lint` (native: `npx eslint .`).
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every command above exits 0 for the audited scope.
- Exactly 13 skills are present with valid, coherent frontmatter.
- Harness mirrors are hash-equal; the routing self-test passes.

## Anti-Patterns
- Declaring conformance from a partial run.
- Repairing a mirror by hand instead of `oaef skills sync-mirrors`.
- Adding a skill without a dispatch-matrix row and frontmatter triggers.
- Treating a divergence as a warning when it is a blocking finding.
