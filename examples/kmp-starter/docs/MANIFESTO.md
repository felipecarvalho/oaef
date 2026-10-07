# Project Manifesto: kmp-starter
> *«The repository that writes its own memory for whoever arrives next.»*  
> Powered by the Open Agentic Engineering Framework (OAEF) by Felipe Carvalho.

---

## 1. Executive & Business Vision

### The Problem This Repository Eliminates
In conventional software development, engineering intelligence is vulnerable to team turnover, forgotten chat threads, and unwritten tribal knowledge. This repository operates as a **Living Repository**:
1. **Instant Onboarding**: New developers and autonomous AI agents read our structured contracts and deliver value immediately.
2. **Predictable Velocity**: Zero code enters production without automated mathematical proof of correctness.
3. **Institutional Continuity**: Architectural intelligence belongs permanently to the codebase.

---

## 2. Technical Philosophy & The Trust Hierarchy

When questions or contradictions arise, truth is determined by the Inviolable Trust Hierarchy:

$$\mathbf{Compiler / Typechecker} > \mathbf{Automated Tests} > \mathbf{Source Code} > \mathbf{Wiki / Docs} > \mathbf{Ephemeral Memory} > \mathbf{LLM Hallucination}$$

### The 5 Pillars
1. **Context Engineering**: Token-efficient task routing (`docs/INDEX.md`) and `/llms.txt`.
2. **Spec-Driven Development**: Executable BDD Gherkin specifications before code.
3. **Multidimensional Quality Gates**: >=95% Line coverage, >=90% Branch coverage, Clean Sizing (<=300 LOC/file, <=50 LOC/method), and zero `// ignore:`.
4. **Zero-Docker Living Memory**: Native inter-session handoff ledger without slow background containers.
5. **Minimalism & Design Integrity (Simplicity Ladder + SOLID)**: The best code is the code you did not have to write, and what you do write obeys strict substitutability.

#### Pillar 5 in Practice

**The Simplicity Ladder (the Ponytail Ladder)** — before writing any code, climb the seven rungs in order: YAGNI > Reuse in the codebase > Language/stdlib primitives > Platform-native capability > Already-installed dependency > One-line idiomatic expression > Smallest correct diff. Stop at the first rung that satisfies the requirement; a lower rung is a review finding, not a stylistic preference.

**Anti-AI-Slop Stance** — zero tolerance for speculative abstraction, ceremonial pass-through layers, narration comments and dead parameters. Root causes are fixed at the shared origin (grep every caller, one guard at the root) instead of patched at each symptom. Residual complexity is declared in place with a `// ponytail: <ceiling + evolution trigger>` marker rather than hidden.

**Rule of Two (Solution Abstraction Elevation)** — a solution recurring in two or more locations is elevated into a shared abstraction; conversely, an abstraction with a single implementation and no mock need is prohibited. Duplication is a signal to elevate, and premature elevation is a signal to inline.

**SOLID Principles** — single responsibility, open/closed extension, strict substitutability (no unimplemented placeholders in production contracts), segregated interfaces and inverted dependencies via constructor injection. Service-locator resolution is confined to the composition root, and concrete network clients are never instantiated in the domain.

**Mechanical Governance Checks** — the ladder and SOLID are not advice; they are enforced by language-native checks (`CC-01`..`CC-11`, `SK-01`..`SK-06`, `PT-01`) executed by `oaef clean-code`, `oaef lint` and `oaef quality-gate` in every one of the 12 supported stacks. The `strict` profile blocks on violations (exit 1); the `standard` profile reports them as advisory, except secret, mirror and suppression checks, which always block.

#### Normative Catalog

`docs/standards/governance_checks.md` is the single normative catalog of the governance checks: it defines every check ID, its semantics, its canonical message, its per-stack realization and its routing/adoption degradation rules. The catalog is enforced by `oaef clean-code` identically in all 12 stacks — the same IDs and the same messages cost nothing to port — and its block/advisory behavior follows one rule: blocking in the `strict` profile, advisory in the `standard` profile, except secret, harness-mirror and suppression checks, which block in both.
