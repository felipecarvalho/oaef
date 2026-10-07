### Stack-Specific Architectural Rules (React Native)

1. **Strict Anti-Suppression Policy**:
   - Suppressing compiler, linter, or typechecker diagnostics via `/* eslint-disable */`, `// eslint-disable-next-line`, `// @ts-ignore`, or `// biome-ignore` is strictly forbidden.
   - **Permitted Scoped Deprecation Exception**: `// eslint-disable-next-line @typescript-eslint/no-deprecated` is permitted solely when calling deprecated APIs from external npm dependencies during active transitional migrations.
   - **Permitted Code-Gen Exception**: Generated code in `codegen/`, `specs/`, or files with `@generated` markers are exempt from manual linter rules.
   - Blanket suppressions without specific rule tokens on domain code are strictly forbidden.

2. **Prohibition of Helper Render Functions in UI**:
   - Never create helper rendering functions inside components (e.g., `const renderRow = () => ...` or `function renderHeader()`).
   - Every UI sub-view or component MUST be extracted into a dedicated functional component with an explicit, typed props interface in its own file.
   - This keeps React reconciliation bounds optimal and enables granular memoization with `React.memo`.

3. **StyleSheet Discipline & Performance Optimization**:
   - All style declarations MUST be defined statically via `StyleSheet.create` outside component render functions.
   - Inline style objects (e.g. `style={ { padding: 16 } }`) inside render loops or list items are strictly prohibited to prevent garbage collection pressure.

4. **New Architecture & TurboModule Specifications**:
   - Native module bridges must target the New Architecture (Fabric renderer, TurboModules, Bridgeless mode).
   - Define typed native specs using TypeScript Codegen protocols (`TurboModuleRegistry.getEnforcing<Spec>('...')`).

5. **Strict Mobile Accessibility**:
   - All interactive elements (`Pressable`, `Touchable`) MUST specify `accessibilityRole` and `accessibilityLabel`.
   - Maintain a minimum touch target size of 44x44 dp across all interactive elements.

---

### Simplicity Ladder & Anti-AI-Slop

1. Climb the ladder before writing: YAGNI → reuse in the codebase → TypeScript/JavaScript stdlib → platform-native capability → already-installed dependency → one-line idiomatic expression → smallest correct diff.
2. Name real primitives: optional chaining, nullish coalescing (`??`), `Array.prototype` pipelines, `Object.groupBy`, `Intl`, `structuredClone`, `useMemo`/`useCallback`, `FlatList` virtualization.
3. Prefer React and React Native built-ins already in the tree over a new npm package; the best diff adds no dependency.
4. Banned ceremonies: one-line pass-through hook or use case, single-implementation context/provider pair without a mock need, forwarding wrapper component, narration comment restating the code.
5. Declare deliberate simplifications with `// ponytail: <ceiling + evolution trigger>` (for example `// ponytail: in-memory cache, move to AsyncStorage once writes exceed 10k/day`).
6. Remediation tags: `[DELETE]`, `[STDLIB]`, `[NATIVE]`, `[YAGNI]`, `[SHRINK]`.
7. Safety frontier is never pruned: validation, error routing, privacy, accessibility and Quality Gates stay.

### SOLID & Substitutability

1. S: one component/hook/module, one reason to change — split when a file mixes fetching, mapping and rendering.
2. O: extend through props, `children` and composition, not by editing closed shared components.
3. L: a component or hook accepting a contract honors it — never render a type/placeholder in place of real behavior.
4. I: props and context slices stay segregated; no context exposing unrelated state to every consumer.
5. D: depend on props/context abstractions, never on a concrete module singleton fetched at call time.
6. Substitutability failure mode: a component or hook that throws or renders nothing when a prop is missing from the declared contract; production must never contain `throw new Error('Not implemented'` (`CC-09`).

### Dependency Inversion & Container Confinement

1. Dependencies arrive by constructor, props or context; never resolved from a global at call time.
2. Container/service-locator tokens `container.get(`, `Container.get(`, `container.resolve(`, `getService(` are allowed only in the composition root and presentation layer; they are banned in `src/domain/`, `src/data/`, `src/services/` and `src/repositories/` (`CC-07`).
3. Concrete network clients (`axios.create(`, `new XMLHttpRequest(`, `new HttpClient(`) are never instantiated outside the composition root; depend on a typed client abstraction (`CC-10`).
4. Allowed roots of this stack: `src/` and `app/` entry modules, `src/di/` or the composition-root module, and feature `presentation/` slices.
5. Domain and data modules receive the client and repositories as parameters and stay pure and testable.

