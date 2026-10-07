### Stack-Specific Architectural Rules (Dart & Flutter)

1. **Strict Anti-Suppression Policy**:
   - Suppressing static analysis warnings via `// ignore:` or `// ignore_for_file:` is strictly forbidden.
   - **Permitted Scoped Deprecation Exception**: `// ignore: deprecated_member_use` is permitted solely when invoking deprecated APIs from external packages/SDKs during active framework migration.
   - **Permitted Code-Gen Exception**: `// ignore: type=lint` is permitted solely at the header of code-generator outputs (`*.g.dart`, `*.freezed.dart`).
   - Blanket suppressions without specific rule tokens are strictly forbidden.

2. **Prohibition of Helper Build Functions in UI**:
   - Never create helper rendering methods (e.g., `Widget _buildHeader()`, `Widget _buildItem()`).
   - Every UI sub-view or component MUST be extracted into a dedicated `StatelessWidget` (preferring `const` constructors) in its own file.
   - This enables granular element tree reconciliation, const caching, and keeps file sizes within Clean Sizing limits.

3. **Dot-Shorthand Syntax**:
   - Whenever the target context type is inferred by the Dart analyzer, use concise dot-shorthand syntax (`.s400`, `.large`, `.min`, `.loading`, `.start`, `.zero`) in constructors, typed arguments, switch expressions, and state mutations (`state.copyWith(status: .loading)`).
   - Explicit enum qualification (e.g. `SessionStatus.loading`) is reserved for generic parameters (`Object?` or `dynamic`), such as test matchers (`equals`, `having`).

4. **Strict Internationalization & Localization**:
   - Hardcoded user-facing strings in visual widgets are strictly forbidden.
   - All text rendered to users MUST be resolved via localization keys (e.g., `context.l10n.<key>`).

5. **State Management & Unidirectional Data Flow**:
   - Presentation widgets must never interact directly with database clients, network clients, or repositories.
   - All state mutations and asynchronous orchestrations must flow through Cubits or Blocs.

---

### Simplicity Ladder & Anti-AI-Slop
1. Climb the ladder before writing code: YAGNI > reuse in the codebase > `dart:core` primitive > Flutter-native capability > already-installed package > one-line idiomatic expression > smallest correct diff.
2. Language primitives first: `Iterable` pipelines, records, pattern matching, `switch` expressions, `StringBuffer`, extension methods, `const` constructors, `dart:collection`.
3. Platform-native before dependency: `LayoutBuilder`, `MediaQuery.sizeOf`, `ThemeData`, `SliverList`, `FutureBuilder`, and the framework's own widgets cover most layout and state needs.
4. Banned ceremonies: one-line pass-through use case, single-implementation interface with no mock need, forwarding wrapper widget that only re-emits its child props, narration comments restating the code.
5. Comment only the non-obvious constraint or the reason; never the mechanics of the next statement.
6. Record a deliberate simplification with the debt marker `// ponytail: <ceiling + evolution trigger>`, for example `// ponytail: in-memory cache, move to persistent storage once writes exceed 10k/day`.
7. Remediation tags for an anti-slop sweep: `[DELETE]` dead or unreachable code, `[STDLIB]` replace a hand-rolled helper, `[NATIVE]` replace a package with a framework capability, `[YAGNI]` drop speculative code, `[SHRINK]` collapse duplicated logic.
8. Safety frontier that is never pruned: input validation, error routing, privacy, accessibility and the Quality Gates (`dart analyze --fatal-infos`, `flutter test --coverage`).

### SOLID & Substitutability
1. Single responsibility: one widget, Cubit, repository or service owns one reason to change; split feature slices into `lib/features/<feature>/{presentation,domain,data}` rather than growing a god class.
2. Open/closed: extend behaviour through composition and new implementations of a domain contract, not by editing stable call sites with conditionals.
3. Liskov: a subtype or implementation MUST honour the full contract of its supertype; a `State` that swallows an unsupported operation is a LSP failure.
4. Interface segregation: narrow, consumer-owned contracts; never force a fake to implement methods it does not need.
5. Dependency inversion: depend on the abstract contract, not on the concrete `Repository`/`ApiClient`; the caller declares the dependency it needs.
6. Concrete substitutability failure mode: `throw UnimplementedError(` inside a production implementation of a contract, and `override` methods that silently no-op instead of preserving the supertype's post-condition.
7. A production contract implementation never contains `throw UnimplementedError(`; partial implementations are forbidden (`CC-09`).

