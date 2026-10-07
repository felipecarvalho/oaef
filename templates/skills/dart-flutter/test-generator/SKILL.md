---
name: test-generator
description: >-
  Use when writing or expanding automated tests, mocks or fixtures for Dart & Flutter. Triggers on: "test", "coverage", "mock", "fixture".
  Chains into: collect-coverage, run-static-analysis. Generates Dart & Flutter tests with the AAA pattern and one DRY factory per entity: unit, component and integration coverage of the happy path and of every error branch, with deterministic data and no dead parameters.
argument-hint: "[target class or module]"
license: MIT
metadata:
  framework: OAEF
  stack: dart-flutter
  version: 1.1.0
---

# Test Generator (Dart & Flutter)

> **Stack Profile:** Dart & Flutter
> **Governance Standard:** OAEF v1.1.0 (Author: Felipe Carvalho)
> **Skill Class:** primary

## Mission
Generate deterministic Dart and Flutter tests that cover the happy path and every error branch. Tests follow the AAA pattern, share one factory per entity, and run hermetically, without real network, storage or clock dependence.

## Territory
- `test/features/<feature>/**` — unit and widget tests mirroring the feature slice.
- `test/**` — shared harnesses (`buildWidget`/`pumpWidget` helpers) and global fixtures.
- `lib/features/<feature>/**` — the production contracts under test; tests never import `data` internals to assert against them.
- `pubspec.yaml` — `flutter_test`, `test` and the mock library already declared.

## Testing Pyramid
- **Unit** — entities, parsers, use cases and state holders. Fastest and most numerous; no widget tree.
- **Widget / component** — `WidgetTester.pumpWidget` renders one surface; assert on rendered structure, semantics and state transitions, not implementation details.
- **Integration** — a full flow through the router with fake repositories bound in the composition root.
- Error branches are mandatory at every level: timeouts, invalid payloads, empty results and thrown domain errors each get an assertion.

```dart
test('returns an empty list when the repository fails', () async {
  // Arrange
  final repository = FakeBookingRepository(error: TimeoutException('t'));
  final useCase = WatchBookings(repository);
  // Act
  final result = await useCase();
  // Assert
  expect(result, isEmpty);
});
```

## DRY Test Factories (make*)
One factory per entity, declared once per suite and reused. Parameters are only the fields a test actually varies; every remaining field gets a deterministic constant default.

```dart
Booking makeBooking({String id = 'b-1', String seat = 'unassigned'}) =>
    Booking(id: id, seat: seat);
```

- Never pass a dead parameter that no assertion observes.
- Optional collections default to a constant empty collection, never `null` (`CC-08`).
- Fixtures are deterministic: inject a fixed clock and fixed ids; no `DateTime.now()` in a factory.
- Mocks are declared per suite and reset between tests; `Mocktail`-style doubles replace real I/O.
- Never copy a factory into another file; import the shared one (Rule of Two applies to test fixtures).

## Repository Conformance Gate
- `oaef doctor` — structural, skill and entrypoint conformance.
- `oaef lint` — `CC-*` advisory sweep plus `SK-01`…`SK-06` and secret detection.
- `oaef clean-code` (native: `dart run tool/governance.dart clean-code`) — blocking under the `strict` profile.
- `flutter test --coverage` (or `dart test --coverage=coverage`) — the suite must pass deterministically.
- Unresolved findings are recorded in `docs/wiki/memory/handoff.md`.

## Exit Criteria
- Happy path and every error branch of the touched contract are asserted.
- Exactly one factory exists per entity and is shared by every suite that needs it.
- No test performs real I/O, depends on wall-clock time or leaks mutable state across tests.
- `flutter test --coverage` passes with no flaky or order-dependent test.

## Anti-Patterns
- A test that constructs an entity inline with five literals while a factory exists elsewhere.
- Factories with parameters no assertion reads (dead parameters).
- Asserting on private fields or widget internals instead of observable behavior.
- A shared mutable fixture mutated by one test and read by the next.
- Covering only the success path and leaving timeouts and invalid payloads untested.
