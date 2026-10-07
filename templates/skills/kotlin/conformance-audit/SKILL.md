---
name: conformance-audit
description: >-
  Use when verifying that the repository, its skills or its governance artifacts conform to the framework in Kotlin & JVM. Triggers on: "conformance", "doctor", "parity", "frontmatter". Chains into: code-review. Audits repository conformance: structure, mirror parity, the 13 skills with their frontmatter and harness mirrors, governance entrypoints and community files, then reports every divergence as a blocking finding.
argument-hint: "[scope: repository|skills|docs]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin
  version: 1.1.0
---

# Conformance Audit (Kotlin & JVM)

> **Stack Profile:** Kotlin & JVM
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Prove the repository conforms to the framework: the right files exist, the 13 skills carry
valid frontmatter, the harness mirrors match their source, and the entrypoints agree. Every
divergence is a blocking finding, reported with the exact path and remedy.

## Territory
- `.agents/skills/<name>/SKILL.md` — the canonical 13 skills and their frontmatter.
- `.claude/skills/`, `.cursor/rules/`, `.windsurf/skills/`, `.cline/skills/`, `.grok/agents/` — harness mirrors.
- `AGENTS.md` §3.3, `README.md`, `llms.txt`, `docs/INDEX.md`, `docs/MANIFESTO.md` — entrypoints.
- `docs/standards/*`, `oaef.context.json`, `docs/wiki/metrics/baseline.json` — governance artifacts.

## What This Skill Verifies
- Structure: every mandatory file and directory exists at the expected path.
- Skills: 13 skills present; `name` equals the directory; `description` starts with `Use when`
  and carries `Triggers on:` and `Chains into:`; density at least 150 characters.
- Trigger coherence: each dispatch-matrix keyword appears in the matching skill's `Triggers on:`.
- Mirror parity: each harness mirror is byte-identical to `.agents/skills`.
- Entrypoint parity: `llms.txt` lists all skills; README/INDEX/MANIFESTO reference `llms.txt`.
- Community files: PR template, handoff and log present and non-empty.

## Deterministic Procedure
1. `oaef doctor` (native: `kotlinc -script tool/governance.main.kts doctor`) — structure and parity.
2. `oaef skills audit` — frontmatter quality, catalog parity, trigger coherence (`SK-01`..`SK-04`).
3. `oaef skills audit --selftest` — routing fixture table (`SK-06`).
4. `oaef skills route "<prompt>"` — spot-check that a prompt resolves to the expected skill.
5. `oaef skills sync-mirrors --check` — mirror parity (`SK-05`).
6. `oaef lint` — entrypoint parity across `llms.txt`, `README.md` and `docs/INDEX.md`.
Record every divergence as a blocking finding with its check ID.

## Repository Conformance Gate
- Run `oaef doctor` and `oaef lint` as the entry condition for any audit.
- A failing conformance or lint check blocks approval.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `oaef doctor`, `oaef lint` and `oaef skills audit --selftest` all exit zero.
- Every harness mirror matches `.agents/skills` and `--check` reports no divergence.
- Entrypoints list all 13 skills and reference `llms.txt`.
- Every divergence is either fixed or recorded with a tracked remedy.

## Anti-Patterns
- Treating a mirror divergence as cosmetic; it breaks harness activation.
- Editing a skill body but not re-running `oaef skills sync-mirrors`.
- Skipping the routing self-test and assuming dispatch works.
- Reporting conformance as green while an entrypoint still lists fewer than 13 skills.
