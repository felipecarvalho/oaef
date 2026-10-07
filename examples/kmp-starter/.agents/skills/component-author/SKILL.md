---
name: component-author
description: >-
  Use when authoring or extracting a reusable component, widget, button, card or modal in Kotlin Multiplatform. Triggers on: "component", "widget", "button", "card", "modal". Chains into: ui-preview, responsive-layout, test-generator. Authors reusable Kotlin Multiplatform surfaces from design-system tokens: one responsibility per component, tokens instead of literals, and a contract that serves every consumer without a bespoke variant.
argument-hint: "[component name]"
license: MIT
metadata:
  framework: OAEF
  stack: kotlin-multiplatform
  version: 1.1.0
---

# Component Author (Kotlin Multiplatform)

> **Stack Profile:** Kotlin Multiplatform
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Ship a stateless Compose Multiplatform component with a stable contract that every consumer can use without a new variant, styled exclusively from design-system tokens.

## Territory
- `src/commonMain/kotlin/**/components/**` - reusable composables.
- `src/commonMain/kotlin/**/shared/**` - cross-feature building blocks and slot defaults.
- `src/commonMain/kotlin/**/ui/theme/**` - tokens: colors, typography, spacing, shapes.
- `**/features/*/presentation/**` - consumers; a component is extracted here only when a second consumer exists.

## Component Contract
- Signature starts from tokens and slots: `@Composable fun <Name>(modifier: Modifier = Modifier, content: @Composable () -> Unit)`.
- The component is stateless: state is hoisted to the caller; the component receives values and emits events.
- `modifier` is the first optional parameter and is applied to the outermost node exactly once.
- Slots replace boolean flags: `leadingIcon: (@Composable () -> Unit)? = null` instead of `showIcon: Boolean`.
- Events are lambdas with domain-neutral names (`onClick`, `onValueChange`), never repository calls.
- Semantics are declared: `Modifier.semantics { contentDescription = ... }` or role-bearing `Modifier.clickable` for accessibility.
- A single responsibility per component; composition over configuration.

## Token Discipline
- Colors, typography, spacing and shapes come from `MaterialTheme.colorScheme`, `MaterialTheme.typography` and the project token object; never a literal `Color(0xFF...)` or magic `12.dp`.
- Exception: a token-less primitive whose only literal is `Modifier.size(0.dp)` for a spacer, which is replaced by the spacing token.
- Platform-specific styling is confined to `expect/actual` or a theme provider; the component itself stays in `commonMain`.
- No bespoke variant parameter when a slot or a token override expresses the same intent.
- Previews for each public variant live next to the component (`ui-preview`).

## Repository Conformance Gate
- Run `oaef doctor`, `oaef lint` and `oaef clean-code` (native: `kotlinc -script tool/governance.main.kts clean-code`).
- Run `./gradlew detekt` and `./gradlew allTests`.
- Record deferred component work in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- The component is stateless and its state is hoisted at every call site.
- No design literal remains; every color, size and type comes from a token.
- The public variants are covered by previews and by at least one composable test.

## Anti-Patterns
- A `boolean` flag per visual variation instead of a slot.
- Copy-pasting the component into a feature to tweak one color.
- Applying `modifier` twice, or not at all, on the outermost node.
