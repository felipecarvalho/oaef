---
name: conformance-audit
description: >-
  Use when verifying that the repository, its skills or its governance artifacts conform to the framework in C# / .NET. Triggers on: "conformance", "doctor", "parity", "frontmatter". Chains into: code-review. Audits repository conformance: structure, mirror parity, the 13 skills with their frontmatter and harness mirrors, governance entrypoints and community files, then reports every divergence as a blocking finding.
argument-hint: "[scope: repository|skills|docs]"
license: MIT
metadata:
  framework: OAEF
  stack: dotnet
  version: 1.1.0
---

# Conformance Audit (C# / .NET)

> **Stack Profile:** C# / .NET
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Prove the repository conforms to OAEF: canonical structure, the 13 skills with valid frontmatter, harness mirror parity, governance entrypoints and community files, with every divergence reported as blocking.

## Territory
- `.agents/skills/**/SKILL.md` — the canonical skill catalog.
- `.claude/skills/`, `.cursor/rules/`, `.windsurf/skills/`, `.cline/skills/`, `.grok/agents/` — harness mirrors.
- `AGENTS.md`, `CLAUDE.md`, `llms.txt`, `README.md`, `docs/INDEX.md`, `docs/MANIFESTO.md` — entrypoints.
- `tool/Governance.csproj`, `oaef.context.json`, `docs/wiki/metrics/baseline.json` — governance artifacts.

## What This Skill Verifies
- Structure: the five canonical standards, the 13 skills, the wiki memory files.
- Skill frontmatter quality: `Use when` + `Triggers on:` + `Chains into:`, density >= 150 characters, `name` equal to the directory, no unknown key.
- Entrypoint parity: `llms.txt` lists every skill, and `README.md`/`docs/INDEX.md`/`docs/MANIFESTO.md` reference `llms.txt`.
- Dispatch-matrix coherence: every matrix trigger appears in the matching skill.
- Harness mirror parity: each present mirror matches `.agents/skills/` byte for byte.
- Community files: `CONTRIBUTING.md`, `SECURITY.md`, the PR template.

## Deterministic Procedure
1. `oaef doctor` — structural and standard prerequisites.
2. `oaef skills audit` — `SK-01`/`SK-02`/`SK-03`/`SK-04`.
3. `oaef skills audit --selftest` — adds the routing fixture table (`SK-06`).
4. `oaef skills route "<prompt>"` — confirm a representative prompt resolves correctly.
5. `oaef skills sync-mirrors --check` — `SK-05` mirror parity.
6. Native form: `dotnet run --project tool/Governance.csproj skills-audit`.
7. Report every divergence with its check ID; never downgrade a blocking finding.

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint`, `oaef clean-code` or `dotnet run --project tool/Governance.csproj clean-code`.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `oaef doctor` exits 0 and `oaef skills audit --selftest` exits 0.
- Every present harness mirror matches the canonical catalog.
- No entrypoint parity or frontmatter finding remains open.

## Anti-Patterns
- Editing mirror directories by hand instead of `oaef skills sync-mirrors`.
- Downgrading a blocking conformance finding to a warning.
- Auditing skills without running the routing self-test.
