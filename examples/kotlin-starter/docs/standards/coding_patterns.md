<!-- oaef:section:standard:coding_patterns -->
# Coding Standards & Clean Code Craftsmanship

> Canonical code quality, clean architecture, and craftsmanship guide for `kotlin-starter`.

---

## 1. Clean Sizing Limits

To minimize cognitive load, maintain high cohesion, and keep cyclomatic complexity low:

| Scope | Physical Line Limit | Target Clean Code | Action if Exceeded |
| :--- | :--- | :--- | :--- |
| **Files** | **<= 300 LOC** | **<= 200 LOC** | Decompose into smaller focused modules/components. |
| **Methods / Functions** | **<= 50 LOC** | **<= 30 LOC** | Extract helper routines, guard clauses, or delegates. |

*Files exceeding 300 lines or functions exceeding 50 lines are rejected by the automated Quality Gate.*

---

## 2. Meaningful Names (Robert C. Martin Clean Code Standards)

Names are the primary communication medium in code. Names must be clear, unambiguous, and intention-revealing.

### 2.1 Intention-Revealing Identifiers
- A name should answer: **why it exists**, **what it does**, and **how it is used**.
- If a variable or function requires a comment to explain its purpose, the name has failed.
- Examples:
  - BAD: `int d; // elapsed time in days` -> GOOD: `int elapsedTimeInDays;`
  - BAD: `bool flag;` -> GOOD: `bool isAccountActive;`

### 2.2 Strict Ban on Cryptic Abbreviations
Never use arbitrary or lazy abbreviations. Use the complete, self-documenting word:

| Banned Abbreviation | Mandatory Full Identifier |
| :--- | :--- |
| `btn`, `submitBtn` | `button`, `submitButton` |
| `val`, `curVal` | `value`, `currentValue` |
| `res`, `resp` | `response` or `result` |
| `req` | `request` |
| `usr` | `user` |
| `cb` | `callback`, `onSuccessCallback` |
| `temp`, `tmp` | `temporaryDirectory`, `intermediateBuffer` |
| `data`, `info`, `obj` | Specific domain noun (e.g. `orderSummary`, `userProfile`) |
| `mgr` | `manager`, `coordinator`, `service` |
| `param`, `params` | `parameter`, `parameters` |
| `fn` | `function`, `action`, `operation` |
| `cnt` | `count`, `itemCount` |
| `idx` | `index`, `itemIndex` |
| `buf` | `buffer` |
| `str` | Descriptive text noun (e.g. `titleText`, `sanitizedQuery`) |
| `num` | `number`, `quantity`, `amount` |
| `doc` | `document` |
| `elem` | `element` |
| `curr`, `prev` | `current`, `previous` |

*(Exception: Parameter names mandated by third-party language SDKs, such as Flutter's `BuildContext context` or Go's `context.Context ctx`)*.

### 2.3 Single-Letter Variable Prohibition
- Single-letter variable names (`a`, `b`, `c`, `d`, `e`, `k`, `m`, `n`, `s`, `t`, `v`, `x`, `y`, `z`) are strictly forbidden.
- Loop counter variables (`i`, `j`) are allowed **ONLY** in localized loops of `<= 5` lines.
- For nested loops or longer blocks, use clear contextual names (`rowIndex`, `columnIndex`, `charIndex`).

### 2.4 Ban on Noise Words & Hungarian Notation
- Avoid adding redundant words that provide zero conceptual distinction:
  - BAD: `ProductData`, `ProductInfo`, `ProductObject` -> GOOD: `Product`
  - BAD: `CustomerRecord` -> GOOD: `Customer`
- Do not encode data types into variable names (Hungarian notation):
  - BAD: `nameString`, `accountList`, `userMap` -> GOOD: `name`, `accounts`, `usersByIdentifier`

### 2.5 Parts of Speech & Verbs
- **Classes and Types**: MUST be nouns or noun phrases (`UserProfile`, `PaymentGateway`, `InvoiceRepository`).
- **Methods and Functions**: MUST be verbs or verb phrases (`calculateDiscount`, `validateSession`, `sendNotification`).
- **Booleans**: MUST read as predicates (`isVisible`, `hasExpired`, `canSubmit`).
- **Consistency**: Pick one word per concept across the entire codebase. Do not interchange `fetch`, `retrieve`, and `get` for identical retrieval operations.

---

## 3. Function Discipline & Craftsmanship

