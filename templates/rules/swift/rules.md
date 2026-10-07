### Stack-Specific Architectural Rules (Swift & iOS)

1. **Strict Anti-Suppression Policy**:
   - Suppressing compiler warnings or SwiftLint diagnostics via `// swiftlint:disable`, `// swiftlint:disable:next`, or `// swiftlint:disable:this` is strictly forbidden.
   - **Permitted Scoped Deprecation Exception**: `// swiftlint:disable:next deprecated` or `// swiftlint:disable:next deprecated_call` is permitted solely when calling deprecated Apple framework or external package APIs during active migration.
   - **Permitted Code-Gen Exception**: `// swiftlint:disable all` is permitted solely at the file header of machine-generated files (matching `*.generated.swift` or SwiftGen/Sourcery outputs).
   - Blanket suppressions without specific rule tokens on domain code are strictly forbidden.

2. **Prohibition of Helper ViewBuilder Functions**:
   - In SwiftUI, avoid creating `@ViewBuilder func buildHeader() -> some View` helper functions inside a parent view.
   - Extract sub-views into dedicated `View` structs in their own files to allow fine-grained SwiftUI body invalidation and preview generation.

3. **Strict Swift 6 Concurrency Compliance**:
   - Enable complete concurrency checking. Ensure all types crossing actor boundaries conform to `Sendable`.
   - UI updates, ViewModel state changes, and navigation must be explicitly bound to `@MainActor`.

4. **Zero Force Unwrapping**:
   - Force unwrapping (`!`) and force casting (`as!`) are strictly prohibited in domain and production logic.
   - Use `guard let`, `if let`, or optional chaining to safely handle nil and downcasting.

5. **Exhaustive Pattern Matching**:
   - Use exhaustive `switch` statements over domain enums without relying on a catch-all `default:` clause, ensuring compiler checks catch any new enum cases.

---

### Simplicity Ladder & Anti-AI-Slop

- Climb the seven rungs before writing code: YAGNI -> reuse in the codebase -> Swift stdlib primitive (`Array`/`Dictionary` pipelines, `Optional` chaining, `Result`, `Codable`, `async/await`) -> platform-native capability (SwiftUI modifiers already available, `ViewThatFits`, `NavigationStack`) -> already-installed package -> one-line idiomatic expression -> smallest correct diff.
- Banned ceremonies: one-line pass-through use case, single-implementation protocol without a mock need, forwarding wrapper (a type that only delegates), narration comment restating the code.
- Declare deliberate ceilings with `// ponytail: <ceiling + evolution trigger>`; sweep remediation under the tags `[DELETE] [STDLIB] [NATIVE] [YAGNI] [SHRINK]`.
- Safety frontier: validation, error routing, privacy, accessibility and Quality Gates are never pruned.

### SOLID & Substitutability

- Single responsibility: a `View`, a `ViewModel` and a `Repository` each own exactly one reason to change.
- Open/closed: extend behavior by conforming new types to a protocol, not by editing existing `switch` bodies.
- Liskov: every conformer upholds the full protocol contract; a production implementation never hides an unimplemented contract behind `fatalError("TODO` or `preconditionFailure(` (`CC-09`).
- Interface segregation: small role protocols (`Fetching`, `Persisting`) instead of one god protocol.
- Dependency inversion: collaborators are protocol-typed; concrete `URLSession` access is confined.
- Substitutability failure mode: a stub conformer that traps at runtime instead of implementing the contract.

### Dependency Inversion & Container Confinement

- Inject collaborators via initializer (`init(repository: Repository)`); never late-assign a client/service/property (`CC-03`).
- Container/resolver tokens `Resolver.resolve(`, `DependencyContainer.shared`, `container.resolve(` are allowed only in `**/App*/**`, `*Assembly.swift` and `**/DI/**` (`CC-07`).
- `URLSession.shared` is never referenced outside the composition root; depend on a protocol wrapper around it (`CC-10`).
- `Domain`, `Data` and `Presentation` types receive dependencies; they never reach for a global container.

### Non-Nullable Collections & Nullability Minimization

- `nil` carries business meaning only; otherwise use `guard let` / `if let`.
- A collection parameter or return defaults to a constant empty collection: `[Element]?`, `[K: V]?` and `Set<T>?` default to `[]`, `[:]` and `[]` (`CC-08`).
- Force unwrap `!` and force cast `as!` stay banned in production logic (see rule 4); prefer optional chaining `?.` and `??`.
- Model error paths with `throws`/`Result`, not with an optional that silently collapses failure.

### Two-Layer Resilience & Zero Silent Exception Swallowing

- Layer 1 (infrastructure): catch, log structured context plus error and stack trace through an injected `Logger`/`os.Logger`, then propagate or map into a domain error.
- Layer 2 (coordination): timeout, retry with backoff, barrier or circuit breaker around remote calls; structured concurrency via `Task`/`async let` with explicit cancellation.
- Prohibited handler shape: an empty `catch { }` with no log call and no rethrow (`CC-06`).
- Never emit `print(` for diagnostics in production; use the logging interface (`CC-05`).

### DRY Test Factories

- One local factory per entity named `make<Entity>` (`makeUser`, `makeSession`); expose only parameters that vary.
- No dead parameters and no ambient clock/random/network in fixtures; data is deterministic per test.
- Test facility: `XCTest`/`swift-testing`, protocol-conforming doubles and fakes, builders living in `Tests/`.

### Solution Abstraction Elevation (Rule of Two)

- Two occurrences of the same solution become one shared abstraction in the same change set.
- A single-implementation abstraction with no mock need is prohibited (the anti-over-engineering razor).
- Each elevation documents its ceiling and the evolution trigger that invalidates it.

### Native / Multi-Platform Dependency Audit

- Manifests: `Package.swift` and the resolved `Package.resolved`; native binaries ship as XCFrameworks.
- Prove the multi-platform build: iOS device and simulator, plus macOS when the module targets it, in Debug/Release as applicable.
- Before accepting a dependency with native code, audit transitive compatibility across downstream host repositories and confirm the multi-target build has no duplicate symbols or classes.

### Memory & Allocation Discipline

- Avoidable allocation shape: `Array(` inside a loop body (`CC-11`); pass the existing sequence, use `lazy` pipelines or mutate in place.
- Inspect without copying and return the original reference when nothing changes.

### Privacy by Design (Consent & PII Redaction)

- A consent gate precedes any personal data leaving the process or being persisted; third-party SDKs are not initialized before consent.
- Redaction is lazy and allocation-free and returns the original reference when nothing is redactable; blocked keys live in a single keyword list in one module.
- See `docs/standards/analytics_and_telemetry.md`.

### Applicable Governance Checks

`CC-01`, `CC-02`, `CC-04`, `CC-05`, `CC-06`, `CC-07`, `CC-08`, `CC-09`, `CC-10` and `CC-11` apply to Swift; `CC-03` is a documented no-op because Swift has no idiomatic late-assignment lazy initializer. `oaef clean-code` enforces these; see `docs/standards/governance_checks.md`.