### Dependency Inversion & Container Confinement
1. Inject through constructors with `required` and `final` fields; a class declares exactly the collaborators it uses and receives them from its parent.
2. `getIt<`, `GetIt.instance<` and `getIt(` are allowed only in the composition root and presentation layer: `lib/main.dart`, `**/di/**`, `**/presentation/**`, `*_screen.dart`, `*_view.dart`, `*_widget.dart`, `*_mixin.dart`, `**/debug/**`.
3. Domain, data and service packages MUST NOT resolve the container; they receive their dependencies (`CC-07`).
4. `HttpClient(` and `Dio(` are never instantiated in domain, data or service code; build the client in `lib/di/` or `lib/main.dart` and inject it behind a contract (`CC-10`).
5. The service-locator setup in `lib/di/` must not accept optional or nullable dependency parameters; every registration is explicit.
6. Prefer a typed factory or provider registered once over ambient lookup at the point of use.

### Non-Nullable Collections & Nullability Minimization
1. Model absence of a business entity with a domain type (sealed hierarchy, `Result`, dedicated state), never with a nullable field that has no business meaning.
2. A collection parameter or return defaults to a constant empty collection instead of `null`: annotate `const <T>[]`, `const <K, V>{}` or `const <T>{}` so the empty value is allocation-free.
3. Public signatures must not declare `List<...>?`, `Map<...>?` or `Set<...>?` when a `const` empty default expresses the same intent (`CC-08`); `copyWith` copy parameters are the documented exception.
4. A field that is only "temporarily null" during construction is a design smell; use `late final` initialization in the constructor body instead of a nullable public field.
5. The non-null assertion operator `!` stays banned in production logic; narrow with pattern matching, `if (value case final Value v)`, or an explicit `ArgumentError` guard.
6. Optional collaborators are constructor-optional (`{Dep? dep}`) only when a documented default exists; never store them nullable and assert non-null at every use site.

### Two-Layer Resilience & Zero Silent Exception Swallowing
1. Layer 1 (infrastructure): a `try`/`catch` in a data source catches a typed failure, logs with structured context plus the error and stack trace, then propagates or wraps it in a domain error or `Result.failure`.
2. Layer 2 (coordination): the Cubit/service layer applies a defensive barrier, timeout (`Future.timeout`), bounded retry or circuit breaker; it never retries blindly inside the same microtask.
3. Empty inline and multiline `catch (...) { }` blocks are strictly prohibited; every handler logs through the logging interface or rethrows/encapsulates (`CC-06`).
4. A `catch` that only calls `setState`/emits a state without recording the error is still swallowing; emit the user-facing state AND log the diagnostic.
5. Logging goes through the injected logger interface, never through `print(`; `print(` is prohibited in production directories (`CC-05`).
6. Log entries carry a namespace, the failing operation, the error object and the stack trace (`Error.throwWithStackTrace` or `stackTrace` from the handler).

### DRY Test Factories
1. One local factory per entity per suite, named `make<Entity>` (for example `makeBooking`, `makeUser`), returning a fully valid instance with every field populated.
2. Only parameters that actually vary across the suite are exposed; a parameter that every caller passes the same value for is a dead parameter and must be inlined.
3. Never pass `null` to a factory parameter just to satisfy its signature; a nullable parameter with a constant meaning is a design error.
4. Optional collection parameters on a factory default to a `const` empty collection, never to `null`.
5. Factories are deterministic: no ambient clock (`DateTime.now()`), no unseeded `Random`, no network; inject a fixed clock or a seeded generator when the value matters.
6. Test facility: `flutter_test` / `test` with `testWidgets` and `group`, `Mocktail`-style mocks registered per test, and `buildWidget`/`pumpWidget` harnesses; mocks are declared with `when(() => ...)` and verified with `verify`.

