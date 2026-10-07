---
name: ui-preview
description: >-
  Use when a component or screen must be inspected in isolation before it is wired into the application in React Native. Triggers on: "preview", "storybook", "isolated render". Chains into: test-generator, run-static-analysis. Provides isolated preview harnesses for React Native: loading, success, empty and error states are rendered without booting the full runtime, so layout, tokens and typography are validated before integration.
argument-hint: "[component or screen name]"
license: MIT
metadata:
  framework: OAEF
  stack: react-native
  version: 1.1.0
---

# UI Preview (React Native)

> **Stack Profile:** React Native
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Render one surface in isolation so layout, tokens and typography are verified before integration. A preview boots the component only, not the navigation stack, the network layer or the whole application.

## Territory
- `src/components/**`, `src/shared/ui/**` — component previews.
- `src/features/<feature>/presentation/screens/**` — screen previews.
- `.storybook/**`, `**/*.stories.tsx` — story definitions when Storybook is installed.
- `__tests__/` — snapshot and rendering tests backing the preview.

## Preview Harness
- Prefer a dedicated preview runner (`npx expo start` with an isolated route, or Storybook via `npx storybook dev`) over a debug switch buried in production navigation.
- Define the preview at module scope: one story per meaningful state.
- Cover the state matrix: `idle`, `loading`, `success`, `empty`, `error`, plus long-content and compact/expanded widths.
- Inject deterministic props and mock callbacks (`jest.fn()` or a local no-op); never call real services.
- Wrap previews in the providers the component needs (safe area, theme, fonts) so the render matches production.
- Keep previews out of the production bundle; gate them behind a dev-only entry.
- When Storybook is absent, a minimal sandbox screen under a dev-only route is sufficient.
- Render on a real device or simulator, not only in the test renderer, so platform shadows, fonts and safe areas are visible.
- Capture one reference per state at compact and expanded widths; attach them as review evidence.
- Keep story data in the story file or a `make<Entity>` factory; never import production fixtures.

## Repository Conformance Gate
- Run `oaef doctor` (native: `node tool/governance.mjs doctor`).
- Run `oaef lint` (native: `npx eslint .`).
- Run `oaef clean-code` (native: `node tool/governance.mjs clean-code`).
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Every state in the matrix renders from static props in the harness.
- The preview does not boot the full runtime or hit real services.
- Layout and tokens are verified at compact and expanded widths.

## Anti-Patterns
- A preview that requires a running backend to render.
- A single story covering only the happy path.
- Preview code shipped into the production bundle.
- Inline style overrides in the story that hide a token defect.
