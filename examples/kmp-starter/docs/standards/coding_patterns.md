# Coding Standards & Clean Code Craftsmanship

> Canonical code quality, clean architecture, and craftsmanship guide for `kmp-starter`.

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
  - ❌ `int d; // elapsed time in days` ➔ ✅ `int elapsedTimeInDays;`
  - ❌ `bool flag;` ➔ ✅ `bool isAccountActive;`

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
  - ❌ `ProductData`, `ProductInfo`, `ProductObject` ➔ ✅ `Product`
  - ❌ `CustomerRecord` ➔ ✅ `Customer`
- Do not encode data types into variable names (Hungarian notation):
  - ❌ `nameString`, `accountList`, `userMap` ➔ ✅ `name`, `accounts`, `usersByIdentifier`

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
  - ❌ `processOrder(order, isExpedited: true)`
  - ❌ `render(isModal: true)`
- A boolean argument is undeniable proof that the function is doing two things (one if true, another if false).
- Split into two distinct functions:
  - ✅ `processExpeditedOrder(order)` and `processStandardOrder(order)`
  - ✅ `renderModalView()` and `renderStandardView()`

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
  // ❌ Deeply nested ladder
  if (user != null) {
    if (user.isActive) {
      if (hasPermission) {
        process();
      }
    }
  }

  // ✅ Clean guard clauses
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
