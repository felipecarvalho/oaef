### Stack-Specific Architectural Rules (Kotlin & Android)

1. **Strict Anti-Suppression Policy**:
   - Suppressing compiler warnings or detekt/ktlint rules via `@Suppress(...)` or `@file:Suppress(...)` is strictly forbidden.
   - **Permitted Scoped Deprecation Exception**: `@Suppress("DEPRECATION")` or `@Suppress("DeprecatedCallableAddReplaceWith")` is permitted solely when invoking deprecated APIs from external Java/Kotlin libraries during active migration.
   - **Permitted Code-Gen Exception**: `@file:Suppress("UNCHECKED_CAST")` or `@Generated` is permitted solely in build-tool generated files (e.g. Room, Dagger, Wire outputs).
   - Blanket suppressions without specific warning tokens are strictly forbidden.

2. **Prohibition of Monolithic Composable Functions**:
   - In Jetpack Compose, avoid monolithic `@Composable` functions.
   - Extract distinct UI sub-elements into dedicated `@Composable` functions in separate files, annotated with `@Preview`.
   - Maintain a clean separation between stateful container composables and stateless presentation composables.

3. **Strict Null Safety Discipline**:
   - The non-null assertion operator `!!` is strictly forbidden in production and domain code.
   - Use safe calls `?.`, the Elvis operator `?:`, or explicit precondition functions (`checkNotNull`, `requireNotNull`).

4. **Sealed Interfaces for Domain State Modeling**:
   - Model UI and business state using `sealed interface` or `sealed class` hierarchies.
   - Process states using exhaustive `when` expressions without a fallback `else` branch, ensuring compile-time safety when new states are added.

5. **Structured Coroutines & Scope Binding**:
   - Never launch coroutines into `GlobalScope`.
   - Always bind asynchronous tasks to structured scopes (`viewModelScope`, `lifecycleScope`, or an injected `CoroutineScope`).

---

### Simplicity Ladder & Anti-AI-Slop

1. Climb the seven rungs before writing any code: YAGNI (do not build it) > reuse an existing type in the codebase > Kotlin stdlib primitive (`map`/`filter`/`fold`, `Result`, sealed interface, value class, `use {}`) > Jetpack Compose platform primitive (`remember`/`derivedStateOf`, adaptive layout, resource qualifier) > already-declared Gradle dependency > one-line idiomatic expression (Elvis `?:`, scope function, destructuring) > smallest correct diff.
2. Banned ceremonies: a one-line pass-through use case, a single-implementation interface with no mock or second caller, a forwarding wrapper that adds no behavior, a narration comment restating the next statement, a `data class` mirroring another type field for field.
3. Mark a deliberate simplification ceiling with the debt marker `// ponytail: <ceiling + evolution trigger>` so the decision can be reopened; it is report-only and never blocking.
4. Remediate with the tags `[DELETE]` (remove entirely), `[STDLIB]` (use a stdlib primitive), `[NATIVE]` (use a Compose/platform capability), `[YAGNI]` (do not build it), `[SHRINK]` (smallest correct diff).
5. Fix bugs at the shared root: `grep` every caller of the failing path and add one guard at the common origin instead of patching each call site.
6. Safety frontier — validation, error routing, privacy, accessibility and Quality Gates are never pruned by simplicity.

### SOLID & Substitutability

1. **S** — one reason to change per class, `@Composable`, `ViewModel` or module; split by behavior, not by line count.
2. **O** — extend behavior with a new sealed-interface case or a new strategy implementation, not with a `when` branch added to unrelated code.
3. **L** — a subtype or implementation must honor the full contract of the type it substitutes; a base or interface method must never throw on an unimplemented path.
4. **I** — narrow, cohesive interfaces consumed by the caller instead of wide fat interfaces.
5. **D** — depend on interfaces or `expect` declarations; concrete classes are supplied at the composition root.
6. Substitutability failure mode: a production implementation that carries `TODO(` or `throw NotImplementedError(` in a contract method — a violation of LSP and of `CC-09`.

### Dependency Inversion & Container Confinement

1. Dependencies arrive through constructor parameters (`private val`), never through static access or lazy late assignment.
2. Koin/Kotlin service-locator APIs — `inject<`, `KoinComponent`, `getKoin().get(`, `GlobalContext.get().get(` — are allowed **only** at the composition root and presentation layer: `**/di/**`, `*Module.kt`, `*Application*`, `*Activity*`; they are banned in `**/domain/**`, `**/data/**`, `**/services/**` and `**/repositories/**`.
3. Concrete network clients — `OkHttpClient(`, `HttpClient(` — are never instantiated outside the composition root; a repository depends on an interface or an `expect`/`actual` abstraction whose concrete engine is provided at the root.
4. `TODO(` and `throw NotImplementedError(` in production contract code are prohibited: implement the contract, do not ship a placeholder.

