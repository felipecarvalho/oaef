### Stack-Specific Architectural Rules (Kotlin Multiplatform / KMP)

1. **Strict Anti-Suppression Policy**:
   - Suppressing compiler warnings or detekt/ktlint rules via `@Suppress(...)` or `@file:Suppress(...)` is strictly forbidden.
   - **Permitted Scoped Deprecation Exception**: `@Suppress("DEPRECATION")` or `@Suppress("DeprecatedCallableAddReplaceWith")` is permitted solely when invoking deprecated APIs from external multiplatform libraries during active migration.
   - **Permitted Code-Gen Exception**: `@file:Suppress("UNCHECKED_CAST")` or `@Generated` is permitted solely in build-tool generated files (e.g. SQLDelight, KSP, Wire outputs).
   - Blanket suppressions without specific warning tokens are strictly forbidden.

2. **Source-Set Separation (`commonMain` vs Platform Sets)**:
   - All domain business logic, data models, repositories, and Compose Multiplatform UI components MUST reside in `commonMain`.
   - Platform-specific implementations (`androidMain`, `iosMain`, `desktopMain`) are strictly restricted to hardware/OS bridging via `expect`/`actual` declarations or injected interfaces.
   - Platform SDK dependencies (e.g. Android `Context`, Apple `UIViewController`) MUST NOT leak into `commonMain`.

3. **Compose Multiplatform UI Decomposition**:
   - Prohibit monolithic `@Composable` functions. Extract distinct sub-views into dedicated `@Composable` functions in separate files.
   - Maintain a strict boundary between stateful container composables and stateless presentation composables.
   - Preview annotations (`@Preview`) must be used for modular visual verification.

4. **Strict Null Safety Discipline**:
   - The non-null assertion operator `!!` is strictly forbidden in production and domain code.
   - Use safe calls `?.`, the Elvis operator `?:`, or explicit precondition functions (`checkNotNull`, `requireNotNull`).

5. **Multiplatform Coroutines & Flow Discipline**:
   - All asynchronous state streaming must flow through `StateFlow` or `SharedFlow`.
   - Never launch coroutines into `GlobalScope`. Always bind jobs to structured, cancelable scopes (e.g. `viewModelScope` or injected `CoroutineScope`).

---

### Simplicity Ladder & Anti-AI-Slop

1. Climb before writing: YAGNI > reuse an existing `commonMain` API > Kotlin stdlib primitive (`map`/`filter`/`fold`, `Result`, sealed hierarchy, value class) > `expect/actual` multiplatform capability > already-installed dependency (coroutines/`Flow`, Compose Multiplatform) > one-line idiomatic expression > smallest correct diff.
2. Banned ceremonies: one-line pass-through use case that only delegates to a repository; single-implementation interface with no fake/mock need; `expect/actual` pair that just forwards; forwarding wrapper `class` around a dependency; narration comment restating the next line.
3. Mark deferred complexity with `// ponytail: <ceiling + evolution trigger>` (e.g. `// ponytail: in-memory cache; replace with persistent store when multi-session is required`).
4. Remediation tags: `[DELETE]`, `[STDLIB]`, `[NATIVE]`, `[YAGNI]`, `[SHRINK]`.
5. Safety frontier never pruned: validation, error routing, privacy, accessibility and Quality Gates.

### SOLID & Substitutability

1. Single responsibility: one source-set concern per class, one reason to change per file.
2. Open/closed: extend behavior through composition and `sealed` hierarchies, not flag parameters.
3. Liskov: every `actual` implementation and every test fake must honor the `expect`/interface contract identically.
4. Interface segregation: small consumer-owned interfaces instead of fat repository contracts.
5. Dependency inversion: depend on `commonMain` abstractions, never on platform classes.
6. Substitutability failure mode: an `actual` type or fake that silently narrows behavior (throws, returns empty, changes nullability) where the `expect` declares a total contract.
7. Production implementations never contain `TODO(` or `throw NotImplementedError(` (`CC-09`).

### Dependency Inversion & Container Confinement

1. Inject dependencies via constructor or parameters; fields are `private val` and immutable.
2. Container/service-locator tokens (`inject<`, `KoinComponent`, `getKoin().get(`, `GlobalContext.get().get(`) are allowed only in `**/di/**`, `*Module.kt`, `*Application*`, `*Activity*` (`CC-07`).
3. Never resolve the container from `commonMain` domain/data layers or from Compose composables outside the composition root and presentation entry points.
4. Concrete network clients (`OkHttpClient(`, `HttpClient(`) are instantiated only in the composition root (`**/di/**`, `*Module.kt`) and exposed as abstractions to `commonMain` (`CC-10`).
5. Platform-dependent implementations are bound at the composition root and reach `commonMain` through interfaces, not through `expect` classes that hide a container lookup.

