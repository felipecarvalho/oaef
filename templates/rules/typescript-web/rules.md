### Stack-Specific Architectural Rules (TypeScript & Web)

1. **Strict Anti-Suppression Policy**:
   - Suppressing compiler, linter, or typechecker diagnostics via `/* eslint-disable */`, `// eslint-disable-next-line`, `// @ts-ignore`, `// @ts-nocheck`, or `// biome-ignore` is strictly forbidden.
   - **Permitted Scoped Deprecation Exception**: `// eslint-disable-next-line @typescript-eslint/no-deprecated` is permitted solely when calling deprecated APIs from external npm dependencies during active transitional migrations.
   - **Permitted Code-Gen Exception**: `/* eslint-disable */` or `// biome-ignore lint: generated` is permitted solely at the file header of machine-generated files (matching `*.g.ts`, `*.generated.ts`, or files with `@generated` markers).
   - Blanket suppressions without specific rule tokens or on custom domain code are strictly forbidden.

2. **Prohibition of Helper Render Functions in UI**:
   - Never create helper rendering functions inside components (e.g., `const renderHeader = () => ...` or `function renderListItem()`).
   - Every UI sub-view or component MUST be extracted into a dedicated functional component with an explicit, typed props interface in its own file.
   - This ensures React/Vue/Solid reconciliation boundaries remain optimal and allows targeted memoization.

3. **Type Soundness & Ban on `any`**:
   - The `any` type is strictly forbidden. Use `unknown` with runtime type narrowing, zod/valibot schemas, or generics.
   - Prefer discriminated unions over loosely typed payloads.

4. **String Literal Unions over Numeric Enums**:
   - Prefer string literal unions (`type RequestStatus = 'idle' | 'loading' | 'success' | 'failure'`) over TypeScript numeric enums.
   - This eliminates runtime enum boilerplate and produces cleaner serialization.

5. **State Immutability**:
   - Direct mutation of state objects or arrays is strictly forbidden. Always use immutable update patterns, object spreads, or immutable libraries.

---

### Simplicity Ladder & Anti-AI-Slop

1. Climb the ladder before writing code — the best code is the line you did not have to add:
   1. **YAGNI** — do not build the extension point, the option object or the generic wrapper until a second caller exists.
   2. **Reuse in the codebase** — grep `src/shared/` and `src/components/` first.
   3. **Language/stdlib primitive** — `Array.prototype`, `Object.groupBy`, `URL`, `URLSearchParams`, `Intl`, `structuredClone`, `AbortController`.
   4. **Platform-native capability** — CSS media/container queries, `clamp()`, `srcset`/`sizes`, `:has()`, `prefers-reduced-motion`, the DOM itself before a dependency.
   5. **Already-installed dependency** — never add an npm package that is already in `package.json`.
   6. **One-line idiomatic expression** — optional chaining, nullish coalescing, a single `flatMap`.
   7. **Smallest correct diff** — touch the fewest files that make the change.
2. Banned ceremonies: one-line pass-through use cases, single-implementation interfaces with no mock need, forwarding wrappers that only rename a prop, and narration comments that restate the code.
3. Declare deliberate simplifications with `// ponytail: <ceiling + evolution trigger>`; remediations are tagged `[DELETE] [STDLIB] [NATIVE] [YAGNI] [SHRINK]`.
4. The safety frontier is never pruned: input validation, error routing, privacy, accessibility and Quality Gates always stay.

### SOLID & Substitutability

1. **S** — one reason to change per module, hook or class; no component that fetches, formats and renders.
2. **O** — extend via composition and small props, not by editing a switch that grows per caller.
3. **L** — every subtype/subclass honors the base contract; a substitution that throws where the base succeeded is a violation.
4. **I** — narrow, purpose-built interfaces; never force a consumer to depend on members it ignores.
5. **D** — depend on abstractions (interfaces/props), never on `axios`, `localStorage` or a concrete repository instance.
6. Concrete substitutability failure: overriding a method to `throw new Error('Not implemented'` — a production implementation never ships the unimplemented placeholder (`CC-09`).

### Dependency Inversion & Container Confinement

