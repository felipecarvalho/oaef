---
name: conformance-audit
description: >-
  Use when verifying that the repository, its skills or its governance artifacts conform to the framework in Dart & Flutter. Triggers on: "conformance", "doctor", "parity", "frontmatter".
  Chains into: code-review. Audits repository conformance: structure, mirror parity, the 13 skills with their frontmatter and harness mirrors, governance entrypoints and community files, then reports every divergence as a blocking finding.
argument-hint: "[scope: repository|skills|docs]"
license: MIT
metadata:
  framework: OAEF
  stack: dart-flutter
  version: 1.1.0
---

# Conformance Audit (Dart & Flutter)

> **Stack Profile:** Dart & Flutter
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Verify that the repository conforms to the framework as installed: the structural tree, the 13 canonical skills, the harness mirrors, the governance entrypoints and the community files. Each divergence is reported as a blocking finding with the exact command that restores conformance.

## Territory
- `.agents/skills/**` — the canonical skill catalog (13 skills, one `SKILL.md` each).
- `.claude/skills/**`, `.cursor/rules/**`, `.windsurf/skills/**`, `.cline/skills/**`, `.grok/agents/**` — harness mirrors of the catalog.
- `AGENTS.md`, `CLAUDE.md`, `llms.txt`, `README.md` — entrypoints and parity targets.
- `docs/**`, root meta-files — standards, index, memory and community files.
- `tool/governance.dart` — the native governance engine.

## What This Skill Verifies
- **Structure** — the expected tree exists (production roots, test roots, docs, tool) with no missing or unexpected top-level artifact.
- **Skill catalog** — all 13 skills are present, each with a `SKILL.md`; names match directories.
- **Frontmatter quality** — every description starts with `Use when`, carries `Triggers on:` and `Chains into:`, has at least 150 characters, and uses only allowlisted keys.
- **Mirror parity** — each present harness directory mirrors `.agents/skills/` byte for byte.
- **Entrypoint parity** — `llms.txt` lists every skill; `README.md`, `docs/INDEX.md` and `docs/MANIFESTO.md` reference `llms.txt`; `AGENTS.md` lists the catalog.
- **Governance** — `tool/governance.dart` exposes every subcommand the framework declares.
- **Community files** — contribution, security and PR templates are present where required.

## Deterministic Procedure
1. Run `oaef doctor` to check structure, standards and entrypoints; any failure is a blocker.
2. Run `oaef skills audit` to validate the catalog, frontmatter quality, trigger coherence and entrypoint parity.
3. Run `oaef skills audit --selftest` to confirm the routing fixture table resolves exactly (`SK-06`).
4. Run `oaef skills route "review my PR before I open it"` and confirm the router resolves the expected primary skill and reports its recipes.
5. Run `oaef skills sync-mirrors --check` to detect harness mirror divergence without writing.
6. Run `oaef lint` and `oaef clean-code` (native: `dart run tool/governance.dart clean-code`) for the governance and clean-code pass.
7. Report each divergence with its `SK-*` or `CC-*` identifier and the restoring command; record unresolved findings in `docs/wiki/memory/handoff.md`.

```bash
oaef doctor
oaef skills audit --selftest
oaef skills sync-mirrors --check
```

## Repository Conformance Gate
- `oaef doctor` — structural, skill and entrypoint conformance.
- `oaef lint` — `CC-*` advisory sweep plus `SK-01`…`SK-06` and secret detection.
- `oaef clean-code` (native: `dart run tool/governance.dart clean-code`) — blocking under the `strict` profile.
- `oaef skills sync-mirrors [--check]` — mirror parity (`SK-05`).
- Unresolved findings are recorded in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `oaef doctor`, `oaef skills audit` and `oaef skills audit --selftest` exit clean.
- Every harness mirror present matches `.agents/skills/` byte for byte.
- All 13 skills exist with conformant frontmatter and a dispatch-matrix row.
- Every entrypoint lists the catalog and references `llms.txt`.

## Anti-Patterns
- Reporting a divergence without the command that restores conformance.
- Overwriting a user-modified mirror instead of running `oaef skills sync-mirrors` deliberately.
- Treating a frontmatter or mirror divergence as advisory when it blocks skill activation.
- Skipping the routing self-test because the catalog "looks complete".
- Auditing only `.agents/skills/` and ignoring the harness mirrors entirely.
