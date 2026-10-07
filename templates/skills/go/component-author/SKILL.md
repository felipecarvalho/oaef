---
name: component-author
description: >-
  Use when authoring or extracting a reusable component, widget, button, card or modal in Go. Triggers on: "component", "widget", "button", "card", "modal". Chains into: ui-preview, responsive-layout, test-generator. Authors reusable Go surfaces from design-system tokens: one responsibility per component, tokens instead of literals, and a contract that serves every consumer without a bespoke variant.
argument-hint: "[component name]"
license: MIT
metadata:
  framework: OAEF
  stack: go
  version: 1.1.0
---

# Component Author (Go)

> **Stack Profile:** Go
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Author a reusable Go package or type that serves every consumer through one contract. A "component" in a headless stack is a package surface: a type, its constructor and its methods, or a reusable transport middleware.

## Territory
- `internal/shared/<name>/` — reusable packages within the module.
- `internal/platform/<name>/` — shared infrastructure components (middleware, encoders).
- `pkg/<name>/` — packages exported beyond the module, when the repository declares one.
- `internal/shared/<name>/<name>_test.go` — the component's contract tests.

## Component Contract
- One responsibility per package; the package name is a noun describing that responsibility.
- A constructor function (`func New(options Options) *Component`) validates its inputs and returns a typed error on failure; no package-level mutable state.
- Configuration through a struct with exported fields, not a long parameter list.
- The zero value is either usable or has a documented reason it is not.
- Public methods accept `context.Context` first and return `(result, error)`.
- The contract is exercised by a mock-fake in tests, so a single-implementation interface is justified only when the consumer needs a seam.

## Token Discipline
In a headless stack, "tokens" are the shared constants and configuration values that every consumer must use instead of literals:
- Define status codes, header names, retry counts and timeouts as named constants or package defaults.
- Never hardcode a magic string, timeout duration or buffer size at a call site; reference the token.
- Design-system equivalents (typography, spacing) do not apply here; apply the same discipline to protocol and encoding constants.
- A new token is added once, in the owning package, and imported everywhere.

## Repository Conformance Gate
- Run `oaef doctor` (native: `go run tool/governance.go doctor`).
- Run `oaef lint` (native: `go run tool/governance.go lint`).
- Run `oaef clean-code` (native: `go run tool/governance.go clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The component has one responsibility and no package-level mutable state.
- Every magic literal is replaced by a named token.
- A contract test proves the public surface from the consumer's perspective.

## Anti-Patterns
- A package-level singleton holding the component's state.
- An interface with one implementation that no test fakes.
- A boolean parameter that toggles two unrelated behaviours.
- Duplicating a constant in several packages instead of importing the owner.
