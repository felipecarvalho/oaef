---
name: ponytail
description: >-
  Use when adding, refactoring, simplifying or deleting code in Go. Triggers on: "new", "refactor", "add", "simple", "minimal", "YAGNI", "dead code", "delete", "remove". Chains into: screen-builder, component-author, nullable-types, code-review. Governs the seven-rung Simplicity Ladder across every Go source tree: it demands the smallest correct diff, forbids ceremonial layers and speculative abstraction, and routes every root cause to the single shared guard instead of per-call-site defensive branches.
argument-hint: "[mode: lite|full|ultra] [path]"
license: MIT
metadata:
  framework: OAEF
  stack: go
  version: 1.1.0
---

# Ponytail (Go)

> **Stack Profile:** Go
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)

> **Attribution:** the Simplicity Ladder is inspired by Dietrich Gebert's *Ponytail* minimalism (smallest correct diff, zero AI slop).
> **Skill Class:** meta

## Mission
Enforce the Simplicity Ladder on every Go change: the best code is the code you did not have to write. Reject AI slop, speculative abstraction and ceremonial indirection before they enter a package.

## Territory
- `*.go` at the repository root — top-level package code and `main.go`.
- `internal/<feature>/` — `domain/`, `data/`, `http/` slices.
- `cmd/**/main.go` — composition roots.
- `*_test.go` — simplification of oversized test scaffolding.
- `go.mod` — dependency surface; a new module is a last resort.

## Modes
- **lite** — apply the ladder to the touched function only; keep the public API stable.
- **full** — apply to the whole package slice, including deletion of unused helpers.
- **ultra** — apply to the subtree and audit every `go.mod` addition for removal.

## The N-Step Ladder
1. **YAGNI** — does the requirement exist today? If not, write nothing.
2. **Reuse in codebase** — search the module first (`grep -rn "func Name"`).
3. **Language/stdlib primitives** — `slices`, `maps`, `strings.Builder`, `errors.Is`/`errors.As`, `context`, `net/http` before any dependency.
4. **Platform-native capability** — the runtime and `go` toolchain already provide it.
5. **Already-installed dependency** — extend an existing `go.mod` package instead of adding a second one.
6. **One-line idiomatic expression** — a table-driven loop or a single guard replaces a hand-written block.
7. **Smallest correct diff** — stop at the first rung that works; do not climb further.

## Root-Cause Bug Fixing
Grep every caller before editing: `grep -rn "func Affected" --include='*.go'`. Fix the single shared guard in the common `internal/.../domain` path; never duplicate an `if err != nil` branch per call site. A fix that touches only the reported path is incomplete.

## Complexity Taxonomy
- `[DELETE]` — dead function, unused helper, unreachable branch.
- `[STDLIB]` — hand-rolled helper replaced by `slices`, `maps` or `strings`.
- `[NATIVE]` — custom machinery replaced by `context`, `net/http` or the toolchain.
- `[YAGNI]` — speculatively generic code with a single concrete caller.
- `[SHRINK]` — code kept but reduced to its minimum correct form.

## `// ponytail:` Debt Markers
Declare a deliberate ceiling with its evolution trigger:
```go
// ponytail: in-memory cache, move to persistent storage once writes exceed 10k/day
```
`oaef ponytail debt` (native: `go run tool/governance.go ponytail-debt`) reports every marker as `PT-01`; `oaef ponytail audit` adds the `[TAG]` anti-slop sweep. Markers are report-only, never blocking.

## Safety Frontier
Validation, error routing, privacy, logging and Quality Gates are never pruned. A simplification that removes an error path, a bounded context deadline or a conformance check is rejected.

## Repository Conformance Gate
- Run `oaef doctor` (native: `go run tool/governance.go doctor`).
- Run `oaef lint` (native: `go run tool/governance.go lint`).
- Run `oaef clean-code` (native: `go run tool/governance.go clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every touched symbol descends the ladder; no speculative abstraction survives.
- `go vet ./...` and `golangci-lint run` report no new findings.
- `oaef ponytail debt` lists any new marker with its ceiling and trigger.

## Anti-Patterns
- A single-implementation interface added "for testability" when a fake is not needed.
- A one-statement pass-through wrapper around a stdlib call.
- Narration comments that restate the Go code.
- Adding a dependency for a problem the stdlib already solves.
