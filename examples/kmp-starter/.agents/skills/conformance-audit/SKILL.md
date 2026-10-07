---
name: conformance-audit
description: >-
  Use when verifying that the repository, its skills or its governance artifacts conform to the framework in Kotlin Multiplatform. Triggers on: "conformance", "doctor", "parity", "frontmatter". Chains into: code-review. Audits repository conformance: structure, mirror parity, the 13 skills with their frontmatter and harness mirrors, governance entrypoints and community files, then reports every divergence as a blocking finding.
argument-hint: "[scope: repository|skills|docs]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.1.0
---

# Conformance Audit (Kotlin Multiplatform)

> **Stack Profile:** Kotlin Multiplatform
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Answer one question with evidence: does this repository conform to OAEF v1.1.0? Every divergence is reported with the file and the violated invariant, never as a bare warning.

## Territory
- `.agents/skills/**` - the canonical skill catalog (13 skills).
- `.claude/skills/**`, `.cursor/rules/**`, `.windsurf/skills/**`, `.cline/skills/**`, `.grok/agents/**` - harness mirrors.
- `AGENTS.md`, `CLAUDE.md`, `llms.txt`, `README.md` - entrypoints and catalog declarations.
- `docs/standards/**`, `docs/INDEX.md`, `docs/wiki/**` - standards, index and memory.
- `tool/governance.main.kts`, `oaef.context.json` - governance entrypoint and framework metadata.

## What This Skill Verifies
- **Structure** - every mandatory file exists: the 13 skills, the standard documents, `AGENTS.md`, `llms.txt`, `oaef.context.json`.
- **Frontmatter quality** - `name` equals the directory, `description` starts with `Use when`, contains `Triggers on:` and `Chains into:`, exceeds 150 characters, and no unknown key is present (`SK-02`).
- **Trigger coherence** - every dispatch-matrix trigger keyword appears in the matching skill frontmatter, and every catalog skill has a matrix row (`SK-04`).
- **Parity** - every skill is listed in `README.md`, `AGENTS.md` and `llms.txt`; the entrypoints reference `llms.txt` (`SK-01`, `SK-03`).
- **Harness mirrors** - each present mirror directory carries every skill with identical content to `.agents/skills` (`SK-05`).
- **Routing** - the twelve prompt-to-skill fixtures resolve exactly as specified (`SK-06`).
- **Governance** - `clean-code`, `lint`, `doctor` and `quality-gate` run in the stack and read the baseline.
- **Community files** - `CONTRIBUTING.md`, `SECURITY.md` and the PR template are present.

## Deterministic Procedure
1. `oaef doctor` - validate the repository structure, mandatory files and framework metadata; exit 0 required.
2. `oaef skills audit` - validate the 13 skills, their frontmatter and their parity across `README.md`, `AGENTS.md` and `llms.txt`.
3. `oaef skills audit --selftest` - run the routing fixture table and fail with `SK-06` on any divergence.
4. `oaef skills route "<prompt>"` - spot-check a real prompt resolves to the expected primary skill and prints its recipe.
5. `oaef skills sync-mirrors --check` - validate every present harness mirror against `.agents/skills` (`SK-05`).
6. `oaef lint` - run the `SK-*` and secret checks; `oaef clean-code` (native: `kotlinc -script tool/governance.main.kts clean-code`) for the `CC-*` barrier.
7. `oaef quality-gate` - enforce coverage, sizing and clean-code floors against `docs/wiki/metrics/baseline.json`.
8. Report each divergence as a blocking finding with path and invariant; a clean run is the only pass.

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint`, `oaef clean-code` (native: `kotlinc -script tool/governance.main.kts clean-code`) and `oaef skills audit --selftest`.
- Record every unresolved divergence in `docs/wiki/memory/handoff.md` with the owning skill.

## Exit Criteria
- `oaef doctor`, `oaef lint` and `oaef skills audit --selftest` all exit 0.
- Every harness mirror present in the tree matches the canonical catalog byte for byte.
- No finding is reported without its file path and violated invariant.

## Anti-Patterns
- Treating a warning as acceptable because the build still runs.
- Fixing the mirror by hand instead of running `oaef skills sync-mirrors`.
- Auditing only the skills and skipping the entrypoint and governance parity.