### 3.1 Single Responsibility Principle (Do One Thing)
- A function should do one thing, do it well, and do it only.
- If a function contains sections that can be logically grouped and named (e.g. `// validate`, `// calculate`, `// save`), each section belongs in its own dedicated function.

### 3.2 Single Level of Abstraction (SLAP)
- All operations within a function must operate at the same conceptual level of abstraction. High-level orchestrators must not mix with low-level string slicing or raw byte manipulation.

### 3.3 Function Arguments
- **Ideal**: 0 (niladic), 1 (monadic), or 2 (dyadic).
- **Avoid**: 3 arguments (triadic).
- **Prohibited**: 4 or more arguments (polyadic). Refactor 3+ arguments into a strongly typed configuration object, record, or parameter struct.

### 3.4 Strict Prohibition of Flag Arguments
- Never pass boolean flags to functions:
  - BAD: `processOrder(order, isExpedited: true)`
  - BAD: `render(isModal: true)`
- A boolean argument is undeniable proof that the function is doing two things (one if true, another if false).
- Split into two distinct functions:
  - GOOD: `processExpeditedOrder(order)` and `processStandardOrder(order)`
  - GOOD: `renderModalView()` and `renderStandardView()`

### 3.5 Command-Query Separation (CQS)
- A method should either **change state** (command) or **return an answer** (query), but never both.
- Query methods must be idempotent and side-effect free.

### 3.6 Extract Error Handling
- Functions that handle errors (`try/catch` or Result matching) should do only that.
- Extract the try/catch logic into a dedicated wrapper function so business logic remains cleanly separated from fault recovery.

---

## 4. Flow Control & Guard Clauses

### 4.1 Return Early (Guard Clauses)
- Check invalid conditions, missing parameters, and edge cases immediately at the top of the function and return early.
- Keep the "happy path" unindented at the base level of the function:
  ```
  // BAD: Deeply nested ladder
  if (user != null) {
    if (user.isActive) {
      if (hasPermission) {
        process();
      }
    }
  }

  // GOOD: Clean guard clauses
  if (user == null || !user.isActive || !hasPermission) {
    return;
  }
  process();
  ```

### 4.2 Cyclomatic Complexity Limit
- Never nest control flow (`if`, `for`, `switch`) more than 2 levels deep. Extract nested blocks into discrete functions.

### 4.3 Zero Commented-Out Code
- Never leave commented-out code in the repository. Version control (git) preserves all historical iterations.

---

## 5. Strict Linter Compliance & Anti-Suppression Policy

Suppressing static analysis warnings or compiler errors using inline ignore directives is strictly forbidden across all languages. The code must be cleanly refactored to satisfy the compiler and static analyzer.

### 5.1 The Canonical Cross-Language Anti-Suppression Matrix

The only permitted exceptions are **scoped external API deprecations** during active framework upgrades and **automated machine-generated code headers**:

| Ecosystem | Banned Directives | Permitted Deprecation Exception | Permitted Code-Gen Exception | Toolchain Enforcer |
| :--- | :--- | :--- | :--- | :--- |
| **Dart / Flutter** | `// ignore:`, `// ignore_for_file:` | `// ignore: deprecated_member_use` | `// ignore: type=lint` | `dart analyze` / `flutter analyze` |
| **TypeScript / Web** | `/* eslint-disable */`, `// @ts-ignore`, `// biome-ignore` | `// eslint-disable-next-line @typescript-eslint/no-deprecated` | `/* eslint-disable */` *(in `*.g.ts` / `@generated` only)* | ESLint / Biome / `tsc` |
| **Python** | `# noqa`, `# type: ignore`, `# pylint: disable` | `# noqa: W1505`, `# noqa: B005`, `# type: ignore[deprecated]` | `# type: ignore` *(in `*_pb2.py` / `# Generated by` only)* | Ruff / Flake8 / Mypy / Pylint |
| **Go** | `//nolint`, `//lint:ignore` | `//lint:ignore SA1019 <reason>` | `// Code generated by ... DO NOT EDIT.` | `golangci-lint` / `staticcheck` |
| **Rust** | `#[allow(...)]`, `#![allow(...)]` | `#[allow(deprecated)]` | `#[allow(clippy::all)]` *(in macro/build outputs only)* | `cargo clippy` / `rustc` |
| **Kotlin / JVM** | `@Suppress(...)`, `@file:Suppress(...)` | `@Suppress("DEPRECATION")`, `DeprecatedCallableAddReplaceWith` | `@file:Suppress("UNCHECKED_CAST")` *(in `@Generated` only)* | `kotlinc` / Detekt / KtLint |
| **Swift / iOS** | `// swiftlint:disable` | `// swiftlint:disable:next deprecated`, `deprecated_call` | `// swiftlint:disable all` *(in `*.generated.swift` only)* | SwiftLint / `swiftc` |
| **C# / .NET** | `#pragma warning disable` | `#pragma warning disable CS0618`, `CS0612` | `<auto-generated />` / `[GeneratedCode]` | Roslyn Analyzers / `dotnet build` |
| **Universal** | Blanket inline suppression comments | Scoped external API deprecation directive | Machine-generated code header | POSIX Governance Engine |

