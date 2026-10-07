---
name: ui-preview
description: >-
  Use when a component or screen must be inspected in isolation before it is wired into the application in TypeScript & Web. Triggers on: "preview", "storybook", "isolated render". Chains into: test-generator, run-static-analysis. Provides isolated preview harnesses for TypeScript & Web: loading, success, empty and error states are rendered without booting the full runtime, so layout, tokens and typography are validated before integration.
argument-hint: "[component or screen name]"
license: MIT
metadata:
  framework: OAEF
  stack: typescript-web
  version: 1.1.0
---

# UI Preview (TypeScript & Web)

> **Stack Profile:** TypeScript & Web
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission

Render a surface in isolation, across every meaningful state, before it is wired into the
application shell. A preview is the fastest feedback loop for layout, tokens and
typography, and it is the harness the tests reuse.

## Territory

- `src/components/**/*.stories.tsx` or `*.preview.tsx` — component harnesses.
- `src/features/<feature>/presentation/**/*.preview.tsx` — screen-level harnesses.
- `.storybook/` — the harness runner when the repository uses one.
- `src/**/*.spec.ts` — tests that render the same harness.

## Preview Harness

- One harness per component; enumerate the states explicitly: `loading`, `success`,
  `empty`, `error`, plus each named breakpoint from `responsive-layout`.
- Supply deterministic fixtures; no live network, no random data, no reliance on the real
  store. Pass data in as props.
- Cover the edge cases that break layout: the longest realistic string, the empty
  collection, the very tall item, and a right-to-left locale if supported.
- Preview the component at the container widths it will actually occupy, not only the
  full viewport.
- Keep the harness out of the production bundle; story files must not be imported by
  application code.
- The preview is temporary scaffolding for a one-off change and permanent for a shared
  component: promote it to a story when the component is reused.

## Repository Conformance Gate

- Run `oaef doctor`, `oaef lint`, `oaef clean-code` (native:
  `node tool/governance.mjs doctor|lint|clean-code`).
- Run `npx tsc --noEmit` and `npx eslint src`.
- Record unresolved findings in `docs/wiki/memory/handoff.md`.

## Exit Criteria

- Every meaningful state renders without crashing and without network access.
- Layout holds at each named breakpoint and with the longest realistic content.
- The harness is reusable by the test suite and excluded from the production bundle.

## Anti-Patterns

- A preview that mounts the whole application to display one component.
- A single "default" preview that never exercises empty or error.
- Fixtures that call the real API and fail without a backend.
- Story files imported from production entry points, bloating the bundle.
