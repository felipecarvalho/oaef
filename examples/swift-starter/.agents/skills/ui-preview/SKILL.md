---
name: ui-preview
description: >-
  Use when a component or screen must be inspected in isolation before it is wired into the application in Swift. Triggers on: "preview", "storybook", "isolated render". Chains into: test-generator, run-static-analysis. Provides isolated preview harnesses for Swift: loading, success, empty and error states are rendered without booting the full runtime, so layout, tokens and typography are validated before integration.
argument-hint: "[component or screen name]"
license: MIT
metadata:
  framework: OAEF
  stack: swift
  version: 1.1.0
---

# UI Preview (Swift)

> **Stack Profile:** Swift
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Render any SwiftUI surface in isolation across its meaningful states before it is integrated. Previews are the fastest feedback loop for layout, tokens and typography and must not require the full app runtime or live network.

## Territory
- `Sources/<Module>/Presentation/` — the previewed views.
- `Sources/<Module>/Presentation/Components/` — shared surfaces.
- `Sources/<Module>/DesignSystem/` — tokens the preview validates.
- `Tests/` — snapshot or state tests that promote a preview to a regression.

## Preview Harness
- Add a `#Preview` next to the view for each meaningful state.
- Define a preview provider that injects fakes; never touch `URLSession.shared`.
- Cover four states: loading, success, empty and error.
- Render at compact and regular size classes and at a large Dynamic Type size.
- Use `#Preview(traits: .sizeThatFitsLayout)` where the surface has no intrinsic size.
- Promote any preview that caught a regression into a test.
- Keep preview fixtures in a shared `PreviewSupport` file, not inline in each view.
- Bind the preview to an explicit state so the rendered frame is deterministic across runs.
- A preview that only compiles in the app target is moved into the previewable module.

## Repository Conformance Gate
- `oaef doctor`
- `oaef lint`
- `oaef clean-code` (native: `swift tool/governance.swift clean-code`)
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Each surface has a preview for loading, success, empty and error.
- Previews build without a live backend or real credentials.
- At least one preview is promoted to a regression test per non-trivial surface.
- `swift build` compiles the preview targets.

## Anti-Patterns
- A preview that calls the real service or a global resolver.
- A single preview instrumented only on the happy path.
- Preview fixtures duplicated inline across many files.
- A preview present only for the root screen, none for shared components.
- A preview left broken in the build without a recorded handoff finding.
