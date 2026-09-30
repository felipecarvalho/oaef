# Coding Standards & Clean Sizing Guidelines

> Canonical code quality and architecture guide for `typescript-starter`.

---

## 1. Clean Sizing Limits

To minimize cognitive load and cyclomatic complexity:

| Scope | Physical Line Limit | Target Clean Code | Action if Exceeded |
| :--- | :--- | :--- | :--- |
| **Files** | **<= 300 LOC** | **<= 200 LOC** | Decompose into smaller focused modules/widgets. |
| **Methods / Functions** | **<= 50 LOC** | **<= 30 LOC** | Extract helper routines, guard clauses, or delegates. |

*Files exceeding 300 lines or functions exceeding 50 lines are rejected by the automated Quality Gate.*

---

## 2. Prohibition of Helper Build Functions in UI
- **Never create helper rendering functions** (such as `_buildHeader()` or `renderItems()`).
- Always extract separate visual widgets/components into their own files as dedicated components.
- This unlocks granular re-rendering optimizations and keeps method bodies compact.

---

## 3. Strict Linter Compliance (Zero Suppressions)
- Suppressing linter warnings using inline ignore comments (`// ignore:`, `/* eslint-disable */`, `# noqa`) is **strictly forbidden**.
- The code must be cleanly refactored to satisfy the compiler and static analyzer.
- The only permitted exception is when consuming deprecated third-party library members during transitional upgrades.

---

## 4. Defensive Nullability & Typing
- Model missing data explicitly using idiomatic null-safety (e.g. `T?`, `Optional[T]`, `Option<T>`).
- Use early guard clauses and pattern matching to handle null/empty states at function entrypoints.
- Avoid deep conditional nesting.