### Non-Nullable Collections & Nullability Minimization

1. Absence carries business meaning: use `null` only for a real missing value, never as an empty-or-unknown container.
2. A collection parameter or return defaults to a constant empty collection: `List<T>?`, `Map<K,V>?` and `Set<T>?` are prohibited in public signatures — default with `emptyList()`, `emptyMap()` or `emptySet()` wrapped in `Collections.unmodifiable*`/`ImmutableList` when immutability is required.
3. Prefer `List<T>` over `MutableList<T>` in exposed signatures; keep mutability internal to the producing scope.
4. The non-null assertion operator `!!` stays banned in production and domain logic; use `?.`, `?:` or `checkNotNull`/`requireNotNull`.

### Two-Layer Resilience & Zero Silent Exception Swallowing

1. Layer 1 (infrastructure): `catch`, log with structured context plus the error and stack trace, then propagate or wrap into a domain `Result`/sealed error.
2. Layer 2 (coordination): a timeout, retry or circuit-breaker barrier around every boundary crossing.
3. `catch (...) { }` with an empty body — no log call and no rethrow — is prohibited (`CC-06`); a swallowed exception is a defect even when the failure is expected.
4. Route all diagnostics through the injected logging interface, never through `println(` in production code (`CC-05`).

### DRY Test Factories

1. One local factory per entity per suite: `make<Entity>(...)` returning a fully-formed instance.
2. Only parameters that vary between tests are exposed; no dead parameters, no nullable parameters that are always passed.
3. Data is deterministic: no ambient clock, no random source, no live network; inject a fixed `Clock`/seed where the production code needs one.
4. Runner and doubles: JUnit 5 with `kotlin.test` assertions, `MockK` or hand-written fakes implementing the interface.

### Solution Abstraction Elevation (Rule of Two)

1. The same solution appearing in two or more places becomes one shared abstraction in the same change set — a shared composable, a common extension function, a base sealed hierarchy.
2. A single-implementation abstraction with no mock or second caller is prohibited; it is ceremony, not structure, and belongs to the simplicity ladder's ban list.
3. Every elevation documents its ceiling and the trigger that invalidates it, using the `// ponytail:` marker when the abstraction is intentionally narrow.

### Native / Multi-Platform Dependency Audit

1. Native dependency sources: `build.gradle.kts`, the version catalog `gradle/libs.versions.toml`, and Android ABI assets (`jniLibs`/`*.so`) pulled in transitively.
2. Prove every build target under Debug and Release — `./gradlew assembleDebug assembleRelease test detekt ktlintCheck` — with no symbol collision or duplicated class across the packaged ABI set (`checkDebugDuplicateClasses`).
3. Before accepting a native dependency, audit transitive compatibility against downstream host repositories: ABI availability for each packaged architecture, minimum SDK, and absence of a class or symbol already provided by another module.

### Memory & Allocation Discipline

1. Avoidable-allocation shape for this stack: `.toList()` / `.toMutableList()` materialized inside a loop body (`CC-11`, advisory) — hoist the conversion out of the loop or use a single sequence pipeline.
2. Inspect without copying: read via `Sequence`/sequence-derived views or index access instead of materializing an intermediate `List` on a hot path.
3. Return the original reference when nothing changed instead of rebuilding an equal collection; avoid intermediate collections in `@Composable` recomposition paths and use `remember`/`derivedStateOf` to keep derived data stable.

### Privacy by Design (Consent & PII Redaction)

1. No personal data leaves the process or is persisted before the consent gate is satisfied; gate analytics and third-party SDK initialization behind the recorded consent state.
2. Redaction is lazy and allocation-free: it returns the original reference when nothing is redactable, and only copies the payload when a blocked key is present.
3. Keep one blocked-key keyword list in a single module; route all payloads through that sanitizer before dispatch and replace values with `[REDACTED]` (or strip the key entirely for identifiers).
4. See `docs/standards/analytics_and_telemetry.md` for the provider abstraction, the dual event taxonomy and the sanitizer contract.

### Applicable Governance Checks

- This stack is enforced by `CC-01`, `CC-02`, `CC-04`, `CC-05`, `CC-06`, `CC-07`, `CC-08`, `CC-09`, `CC-10` and the advisory `CC-11`; `CC-03` is a documented no-op because Kotlin has no idiomatic late mutable lazy initialization. `oaef clean-code` enforces these; see `docs/standards/governance_checks.md`.
