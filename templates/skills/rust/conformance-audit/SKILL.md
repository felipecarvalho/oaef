---
name: conformance-audit
description: >-
  Use when verifying that the repository, its skills or its governance artifacts conform to the framework
  in Rust. Triggers on: "conformance", "doctor", "parity", "frontmatter". Chains into: code-review.
  Audits repository conformance: structure, mirror parity, the 13 skills with their frontmatter and
  harness mirrors, governance entrypoints and community files, then reports every divergence as a
  blocking finding.
argument-hint: "[scope: repository|skills|docs]"
license: MIT
metadata:
  framework: OAEF
  stack: rust
  version: 1.1.0
---

# Repository Conformance Audit (Rust)

> **Stack Profile:** Rust
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** entrypoint

## Mission
Verify that the repository conforms to the framework: the mandatory structure exists, the skills are
complete and correctly declared, the harness mirrors match, and every governance entrypoint is wired.

## Territory
- `AGENTS.md`, `CLAUDE.md`, `llms.txt`, `README.md` — the root contract and entrypoints.
- `.agents/skills/**` and every harness mirror directory.
- `docs/standards/**`, `docs/INDEX.md`, `docs/MANIFESTO.md` — canonical standards.
- `tool/` — the native governance engine (`cargo run --bin governance`).

## What This Skill Verifies
- Structure: the canonical directories, standards documents and community files are present.
- Skills: all 13 canonical skills exist, each with `## Territory` and `## Repository Conformance Gate`.
- Frontmatter quality: `name` equals the directory, the `description` starts with `Use when`, carries
  `Triggers on:` and `Chains into:`, and holds at least 150 characters.
- Entrypoint parity: `llms.txt` lists every skill; `README.md`, `docs/INDEX.md` and `docs/MANIFESTO.md`
  reference `llms.txt`.
- Mirror parity: each present harness skill directory matches `.agents/skills` byte for byte.
- Governance entrypoints: the native engine answers every subcommand and the CI calls the same suite.

## Deterministic Procedure
1. `oaef doctor` — structural, standards and skill prerequisites.
2. `oaef skills audit` — skill parity (`SK-01`), frontmatter quality (`SK-02`) and entrypoint parity
   (`SK-03`).
3. `oaef skills audit --selftest` — the routing fixture table resolves exactly (`SK-06`).
4. `oaef skills route "<prompt>"` — spot-check a dispatch prompt against its expected skill (`SK-04`).
5. `oaef skills sync-mirrors --check` — mirror parity without writing (`SK-05`); repair with
   `oaef skills sync-mirrors`.
6. `oaef lint` — secrets and remaining governance invariants.
7. `cargo run --bin governance -- clean-code` — the native realization of the clean-code suite.

## Repository Conformance Gate
- `cargo run --bin governance -- clean-code`
- `oaef lint`, `oaef doctor`
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `oaef doctor` and `oaef skills audit --selftest` both exit clean.
- Every divergence is reported as a blocking finding with its check identifier.

## Anti-Patterns
- Declaring conformance from a partial run that skipped the self-test.
- Repairing mirrors by hand instead of `oaef skills sync-mirrors`.
- Treating a missing standard document as a warning rather than a blocker.
- Editing the routing fixture to make the self-test pass.
