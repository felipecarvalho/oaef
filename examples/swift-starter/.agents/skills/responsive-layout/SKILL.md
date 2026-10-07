---
name: responsive-layout
description: >-
  Use when a surface must adapt to another screen size, form factor or payload shape in Swift. Triggers on: "responsive", "adaptive", "breakpoint", "tablet", "foldable", "viewport". Chains into: ui-preview, test-generator. Owns adaptive design in Swift: breakpoints, safe areas, dynamic type and foldables for interactive surfaces, and payload shaping, pagination, content negotiation and streaming backpressure for headless ones.
argument-hint: "[breakpoint or surface name]"
license: MIT
metadata:
  framework: OAEF
  stack: swift
  version: 1.1.0
---

# Responsive Layout (Swift)

> **Stack Profile:** Swift
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Make interactive Swift surfaces adapt across size classes, Dynamic Type, safe areas and window resizing without duplicating a layout per device. Swift is an interactive-surface stack; the guidance below is the breakpoint variant.

## Territory
- `Sources/<Module>/Presentation/` — screens and components that adapt.
- `Sources/<Module>/DesignSystem/` — breakpoint and spacing tokens.
- `Sources/<Module>/App*/` — window and scene configuration.
- `Tests/` — layout tests across size class and text scale inputs.

## Adaptive Surface Design
- Read the environment: `@Environment(\.horizontalSizeClass)`, `\.verticalSizeClass` and `\.dynamicTypeScale`.
- `ViewThatFits` picks the first layout variant that fits before a manual branch is written.
- Respect safe areas with `.safeAreaInset` and `.ignoresSafeArea` only where justified.
- Foldables and Stage Manager: react to window resizing, not to a fixed device list.
- Dynamic Type is honored; fixed point sizes are a finding.
- Reuse the same `View` tree across breakpoints; adapt spacing and column count, not identity.

## Breakpoint Strategy
- Define named breakpoints as tokens; never scatter magic numbers through the tree.
- Compact width: single column; Regular width: multi-column or a detail pane.
- Test the extremes: smallest supported width and largest Dynamic Type size.
- Landscape and split view share the same adaptive rules as portrait.
- A breakpoint branch that duplicates a whole subtree is a `[SHRINK]` finding.
- Prove each breakpoint in a preview bound to an explicit size class.

## Repository Conformance Gate
- `oaef doctor`
- `oaef lint`
- `oaef clean-code` (native: `swift tool/governance.swift clean-code`)
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The surface lays out correctly at both size classes without clipping.
- Dynamic Type at the largest accessible size does not truncate critical text.
- Breakpoint values come from tokens, not literals.
- `swift build` and `swift test` pass; previews cover each branch.

## Anti-Patterns
- A separate `View` per device instead of one adaptive tree.
- Hardcoded `.frame(width: 375)` coupled to a device assumption.
- Ignoring safe areas to force a full-bleed layout.
- Fixed font sizes that break at large Dynamic Type.
- Breakpoint constants duplicated in several files instead of a token.
