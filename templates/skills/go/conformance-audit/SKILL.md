---
name: conformance-audit
description: >-
  Use when verifying that the repository, its skills or its governance artifacts conform to the framework in Go. Triggers on: "conformance", "doctor", "parity", "frontmatter". Chains into: code-review. Audits repository conformance: structure, mirror parity, the 13 skills with their frontmatter and harness mirrors, governance entrypoints and community files, then reports every divergence as a blocking finding.
argument-hint: "[scope: repository|skills|docs]"
license: MIT
metadata:
  framework: OAEF
  stack: go
  version: 1.1.0
---

# Conformance Audit (Go)

> **Stack Profile:** Go
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Verify that the repository, its skills and its governance artifacts conform to OAEF, and report every divergence as a blocking finding.

## Territory
- `AGENTS.md`, `CLAUDE.md`, `llms.txt`, `oaef.context.json` — root meta-files.
- `.agents/skills/` — the 13 canonical skills and their frontmatter.
- `.claude/skills/`, `.cursor/rules/`, `.windsurf/skills/`, `.cline/skills/`, `.grok/agents/` — harness mirrors, when present.
- `docs/standards/`, `docs/INDEX.md`, `docs/MANIFESTO.md`, `docs/wiki/` — standards and memory.
- `tool/governance.go` — the governance runtime.
- `.github/`, `CONTRIBUTING.md`, `SECURITY.md`, `.gitignore` — community files.

## What This Skill Verifies
1. **Structure** — `AGENTS.md`, `CLAUDE.md`, `llms.txt`, `oaef.context.json`, the full `docs/` tree and `docs/HARNESSES.md` exist.
2. **Mirror parity** — `CLAUDE.md` is an exact mirror of `AGENTS.md`; `oaef sync` reconciles them.
3. **Skills** — the 13 canonical skills exist under `.agents/skills/` with valid frontmatter.
4. **Frontmatter quality** — `name` equals the directory, `description` starts with `Use when`, contains `Triggers on:` and `Chains into:`, and folds to at least 150 characters (`SK-02`).
5. **Harness mirrors** — every present harness directory mirrors `.agents/skills/` byte for byte (`SK-05`).
6. **Entrypoint parity** — `llms.txt` lists all skills; `README.md`, `docs/INDEX.md` and `docs/MANIFESTO.md` reference `llms.txt` (`SK-03`).
7. **Governance runtime** — `tool/governance.go` is present and the native commands run.
8. **Hygiene** — no unresolved `{{...}}` placeholders, no secrets, no unallowed suppressions.

## Deterministic Procedure
1. `oaef doctor` (native: `go run tool/governance.go doctor`) — structural and prerequisite audit.
2. `oaef skills audit` (native: `go run tool/governance.go skills-audit`) — skill parity and frontmatter quality.
3. `oaef skills audit --selftest` — routing self-test (`SK-06`) over the canonical fixture table.
4. `oaef skills route "<prompt>"` (native: `go run tool/governance.go skills-route "<prompt>"`) — confirm a prompt resolves to the expected skill and recipe.
5. `oaef skills sync-mirrors --check` — validate every harness mirror; `oaef skills sync-mirrors` rebuilds a diverged mirror.
6. `oaef lint` and `oaef clean-code` (native: `go run tool/governance.go lint` / `clean-code`) — parity, secret and `CC-*` findings.
7. Resolve every divergence; restore missing artifacts from the framework templates, never by editing `CLAUDE.md` directly.
8. Record the audit outcome in `docs/wiki/memory/handoff.md`.

## Repository Conformance Gate
- Run `oaef doctor` (native: `go run tool/governance.go doctor`).
- Run `oaef lint` (native: `go run tool/governance.go lint`).
- Run `oaef clean-code` (native: `go run tool/governance.go clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `oaef doctor` exits 0; the 13 skills validate under `SK-02`.
- `oaef skills audit --selftest` and `oaef skills sync-mirrors --check` exit 0.
- `oaef lint` reports zero parity, secret or suppression findings.

## Anti-Patterns
- Declaring a task complete with a failing conformance audit.
- Editing `CLAUDE.md` directly instead of `AGENTS.md` plus `oaef sync`.
- Hand-editing a harness mirror instead of running `oaef skills sync-mirrors`.
- Loosening `baseline.json` floors to make the audit pass.