### Solution Abstraction Elevation (Rule of Two)
1. When the same solution appears in two places inside the same change set, elevate it to one shared abstraction under `lib/shared/` or `lib/ui/` in that same change set.
2. The shared abstraction lives in the layer that both call sites already depend on; never push a presentation helper into `domain/` to share it.
3. A single-implementation interface with no mock need is prohibited; a concrete class or extension method is the correct shape until a second consumer or a test double forces an interface.
4. Elevation is documented: state the ceiling the abstraction was designed for and the trigger that invalidates it, reusing the `// ponytail: <ceiling + evolution trigger>` marker where the boundary is non-obvious.
5. Duplicated `copyWith`, serialization or mapping logic is the most common violation; elevate the mapper rather than copying the field list.
6. The Rule of Two is balanced by the Simplicity Ladder: if elevation costs more than the duplicated code it removes, keep the duplication and record why.

### Native / Multi-Platform Dependency Audit
1. Every native or plugin dependency is declared in `pubspec.yaml` and pinned in `pubspec.lock`; a dependency added without a lockfile diff is not auditable.
2. Before accepting a package with native code, audit its transitive compatibility in the downstream Android and iOS host projects: `android/app/build.gradle(.kts)` and `ios/Podfile`.
3. Prove the build on all three Flutter targets — Debug, Profile and Release — with no duplicate-symbol or duplicate-class collision in the merged native artifacts.
4. Verify the supported platform minimums (Android `minSdkVersion`, iOS deployment target, macOS/Web when claimed) against the host configuration before merge.
5. A federated plugin must be validated on every platform it declares, not only the one under development.
6. Record the audit evidence (commands run, targets built, result) in the pull request; an unproven native dependency is not accepted.

### Memory & Allocation Discipline
1. Inspect without copying: iterate the original `Iterable` instead of materializing a new list for a read-only pass.
2. Return the original reference when nothing changes; a transformer that produced no change must return its input unchanged rather than a rebuilt copy.
3. `List.from(`, `Map.from(` and spread `[...]` are avoidable allocations when used merely to copy a collection (`CC-11`).
4. Do not build an intermediate collection inside a loop body on a hot path (`build()`, scroll item builders, stream transforms); build once outside the loop or use a lazy `Iterable`.
5. Prefer `const` constructors, `const` literal collections and `final` fields so the framework can reuse element trees and skip rebuilds.
6. Watch hot render paths: allocation inside `itemBuilder` of `ListView.builder`/`SliverList` multiplies per frame and per item.

### Privacy by Design (Consent & PII Redaction)
1. No personal data leaves the process or is persisted before the user has granted consent; the consent gate is checked before the first analytics or telemetry call.
2. Redaction is lazy and allocation-free: return the original reference unchanged when the payload contains nothing redactable, and allocate only when a key is actually masked.
3. Maintain one blocked-key keyword list (`email`, `phone`, `document`, `token`, `password`, `address`, `birthdate`, `device_id`) in a single module so every redaction path shares it.
4. Masked values are replaced with `[REDACTED]`; keys excluded entirely from transmission are stripped from the payload rather than emitted empty.
5. Third-party SDKs (analytics, crash reporting, attribution) are not initialized before consent, and their disclosure hooks must be disabled until the gate opens.
6. Logs, error reports and analytics events pass through the same redactor; never log a raw request or response body.
7. See `docs/standards/analytics_and_telemetry.md` for the provider abstraction, the dual event taxonomy and the sanitizer contract.

### Applicable Governance Checks
- `dart-flutter` applies `CC-01`, `CC-02`, `CC-03`, `CC-04`, `CC-05`, `CC-06`, `CC-07`, `CC-08`, `CC-09`, `CC-10` (blocking under `strict`) and `CC-11` (advisory); there are no documented no-ops for this stack. `oaef clean-code` enforces these; see `docs/standards/governance_checks.md`.
