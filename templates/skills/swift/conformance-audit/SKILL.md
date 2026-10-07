---
name: conformance-audit
description: >-
  Use when verifying that the repository, its skills or its governance artifacts conform to the framework in Swift. Triggers on: "conformance", "doctor", "parity", "frontmatter". Chains into: code-review. Audits repository conformance: structure, mirror parity, the 13 skills with their frontmatter and harness mirrors, governance entrypoints and community files, then reports every divergence as a blocking finding.
argument-hint: "[scope: repository|skills|docs]"
license: MIT
metadata:
  framework: OAEF
  stack: swift
  version: 1.1.0
---

# Conformance Audit (Swift)

> **Stack Profile:** Swift
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Verify that a Swift repository and its governance artifacts conform to the framework. The audit is deterministic: it names the exact command, the exact divergence and the exact fix, and reports nothing that it did not observe.

## Territory
- Root meta-files: `AGENTS.md`, `CLAUDE.md`, `llms.txt`, `oaef.context.json`.
- `docs/` — standards, ADRs, index and wiki.
- `.agents/skills/` and the harness mirrors under `.claude/`, `.cursor/`, `.windsurf/`, `.cline/`, `.grok/`.
- `Package.swift` and `Sources/` — structure and entrypoint parity.

## What This Skill Verifies
- Repository structure: required directories, standards and community files present.
- Skill catalog: the 13 canonical skills exist with the correct frontmatter.
- Mirror parity: each harness mirror matches `.agents/skills/` by content hash.
- Frontmatter quality: `Use when`, `Triggers on:` and `Chains into:` present and dense.
- Entrypoint parity: `llms.txt`, `README.md`, `docs/INDEX.md` and `docs/MANIFESTO.md` agree.
- Governance entrypoints: native tooling wired and reachable.

## Deterministic Procedure
1. Run `oaef doctor` and read the structured conformance report.
2. Run `oaef skills audit` to check the catalog and frontmatter.
3. Run `oaef skills audit --selftest` to prove routing fixtures resolve.
4. Run `oaef skills route "<prompt>"` for a sampled prompt and confirm the mapping.
5. Run `oaef skills sync-mirrors` to rewrite, then `--check` to validate parity.
6. Verify entrypoint parity and record every divergence as a blocking finding.
7. Hand confirmed findings to `code-review` when they require a code change.

## Repository Conformance Gate
- `oaef doctor`
- `oaef lint`
- `oaef clean-code` (native: `swift tool/governance.swift clean-code`)
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `oaef doctor` reports zero blocking divergences.
- All 13 skills pass frontmatter quality and mirror parity.
- `oaef skills audit --selftest` resolves every routing fixture.
- Entrypoint files agree on the skill catalog.

## Anti-Patterns
- Editing a mirror by hand instead of re-running `sync-mirrors`.
- A skill whose `name` does not match its directory.
- A dispatch-matrix trigger missing from the matching skill frontmatter.
- A locally patched mirror left diverging from the canonical source.
- Reporting a divergence without the exact command that reproduces it.