1. Inject through constructors, function parameters, React context or framework providers — not through module-level singletons.
2. Container/service-locator tokens `container.get(`, `Container.get(`, `container.resolve(`, `getService(` are allowed **only** in the composition root and presentation layer; they are banned in `src/domain/`, `src/data/`, `src/services/` and `src/repositories/` (`CC-07`).
3. Concrete network clients `axios.create(`, `new XMLHttpRequest(`, `new HttpClient(` are never instantiated outside the composition root; depend on an injected abstraction (`CC-10`).
4. Allowed resolution roots here: `src/main.ts(x)`, `src/app/**`, `**/di/**`, `**/presentation/**`.

### Non-Nullable Collections & Nullability Minimization

1. `null`/`undefined` is reserved for genuine absence with business meaning; absence of a collection is an empty collection.
2. A collection parameter or return defaults to a constant empty collection; do not accept `Array<...> | undefined`, `ReadonlyArray<...> | undefined`, `Map<...> | undefined`, `Set<...> | undefined` or `[] | undefined` without a non-null default (`CC-08`).
3. Declare the shared default once as a frozen constant (e.g. `const EMPTY_ITEMS: readonly Item[] = Object.freeze([])`) and reuse it.
4. The non-null assertion operators `!` and `as` with a nullable source stay banned in production logic; narrow with a guard instead.

### Two-Layer Resilience & Zero Silent Exception Swallowing

1. **Layer 1 (infrastructure)**: catch, log through the injected logger with structured context plus the error and its stack trace, then propagate or wrap into a domain error/`Result`.
2. **Layer 2 (coordination)**: wrap outbound calls in a barrier, timeout, retry with backoff or circuit breaker at the boundary.
3. Empty `catch (...) { }` and `.catch(() => {})` are prohibited — an empty handler with no log call and no rethrow is a violation (`CC-06`).
4. Log via the project logging interface, never `console.log`/`console.debug`/`console.warn` in production directories (`CC-05`).

### DRY Test Factories

1. One local factory per entity, named `make<Entity>` (e.g. `makeUser`), living next to the suite under `src/**/*.spec.ts` or `test/`.
2. Expose only the parameters that actually vary between tests; no dead parameters (no always-`undefined` options), no mutable shared fixtures, no ambient clock/random/network.
3. Deterministic data only: fixed ids, frozen dates, seeded randomness.
4. Runner facility: Vitest/Jest with `jsdom` and testing-library; prefer hand-written fakes over deep mock graphs.

### Solution Abstraction Elevation (Rule of Two)

1. The second occurrence of the same solution elevates it to one shared abstraction inside the same change set — a hook, helper or component under `src/shared/`.
2. A single-implementation abstraction that no test needs to mock is prohibited; inline it and reintroduce only when the second caller lands.
3. Every elevation documents its ceiling and the trigger that invalidates it (usually as a `// ponytail:` marker).

### Native / Multi-Platform Dependency Audit

1. Manifest of record: `package.json` plus the committed lockfile; adding a dependency is a reviewed decision, not an incidental one.
2. Prove the dependency against the declared browser/runtime target matrix (evergreen browsers and the supported Node runtime), not only against the local browser.
3. Run bundle-level duplication checks (`npm ls`, bundle-analyzer) so no transitive package is shipped twice; a native/WASM addon must be verified against every target before acceptance.

### Memory & Allocation Discipline

1. Avoidable allocation on a hot path is reported (`CC-11`): spreading `[...list]`, `.map(...)`/`.filter(...)` materialized inside a loop body or a hot render path.
2. Inspect without copying — pass the original reference when nothing changes; compute derived values in one stable pass instead of materializing intermediates.
3. Prefer a single memoized selector over allocating a new array on every render; use `structuredClone` only when a real copy is required.

### Privacy by Design (Consent & PII Redaction)

1. No personal data leaves the process or is persisted before the consent gate resolves; do not initialize third-party SDKs, analytics or trackers before consent.
2. Redaction is lazy and allocation-free: it returns the original reference unchanged when nothing is redactable.
3. Keep one keyword list of blocked keys (email, phone, token, document, ...) in a single module and emit `[REDACTED]` instead of silently dropping fields.
4. See `docs/standards/analytics_and_telemetry.md` for the full contract.

### Applicable Governance Checks

- Apply `CC-01` through `CC-11`; no documented no-ops for this stack (`CC-01`, `CC-02`, `CC-03`, `CC-04`, `CC-05`, `CC-06`, `CC-07`, `CC-08`, `CC-09`, `CC-10` blocking in `strict`, `CC-11` advisory). `oaef clean-code` enforces these; see `docs/standards/governance_checks.md`.