### Non-Nullable Collections & Nullability Minimization

1. Absence carries business meaning: `null`/`undefined` is used only when the domain distinguishes "no value" from "empty".
2. A collection parameter or return type defaults to a constant empty collection (`const EMPTY: readonly T[] = []`) rather than `undefined` (`CC-08`).
3. Declared type: optional array/object parameter typed `foo?: Array<T> | undefined` without an empty default is a finding; default it at the boundary.
4. Non-null assertion `!` and `as` casts stay banned in production logic; narrow with a guard or optional chaining instead.
5. API payloads are normalized at the boundary into non-null internal shapes before they reach domain code.

### Two-Layer Resilience & Zero Silent Exception Swallowing

1. Layer 1, infrastructure: catch the error, log with structured context plus the error and stack trace, then propagate or wrap it into a domain error/result.
2. Layer 2, coordination: guard the call site with a barrier, timeout, retry or circuit breaker; degradation is explicit, never accidental.
3. Prohibited empty handlers: `catch (...) { }` and the promise form `.catch(() => {})` with no log and no rethrow (`CC-06`).
4. Every rejection path routes through the logging interface (`logger`, `console.error` with context); raw `console.log` in production directories is itself a finding (`CC-05`).
5. Errors crossing a feature boundary are typed domain errors, not raw strings.

### DRY Test Factories

1. One local factory per entity: `make<Entity>(overrides?: Partial<Entity>)`, colocated with the suite.
2. The factory exposes only parameters that actually vary; dead or always-default parameters are removed.
3. Deterministic data only — no ambient `Date.now()`, `Math.random()` or live network inside a factory.
4. Runner: Jest (`npm test -- --coverage`), doubles with `jest.fn()` and `@testing-library/react-native` render helpers.
5. A factory used by a single test is inlined; only reuse justifies the helper (`Rule of Two`).

### Solution Abstraction Elevation (Rule of Two)

1. The same solution appearing in two or more places is elevated to one shared abstraction in the same change set.
2. The abstraction lives in the shared slice (`src/shared/`, `src/components/`) and documents its ceiling and the trigger that invalidates it.
3. A single-implementation interface, hook or provider with no mock need is prohibited — it is speculation, not design.
4. Elevation never hides a divergence: if the two call sites differ, the shared shape must model the real difference.

### Native / Multi-Platform Dependency Audit

1. Native dependencies are declared in `package.json` and pinned by the lockfile; the lockfile is committed and reviewed.
2. Before acceptance, prove a multi-target build: Android via `android/` (Gradle) and iOS via `ios/` (Podfile), across Debug and Release.
3. Audit transitive compatibility: autolinking resolution, duplicate-symbol and duplicate-class collisions, and Pod/Gradle version conflicts.
4. A dependency pulled in for a single feature that every build must carry is rejected — document the justification or inline the capability.

### Memory & Allocation Discipline

1. Avatar of avoidable allocation: spread `[...collection]` inside a loop body and `.map(...)` materialized in a loop body (`CC-11`, advisory).
2. Inspect without copying; return the original reference when nothing changes.
3. Hoist stable arrays/objects and `StyleSheet.create` results out of render; use `FlatList` virtualization instead of mapping large lists.
4. Memoize callbacks and derived values with `useMemo`/`useCallback` where identity churn triggers re-renders.

### Privacy by Design (Consent & PII Redaction)

1. No personal data leaves the process or is persisted before the consent gate is satisfied.
2. Redaction is lazy and allocation-free: return the original reference when nothing is redactable.
3. One keyword list of blocked keys (email, phone, name, token, address, ...) lives in a single analytics module.
4. Third-party SDKs, analytics and crash reporters are not initialized before consent.
5. See `docs/standards/analytics_and_telemetry.md` for the provider abstraction and the dual event taxonomy.

### Applicable Governance Checks

- `CC-01`, `CC-02`, `CC-03` (nullish `??=` over client/service/instance/provider), `CC-04`, `CC-05` (`console.log(`, `console.debug(`, `console.warn(`), `CC-06`, `CC-07`, `CC-08`, `CC-09`, `CC-10`, `CC-11` (advisory) apply to React Native; no check is a documented no-op for this stack. `oaef clean-code` enforces these; see `docs/standards/governance_checks.md`.