> [!CAUTION]
> **Zero Blanket Suppressions**: Suppressions without specific rule codes (such as bare `# noqa`, blanket `/* eslint-disable */` on custom code, or unqualified `//nolint`) are completely rejected by OAEF Quality Gates.


## 6. Defensive Nullability & Typing

- Model missing data explicitly using idiomatic null-safety (e.g. `T?`, `Optional[T]`, `Option<T>`).
- Non-null assertion operators (`!`, `!!`, `.unwrap()`) are strictly forbidden in production business logic.

---

## 7. Non-Nullable Collections

A collection is almost never "absent": it is empty. Model that reality in the type, not with a `null` check at every call site.

### 7.1 The Constant-Empty Default

Any optional collection parameter, field or return value MUST default to a shared, immutable constant empty collection. The default is never a freshly allocated literal, and callers never have to null-check before iterating.

```text
// BAD: nullable collection forces a null check on every consumer
void render(List<Item>? items) { if (items != null) { ... } }

// GOOD: default to a shared constant empty collection
static const List<Item> noItems = <Item>[];
void render(List<Item> items = noItems) { ... }
```

### 7.2 The Optional-List Anti-Pattern

`null` is reserved for absence with business meaning. Using it to mean "no items were supplied" is the anti-pattern: it collapses two distinct concepts (absent vs empty) and leaks a branch into every caller. Only keep a nullable collection when the type system cannot express a non-null default, and then document the parameter as nil-safe.

### 7.3 Enforcement

| Check | Rule | Scope |
| :--- | :--- | :--- |
| `CC-08` | Nullable/optional collection in a public signature without a non-null constant-empty default. | blocking under `strict` |
| `CC-08` (degraded) | On stacks that cannot express a non-null collection default (Go, Rust), the rule degrades to the advisory "collection parameters must be documented as nil-safe". | report-only |

---

## 8. Service-Locator Confinement

Dependencies are declared, not discovered. A service locator hides the true dependency graph and makes a class untestable in isolation.

### 8.1 Constructor Injection First

- Production types receive their collaborators through the constructor (or the idiomatic equivalent: `required` named parameter, constructor parameter with default, factory parameter list).
- Injected fields are immutable and assigned exactly once.
- A class never reaches into a global registry mid-method to fetch a collaborator.

### 8.2 Allowed Resolution Roots

Global-container or service-locator resolution is permitted **only** at the composition root and the presentation layer. Everywhere else (domain, data, repositories, services) resolution is a violation.

| Layer | May resolve a global container? |
| :--- | :--- |
| Composition root (`main`, `di/`, `composition_root`, `Program.cs`, `AppDelegate`) | Yes |
| Presentation (screens, views, widgets, activity/view controllers) | Yes |
| Application service / use case | No - inject via constructor |
| Domain model | No |
| Data / repository / infrastructure adapter | No |

> Stacks without an idiomatic container (Go, Rust, `universal`) treat `CC-07` as a documented no-op; the constructor-injection rule in §8.1 still applies everywhere.

### 8.3 Enforcement

`CC-07` reports service-locator or global-container resolution outside the composition root and presentation layer: `prohibited service-locator resolution outside the composition root/presentation layer; inject via constructor`.

---

## 9. Mutable-Lazy-Init Prohibition

A field that is assigned on first use (`_client ??= ...`, `if (self.service is None): self.service = ...`) introduces hidden state, non-determinism and a race in concurrent code.

| Language family | Prohibited form (`CC-03`) |
| :--- | :--- |
| Dart / TypeScript / C# | `??=` against a `client`/`instance`/`service`/`provider` field |
| Python | `x = x or ...` and `if x is None: x = ...` against those fields |
| Others | no-op token family; the design rule still applies |

