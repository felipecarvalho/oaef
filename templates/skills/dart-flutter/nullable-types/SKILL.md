---
name: nullable-types
description: >-
  Use when a value can be absent, nil, null or optional in Dart & Flutter. Triggers on: "null", "optional", "nil", "guard clause", "defensive".
  Chains into: test-generator, run-static-analysis. Owns defensive null handling and non-nullable collection defaults in Dart & Flutter: absence carries business meaning, guard clauses return early instead of nesting, and a collection parameter defaults to a constant empty collection rather than an optional list.
argument-hint: "[path or type name]"
license: MIT
metadata:
  framework: OAEF
  stack: dart-flutter
  version: 1.1.0
---

# Nullable Types (Dart & Flutter)

> **Stack Profile:** Dart & Flutter
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Keep `null` meaningful, confined and rare across Dart and Flutter sources. This skill removes defensive scatter, replaces optional collections with constant empty defaults, and turns deep nesting into guard clauses, while preserving sound null safety as the compiler contract.

## Territory
- `lib/**` — models, entities, value objects and their `fromJson`/`copyWith` surfaces.
- `lib/features/<feature>/domain/**` — entities and use-case inputs; absence here is a business decision.
- `lib/features/<feature>/data/**` — parsers and DTOs where the network boundary legitimately yields absent values.
- `lib/features/<feature>/presentation/**` — widgets consuming nullable view state (`AsyncValue`, sealed states).
- `test/**` — null-path and empty-collection assertions.

## Conventions
- A nullable type carries business meaning. If absence is not a business state, the value must not be nullable.
- Prefer a sealed state hierarchy (`sealed class`, `switch` expression) over scattered `if (x != null)` branching across widgets.
- Use `?.`, `??`, `??=` and collection-if to express intent in one expression instead of an `if` block.
- `late final` with a deferred assignment that can be absent is prohibited; inject the value or model it as a state (`CC-03`).
- Never silence a null with `!` unless the invariant is proven by an assertion on the same path; prefer a guard that makes the non-null path total.

## Non-Nullable Collections
A collection parameter is never optional. Default to a constant empty collection so callers pass nothing and consumers iterate unconditionally:

```dart
class BookingList extends StatelessWidget {
  const BookingList({super.key, this.items = const <Booking>[]});
  final List<Booking> items;
}
```

- `Map<K, V>?`, `List<T>?` and `Set<T>?` in a public signature are findings (`CC-08`).
- Use `const <T>[]`, `const <K, V>{}` or `const <T>{}` as the non-null default; never `null` plus an internal coercion at every use site.
- Never mutate a shared default collection; return a fresh unmodifiable view (`List.unmodifiable`) when the contract requires immutability.

## Guard Clauses
Return early on the absent or invalid branch and keep the happy path at one indentation level:

```dart
Booking? parseBooking(Map<String, dynamic> raw) {
  final id = raw['id'];
  if (id is! String || id.isEmpty) return null;
  return Booking(id: id, seat: raw['seat'] as String? ?? 'unassigned');
}
```

- One guard per precondition; do not nest guards inside `else` branches.
- A guard that only logs and continues is a silent swallow; log with error and stack trace or rethrow (`CC-06`).
- Guard the boundary once (parser, repository) rather than re-checking the same invariant in every widget.

## Repository Conformance Gate
- `oaef doctor` — structural, skill and entrypoint conformance.
- `oaef lint` — `CC-*` advisory sweep plus `SK-01`…`SK-06` and secret detection.
- `oaef clean-code` (native: `dart run tool/governance.dart clean-code`) — `CC-08` blockers under the `strict` profile.
- Unresolved findings are recorded in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- No public collection parameter is nullable without a constant empty default.
- Every nullable field is justified by a business-absent state, documented at the type.
- Guard clauses replace nested null checks along the whole touched path.
- Tests cover the absent branch and the empty-collection branch.

## Anti-Patterns
- `late final BookingRepository _repository;` assigned later in `initState` (`CC-03`).
- `List<Booking>? items` consumed behind `if (items != null)` in three widgets (`CC-08`).
- Chained `x?.y?.z ?? ''` masking a missing state that should be a sealed type.
- `catch (error) { print(error); }` around a parser (`CC-05`, `CC-06`).
- Broadcast `!` on a value the guard does not prove non-null.
