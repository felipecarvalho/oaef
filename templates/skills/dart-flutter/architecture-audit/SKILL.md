---
name: architecture-audit
description: >-
  Use when reviewing module boundaries, coupling or dependency direction in Dart & Flutter. Triggers on: "architecture", "boundary", "coupling", "cycle".
  Chains into: conformance-audit, code-review. Audits layer boundaries, cyclic dependencies and Clean Sizing inside Dart & Flutter: domain code never reaches outward, infrastructure never leaks inward, and every module keeps a single reason to change.
argument-hint: "[module path or boundary name]"
license: MIT
metadata:
  framework: OAEF
  stack: dart-flutter
  version: 1.1.0
---

# Architecture Audit (Dart & Flutter)

> **Stack Profile:** Dart & Flutter
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Verify that the Dependency Rule holds across a Dart and Flutter feature slice. Layer boundaries are inspected mechanically: domain imports nothing from infrastructure, data implements domain contracts, presentation depends on abstractions, and no module keeps two reasons to change.

## Territory
- `lib/features/<feature>/domain/**` — entities, value objects, use-case contracts; the innermost layer.
- `lib/features/<feature>/data/**` — repositories, DTOs, remote sources; implements domain contracts.
- `lib/features/<feature>/presentation/**` — widgets, state holders, routing.
- `lib/shared/**`, `lib/ui/**` — cross-feature widgets and tokens; must not import a feature.
- `lib/di/**`, `lib/main.dart` — composition root; the only place concrete wiring is legitimate.
- `test/**` — test doubles reveal whether contracts are truly inverted.

## Boundary Checklist
- **Dependency direction** — `domain` imports `dart:core`, `dart:async` and its own files only. An import of `data`, `presentation`, `package:http`, `Dio`, `HttpClient` or a Flutter widget inside `domain` is a blocker.
- **Infrastructure leak** — no `HttpClient`/`Dio` construction and no `getIt<` resolution inside `domain` or `data` (`CC-07`, `CC-10`).
- **Contract ownership** — an interface lives next to its consumer (domain), never inside the concrete implementation that satisfies it.
- **Feature isolation** — `lib/shared/**` and `lib/ui/**` never import `lib/features/**`; a shared widget that needs feature data takes it as a parameter.
- **Cycles** — no import cycle within or between feature slices; a cycle is always a boundary inversion.
- **Cross-feature coupling** — a feature reaches another feature only through a shared contract in `lib/shared/`, never by importing its presentation or data layer.

## Sizing Bounds
Clean Sizing applies per file and per method, including generated slices:
- Files stay at or under **300 lines**; a slice split beyond the bound becomes a new module, not a larger file.
- Methods stay at or under **50 lines**; extract the shared root instead of duplicating branches across widgets.
- A widget class with more than one responsibility splits into a container (state) and a presentational widget.
- Cyclomatic count per method stays bounded; deep nested `switch` chains move to a sealed hierarchy.

## Repository Conformance Gate
- `oaef doctor` — structural, skill and entrypoint conformance.
- `oaef lint` — `CC-*` advisory sweep plus `SK-01`…`SK-06` and secret detection.
- `oaef clean-code` (native: `dart run tool/governance.dart clean-code`) — `CC-07` and `CC-10` blockers under the `strict` profile.
- Unresolved findings are recorded in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- `domain` has zero outward imports; `data` implements, never defines, the contracts.
- No import cycle remains between the audited slices.
- Container tokens (`getIt<`, `GetIt.instance<`, `getIt(`) appear only under `lib/di/**`, `lib/main.dart`, `**/presentation/**`, `*_screen.*`, `*_view.*`, `*_widget.*`, `*_mixin.*` or `**/debug/**`.
- Every file and method is inside the sizing bounds.

## Anti-Patterns
- `domain/booking.dart` importing `package:http/http.dart`.
- `data/booking_repository_impl.dart` constructing a `Dio(` client directly (`CC-10`).
- A shared widget importing `lib/features/booking/presentation/...`.
- A repository interface defined inside the class that implements it.
- A 700-line screen mixing state, layout, network parsing and routing.
