---
name: component-author
description: >-
  Use when authoring or extracting a reusable component, widget, button, card or modal in Swift. Triggers on: "component", "widget", "button", "card", "modal". Chains into: ui-preview, responsive-layout, test-generator. Authors reusable Swift surfaces from design-system tokens: one responsibility per component, tokens instead of literals, and a contract that serves every consumer without a bespoke variant.
argument-hint: "[component name]"
license: MIT
metadata:
  framework: OAEF
  stack: swift
  version: 1.1.0
---

# Component Author (Swift)

> **Stack Profile:** Swift
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Author or extract a reusable SwiftUI component with one responsibility, tokenized styling and a contract that serves every consumer. The component is previewable in isolation and carries no knowledge of any specific screen.

## Territory
- `Sources/<Module>/Presentation/Components/` — shared surfaces.
- `Sources/<Module>/DesignSystem/` — tokens, typography and spacing.
- `Sources/<Module>/Presentation/<Feature>/` — feature-local components.
- `Tests/` — component behavior and snapshot tests.

## Component Contract
- One responsibility per component; a second use case splits it.
- Inputs are explicit parameters with sensible defaults; no ambient globals.
- The component emits intent through closures, never performs navigation itself.
- No dependency resolution inside the component body.
- Accessible by default: labels, traits and Dynamic Type support.
- A `#Preview` covers each meaningful state.

## Token Discipline
- Spacing, color, radius and typography come from design-system tokens.
- Literal color, font-size and spacing values are findings.
- `ViewThatFits` and size classes replace per-breakpoint duplicates.
- Reuse an existing modifier before defining a new one.
- Extract a component only at the Rule of Two: two real call sites.
- No bespoke variant parameter that a second component would serve better.

## Repository Conformance Gate
- `oaef doctor`
- `oaef lint`
- `oaef clean-code` (native: `swift tool/governance.swift clean-code`)
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The component renders in a `#Preview` for every state.
- All styling resolves through tokens; zero literals remain.
- Accessibility labels and Dynamic Type behavior are verified.
- `swift build` and `swift test` pass for the target.

## Anti-Patterns
- One component with a `Style` enum that renders five unrelated surfaces.
- Hardcoded `Color(red:green:blue:)` or `.font(.system(size: 17))`.
- A boolean parameter matrix that encodes screen-specific behavior.
- Component resolving `DependencyContainer.shared` directly.
- A component defined once and shared nowhere (speculative abstraction).
