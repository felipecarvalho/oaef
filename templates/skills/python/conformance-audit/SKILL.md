---
name: conformance-audit
description: >-
  Use when verifying that the repository, its skills or its governance artifacts conform to the framework in Python 3. Triggers on: "conformance", "doctor", "parity", "frontmatter". Chains into: code-review. Audits repository conformance: structure, mirror parity, the 13 skills with their frontmatter and harness mirrors, governance entrypoints and community files, then reports every divergence as a blocking finding.
argument-hint: "[scope: repository|skills|docs]"
license: MIT
metadata:
  framework: OAEF
  stack: python
  version: 1.1.0
---

# Conformance Audit (Python 3)

> **Stack Profile:** Python 3
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Prove the repository conforms to the framework: structure, skills, governance entrypoints
and community files. Every divergence is reported as a blocking finding with its path.

## Territory
- Repository root — meta-files (`AGENTS.md`, `CLAUDE.md`, `README.md`, `llms.txt`).
- `.agents/skills/` — the canonical catalog of 13 skills.
- Harness mirrors: `.claude/skills/`, `.cursor/rules/`, `.windsurf/skills/`,
  `.cline/skills/`, `.grok/agents/`.
- `docs/` — standards, ADRs and wiki artifacts.

## What This Skill Verifies
- Structure: the required standards, the `docs/wiki/` tree and the governance entrypoint.
- Skills: all 13 skills present, each with a conformant frontmatter and correct directory name.
- Mirror parity: every present harness mirror matches `.agents/skills/` content.
- Trigger coherence: every dispatch-matrix keyword appears in the matching skill frontmatter.
- Entrypoint parity: `llms.txt` lists all skills; `README.md`, `docs/INDEX.md` and
  `docs/MANIFESTO.md` reference `llms.txt`.
- Governance entrypoints: the native runner and the portable CLI agree on the command set.
- Community files: contribution, security and license artifacts are present.

## Deterministic Procedure
1. `oaef doctor` — structural and entrypoint conformance.
2. `oaef skills audit` — catalog parity, frontmatter quality, trigger coherence.
3. `oaef skills audit --selftest` — routing self-test across the canonical prompt fixtures.
4. `oaef skills route "<prompt>"` — spot-check a routing decision against its expected skill.
5. `oaef skills sync-mirrors --check` — verify each harness mirror matches the canonical source.
6. Frontmatter quality — `name` equals the directory, `Use when` plus `Triggers on:` plus
   `Chains into:` present, description at least 150 characters, no unknown keys.
7. Entrypoint parity — confirm every skill appears in `llms.txt` and every entrypoint
   references `llms.txt`.
8. Record every divergence with its path and the governing check identifier.

## Repository Conformance Gate
- `oaef doctor` — structural conformance.
- `oaef lint` — governance findings.
- `oaef clean-code` (native: `python3 tool/governance.py clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- All seven procedure steps pass, or each failure is reported as a blocking finding.
- Mirror parity and trigger coherence hold across the whole catalog.
- The routing self-test resolves every fixture prompt to its expected skill.

## Anti-Patterns
- Treating a mirror divergence as cosmetic instead of a blocking finding.
- Skipping the self-test because the catalog "looks complete".
- Reporting a missing skill without naming its expected directory.
- Editing the governance entrypoint in one place and not the other.
- Accepting a frontmatter without the `Triggers on:` contract.