### 9.1 The Injection Refactor

Replace the lazy getter with a constructor parameter that is assigned once in the initializer. If construction cost must be deferred, defer it at the composition root (a factory or a provider registered there), never inside the consumer.

```text
// BAD: mutable lazy initialization
HttpClient? _client;
HttpClient get client => _client ??= HttpClient();

// GOOD: injected once, immutable
final HttpClient client;
Service({required this.client});
```

---

## 10. Silent-Exception Prohibition

An empty `catch`/`except`/`if err != nil` block is a defect, not defensive coding: it destroys the only evidence of the failure and lets the process continue in an invalid state.

### 10.1 The Disposal Matrix

Every caught error MUST be disposed of through exactly one of these paths:

| Disposition | When to use | Requirement |
| :--- | :--- | :--- |
| **Log with context** | The failure is expected, recoverable, and fully handled locally. | Structured log at ERROR with the error object and stack trace plus contextual fields. |
| **Rethrow** | The layer cannot meaningfully handle the failure. | Rethrow the same error, or wrap it (see below); never discard. |
| **Map to a domain error / result** | The caller must branch on the failure. | Return a typed domain error or a `Result`/`Either`; do not leak transport exceptions across a boundary. |

A block that consumes the error without logging, without rethrowing and without mapping it is a silent swallow.

### 10.2 Enforcement

`CC-06` reports silent exception swallowing: `prohibited silent exception swallowing; log with error+stack trace or rethrow`. Recognized log calls include any identifier containing `log`/`logger`/`Log`, or the platform logging API.

---

## 11. DRY Test Factories

Test data construction is repeated far more often than production logic; duplicated literals rot silently when a model gains a field.

### 11.1 Canonical Anatomy

- One factory per entity, named with the `make*` prefix (for example `makeSession`, `makeBooking`).
- Only the parameters that **vary per test** are exposed; every other field is a deterministic default.
- Defaults are constant and self-consistent: a factory with no arguments produces a valid, representative instance.

```text
Session makeSession({String id = 'session-1', bool isActive = true}) =>
    Session(id: id, isActive: isActive, startedAt: fixedStart, device: defaultDevice);
```

### 11.2 Anti-Pattern: Over-Parameterization

A factory mirroring every field of the entity is a constructor with extra steps: it forces each test to restate fields it does not care about. Expose a parameter only when at least one test varies it. **Dead parameters are deleted, not kept "for later"**: a parameter no test sets is removed from the factory signature in the same change.

---

## 12. Solution Abstraction Elevation (Rule of Two)

### 12.1 The Rule

When the same solution shape appears in **two or more** locations, it is elevated into a single shared abstraction: one helper, one module, one source of truth. The second occurrence is the trigger; there is no third copy.

### 12.2 The Single-Implementation Prohibition (Anti-Overengineering Razor)

The converse also holds: an interface, adapter or layer with a single implementation and no mock/substitution need is ceremonious indirection and MUST be collapsed into the concrete type until a genuine second implementation or test double exists. See §7 of the simplicity ladder in `AGENTS.md` and the Ponytail balance in `solid.md`.

---

## 13. Native / Multi-Platform Dependency Audit

Before adding a dependency that ships native code (a plugin wrapping a platform SDK, a C/C++ library, an FFI binding):

1. **Manifest audit** - it is added to the single platform manifest, pinned to an exact compatible range, with its transitive native dependencies inspected.
2. **Build-target proof** - the project still builds for every supported target (Debug, Profile and Release) without duplicate symbols or duplicated classes.
3. **Downstream host verification** - the dependency is verified in the downstream host repositories that embed this code, not only in the current workspace; a plugin that resolves here can still collide there.

A dependency whose transitive native footprint cannot be proven compatible in the downstream host repository is rejected, not "tried and fixed later".

---

## 14. Memory & Allocation Discipline (Lazy-Copy)

On hot paths (render loops, list transforms, serialization of large payloads) every avoidable copy is a latency and GC cost.

- **Inspect without copying**: read the field you need from the source instead of materializing a defensive copy.
- **Return the original reference** when nothing changed; do not allocate an equal-but-new collection or object.
- **Materialize once**: hoist a transform out of a loop; iterate the source lazily instead of building an intermediate list per iteration.
- Debug-only diagnostics (pretty-printed payloads, deep clones for logging) never run on the hot path.

