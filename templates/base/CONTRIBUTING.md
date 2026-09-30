# Contributing to Open Agentic Engineering Framework (OAEF)

Thank you for your interest in contributing to the **Open Agentic Engineering Framework (OAEF)**! This project provides the canonical, vendor-neutral standard for AI-assisted living software repositories.

We welcome contributions from both human software engineers and autonomous AI agents. To maintain the highest standard of engineering excellence, all contributions must strictly adhere to the guidelines set forth below.

---

## 1. Core Principles & Philosophy

Every contribution MUST align with OAEF's foundational pillars:
1. **The Inviolable Trust Hierarchy**:
   $$\mathbf{Compiler / Typechecker} > \mathbf{Automated Tests} > \mathbf{Source Code} > \mathbf{Wiki / Docs} > \mathbf{Ephemeral Memory} > \mathbf{LLM Hallucination}$$
2. **Zero-Pollution Target Isolation**: Target projects using OAEF receive strictly their own ecosystem's files—never extraneous tools or other language dependencies.
3. **Mathematical Quality Gates**: Every change must satisfy deterministic floors (>=95% line coverage, >=90% branch coverage, clean sizing limits, zero lint violations).
4. **Strict Clean Code Craftsmanship**: Code must be expressive, self-documenting, and free of cryptic abbreviations or anti-patterns.

---

## 2. Mandatory Clean Code Standards

When submitting code, ensure full compliance with the [Clean Code Standards](docs/standards/coding_patterns.md):

* **Meaningful, Intention-Revealing Names**: Identifiers must clearly convey *why* they exist, *what* they do, and *how* they are used.
* **Prohibited Abbreviations**: Never use cryptic abbreviations (`btn`, `val`, `res`, `req`, `usr`, `cb`, `temp`, `data`, `info`, `obj`, `mgr`, `param`, `fn`, `cnt`, `idx`, `buf`, `str`, `num`, `doc`, `elem`). Use full, descriptive words (`button`, `response`, `request`, `user`, `callback`, etc.).
* **Single-Letter Identifiers**: Strictly forbidden. Loop counters (`i`, `j`) are allowed solely in small loops of `<= 5` lines.
* **Small Functions**: Keep functions focused on a single responsibility. Target `<= 30 LOC`, hard ceiling `<= 50 LOC`. Files must not exceed `300 LOC`.
* **Prohibited Flag Arguments**: Never pass boolean flags to functions (`processOrder(order, isExpedited: true)`). Split into distinct, single-purpose functions.
* **Guard Clauses**: Validate preconditions at the top and return early. Keep the happy path unindented.
* **Zero Suppressions**: Bypassing static analysis via inline ignore comments (`// ignore:`, `/* eslint-disable */`, `# noqa`, `//nolint`, etc.) is strictly forbidden.
* **Zero Commented-Out Code**: Remove dead code. Version control tracks history.

---

## 3. Contribution Workflow

### Step 1: Branching
Create a topic branch from the latest `main` branch using standard prefixes:
- `feat/add-python-ast-scanner`
- `fix/lcov-parsing-edge-case`
- `docs/clarify-trust-hierarchy`
- `refactor/clean-sizing-guard`

### Step 2: Conventional Commits
All commit messages must adhere to the [Conventional Commits](https://www.conventionalcommits.org/) specification:
```text
feat: add multi-language anti-suppression matrix
fix: resolve branch coverage calculation when LF is zero
docs: document clean code naming invariants
test: add unit tests for go handler sizing rule
chore: update release bundling script
```

### Step 3: Local Verification
Before opening a Pull Request, run the local verification suite:
```bash
# Execute Quality Gate audit
./bin/oaef audit

# Verify documentation link integrity, mirrors, and secret scanning
./bin/oaef lint

# Synchronize AGENTS.md with mirrors
./bin/oaef sync
```
All checks must pass with zero errors, zero warnings, and zero secret detections.

### Step 4: Submitting a Pull Request
1. Open a PR against `main`.
2. Complete all sections of the [Pull Request Template](.github/pull_request_template.md).
3. Link any corresponding issues (`Fixes #123`).
4. Ensure all items in the Contributor Quality Checklist are verified.

---

## 4. Issues & Proposals

- **Bug Reports**: Use the [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.yml) with complete reproduction steps and environment details.
- **Feature Requests**: Use the [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.yml) describing the problem, proposed solution, and alternatives considered.
- **Architectural Proposals**: For architectural changes or new paradigms, submit an [ADR Proposal](.github/ISSUE_TEMPLATE/adr_proposal.yml).

---

## 5. License & Attribution

By contributing to OAEF, you agree that your contributions will be licensed under the **Apache License 2.0**. Please review the `NOTICE` file for project creator and foundational citations.