### Non-Nullable Collections & Nullability Minimization

1. Absence carries business meaning: use a sealed `Result`/value type instead of a nullable field when the reason for absence is meaningful.
2. A collection parameter or return defaults to a constant empty collection: `emptyList()`, `emptyMap()`, `emptySet()`.
3. Public signature must not expose `List<T>?` / `Map<K,V>?` / `Set<T>?` without an immutable constant-empty default (`CC-08`).
4. Never convert a constant-empty default into `mutableListOf()` at the boundary; keep it immutable and read-only.
5. The non-null assertion operator `!!` stays banned in production and domain logic (see rule 4); prefer `?.`, `?:`, `checkNotNull`, `requireNotNull`.

### Two-Layer Resilience & Zero Silent Exception Swallowing

1. Layer 1 (infrastructure): catch, log with structured context plus error and stack trace, then propagate or wrap into a domain error type.
2. Layer 2 (coordination): timeouts, bounded retries, `Result`-based barriers and backpressure on `Flow`.
3. Empty `catch (...) { }` bodies are prohibited; a handler is empty when it holds at most a comment and no log, rethrow or error routing (`CC-06`).
4. Use the structured logging interface (injected logger), never `println(` (`CC-05`).
5. Never swallow errors to make a test or build pass; route them through the same discipline as production paths.

### DRY Test Factories

1. One local factory per entity named `make<Entity>` inside the suite that uses it; no shared mutable global fixtures.
2. Only parameters that actually vary across tests; no dead parameters and no optional-null parameters that are never supplied.
3. Deterministic data only: inject clocks, random sources and dispatchers; never rely on ambient time, randomness or network in `commonTest`.
4. Use `kotlin.test`, `runTest` and fake implementations over heavyweight mocking; fakes must satisfy the same contract as production (`LSP`).
5. Factories return immutable value types; variant builders compose via named factory presets rather than boolean flags.

### Solution Abstraction Elevation (Rule of Two)

1. When the same solution appears in two places, elevate it to one shared abstraction in the same change set.
2. Elevation documents its ceiling and the trigger that invalidates it, using the `// ponytail:` marker.
3. A single-implementation abstraction with no fake/mock need is prohibited; prefer a concrete `commonMain` type until a second consumer or a test double forces the interface.
4. Never elevate a platform fork that should be an `expect/actual` pair, and never duplicate an `expect/actual` pair that stdlib or a dependency already provides.

### Native / Multi-Platform Dependency Audit

1. Declare dependencies in `gradle/libs.versions.toml` and `build.gradle.kts`; pin versions via the catalog.
2. Before accepting a dependency with native code, prove compilation for every declared target: `androidDebug`/`androidRelease`, `iosArm64`, `iosX64`, `iosSimulatorArm64`, `desktop`.
3. Verify no duplicate-class or symbol collision across targets before merge.
4. Audit transitive compatibility in downstream host repositories that consume the module; a dependency that compiles here but collides in a host is rejected.

### Memory & Allocation Discipline

1. Avoid `.toList()` / `.toMutableList()` materialization inside a loop body; keep transforms lazy through the `Sequence`/`Flow` pipeline (`CC-11`).
2. Inspect and map without copying; return the original reference when nothing changes.
3. Avoid intermediate collections on hot paths; use `asSequence()` and in-place transforms where the contract allows.
4. Reuse immutable constant-empty collections rather than allocating fresh ones per call.

### Privacy by Design (Consent & PII Redaction)

1. No personal data leaves the process or is persisted before the consent gate is passed.
2. Redaction is lazy and allocation-free on the clean path; return the original reference when nothing is redactable.
3. Keep one blocked-key keyword list in a single module and route all payloads through it.
4. Third-party SDKs are not initialized before consent; analytics dispatchers register providers idempotently and isolate per-provider failures.
5. See `docs/standards/analytics_and_telemetry.md`.

### Applicable Governance Checks

1. `CC-01`, `CC-02`, `CC-04`, `CC-05`, `CC-06`, `CC-07`, `CC-08`, `CC-09`, `CC-10` are blocking in the `strict` profile; `CC-11` is advisory. `CC-03` (mutable lazy initialization) is a documented no-op on this stack. `oaef clean-code` enforces these; see `docs/standards/governance_checks.md`.