`CC-11` reports avoidable allocation on a hot path as an advisory finding: `[advisory] avoidable allocation on hot path; inspect without copying and return the original reference`.

---

## 15. Cognitive Dispatch Gate (Phase 0)

Before planning or writing any code, the agent evaluates the request against the canonical dispatch matrix (`AGENTS.md` §3.3) and territorial scopes (§3.4), then:

1. Selects the primary skill and, where applicable, the meta-skill (`ponytail`).
2. **Reads each applicable `SKILL.md` first** from `.agents/skills/<skill>/SKILL.md`.
3. Declares the governing skills at the top of the response:

```text
> Governing Skills: [.agents/skills/ponytail/SKILL.md, .agents/skills/test-generator/SKILL.md]
```

Executing a task without consulting the governing skills is a level-1 contract violation (`AGENTS.md` §4.18). This in-repository gate is the bridge to harness-side activation: the same trigger keywords live in each skill's frontmatter `Triggers on:` list (audited by `SK-04`).

---

## 16. Skill Chaining Recipes

The five canonical recipes, copied verbatim from `AGENTS.md` §3.2:

```text
1. Feature / Screen Construction:
   ponytail -> screen-builder + responsive-layout -> ui-preview -> test-generator -> collect-coverage -> run-static-analysis -> code-review
2. Reusable Component / Module Authoring:
   ponytail -> component-author -> ui-preview -> responsive-layout -> test-generator -> run-static-analysis
3. Bug Fix / Root-Cause Remediation:
   ponytail (root-cause caller grep) -> fix-layout-issues (UI) / nullable-types (logic) -> test-generator -> run-static-analysis
4. Domain, Data & Infrastructure:
   ponytail -> nullable-types -> test-generator -> collect-coverage -> run-static-analysis
5. Pre-Submission / Pull Request Cycle:
   collect-coverage -> run-static-analysis -> code-review
```

`oaef skills route "<prompt>"` prints the recipe that contains the resolved primary skill, so the chain is discoverable without reading this document.

---

## 17. Platform Capability Table

Reach for the built-in capability before writing custom code. The right-hand column is the default answer for the left-hand need on each stack.

| what you think you need | what the platform delivers |
| :--- | :--- |
| **dart-flutter** - hand-written date formatting, manual JSON mapping, custom scroll pagination | `intl` `DateFormat`, `dart:convert` `jsonEncode`/`jsonDecode`, `ListView.builder` + `ScrollController` |
| **react-native** - custom date parser, manual key-value persistence, per-item list rendering | `Intl.DateTimeFormat`, `AsyncStorage`, `FlatList` windowing |
| **expo** - bespoke image resizing, hand-rolled secure storage | `expo-image-manipulator`, `expo-secure-store` |
| **typescript-web** - manual browser storage wrapper, hand-rolled fetch retry, date string juggling | `localStorage`/`IndexedDB`, `fetch` + `AbortController`, `Intl.DateTimeFormat` |
| **kotlin-multiplatform** - custom JSON codec, manual coroutine retry, date math | `kotlinx.serialization`, `kotlinx.coroutines` `retry`, `kotlinx-datetime` |
| **kotlin** - custom JSON codec, manual retry loop, date formatting | `kotlinx.serialization`, `Retry`/coroutine `retry`, `java.time` formatters |
| **python** - hand-parsed CLI flags, manual JSON encode/decode, custom date formatting | `argparse`, `json`, `datetime.strftime` |
| **go** - hand-rolled flag parsing, custom JSON codec, manual time formatting | `flag`, `encoding/json`, `time.Time.Format` |
| **rust** - manual error plumbing, hand-rolled CLI parsing, custom JSON codec | `Result` + `?`, `std::env::args` (or `clap`), `serde_json` |
| **swift** - custom date formatting, manual JSON parsing, bespoke image resizing | `DateFormatter`, `Codable`, `UIGraphicsImageRenderer` |
| **dotnet** - hand-written JSON mapping, custom date formatting, manual retry | `System.Text.Json`, `DateTime.ToString`, `HttpClient` message handlers (and `Polly` when installed) |
| **universal** - hand-parsed shell flags, manual JSON edits, custom date formatting | `getopts`, `jq`, `date` |

When the built-in genuinely does not fit, the deviation is recorded as a `// ponytail:` marker with its ceiling and evolution trigger (§8 of `governance_checks.md`), not silently hand-rolled.

<!-- /oaef:section:standard:coding_patterns -->
