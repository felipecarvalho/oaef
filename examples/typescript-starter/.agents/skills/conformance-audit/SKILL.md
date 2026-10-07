---
name: conformance-audit
description: >-
  Use when verifying that the repository, its skills or its governance artifacts conform to the framework in TypeScript & Web. Triggers on: "conformance", "doctor", "parity", "frontmatter". Chains into: code-review. Audits repository conformance: structure, mirror parity, the 13 skills with their frontmatter and harness mirrors, governance entrypoints and community files, then reports every divergence as a blocking finding.
argument-hint: "[scope: repository|skills|docs]"
license: MIT
metadata:
  framework: OAEF
  stack: typescript-web
  version: 1.1.0
---

# Conformance Audit (TypeScript & Web)

> **Stack Profile:** TypeScript & Web
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission

Prove that the repository, its skills and its governance artifacts conform to the
framework, and report every divergence as blocking. This is the final deterministic check
before a task is declared complete.

## Territory

- `AGENTS.md`, `CLAUDE.md`, `llms.txt`, `oaef.context.json` — root meta-files.
- `.agents/skills/**` and the harness mirrors (`.claude/skills/`, `.cursor/rules/`,
  `.windsurf/skills/`, `.cline/skills/`, `.grok/agents/`).
- `docs/**`, `docs/standards/**`, `docs/wiki/**` — canonical documents and memory.
- `tool/governance.mjs` — the native governance runtime.

## What This Skill Verifies

1. **Structure** — `AGENTS.md`, `CLAUDE.md`, `llms.txt`, `oaef.context.json` and the full
   `docs/` tree are present.
2. **Skill parity** — all 13 canonical skills exist under `.agents/skills/`, each with
   `name` equal to its directory and a dense frontmatter (`Use when`, `Triggers on:`,
   `Chains into:`).
3. **Mirror parity** — `CLAUDE.md` mirrors `AGENTS.md`; each harness skills mirror matches
   `.agents/skills/` byte for byte.
4. **Trigger coherence** — every dispatch-matrix keyword appears in the matching skill
   frontmatter, and every catalog skill has a matrix row.
5. **Governance runtime** — `tool/governance.mjs` is present and executable.
6. **Entrypoint parity** — `llms.txt` lists all skills; `README.md`, `docs/INDEX.md` and
   `docs/MANIFESTO.md` reference `llms.txt`.
7. **Community files** — `.github/` templates, CI workflow, `CONTRIBUTING.md`,
   `SECURITY.md`, `.gitignore`.
8. **Hygiene** — no unresolved `{{...}}` placeholders, no secrets, no unallowed
   suppressions.

## Deterministic Procedure

1. `oaef doctor` (native: `node tool/governance.mjs doctor`) — structure, mirror and
   conformance checks.
2. `oaef skills audit` — frontmatter quality and skills parity (`SK-01`, `SK-02`, `SK-03`).
3. `oaef skills audit --selftest` — the routing self-test fixture table (`SK-06`).
4. `oaef skills route "<prompt>"` — spot-check that a sample intent resolves to the
   expected skill and recipe.
5. `oaef skills sync-mirrors --check` — harness mirror parity (`SK-05`).
6. `oaef lint` and `oaef clean-code` (native: `node tool/governance.mjs lint` /
   `node tool/governance.mjs clean-code`).
7. Resolve every divergence: restore a missing artifact from the framework templates;
   run `oaef sync` for mirror divergence; run `oaef skills sync-mirrors` for mirror
   drift; fix frontmatter in the source skill and re-run the audit.
8. Record the audit outcome and findings in `docs/wiki/memory/handoff.md`.
9. Never silence a failing gate; the Inviolable Trust Hierarchy prevails.

## Repository Conformance Gate

- Run `oaef doctor`, `oaef lint`, `oaef clean-code` (native:
  `node tool/governance.mjs doctor|lint|clean-code`).
- Run all five `oaef skills` subcommands above.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria

- `oaef doctor`, `oaef lint` and `oaef clean-code` exit 0.
- `oaef skills audit --selftest` and `oaef skills sync-mirrors --check` exit 0.
- No divergence remains, or each is recorded as a blocking finding.

## Anti-Patterns

- Declaring a task complete while a conformance check fails.
- Editing `CLAUDE.md` or a mirror directly instead of the source plus `oaef sync`.
- Loosening `baseline.json` floors to make the audit pass.
- Accepting a skill whose `name` does not match its directory.
