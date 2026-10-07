<!-- oaef:section:standard:clean_code -->
# Clean Code & Design Integrity Standard

> The working reference for the mechanical clean-code barriers (`CC-01` … `CC-11`): naming, injection, nullability, resilience, allocation discipline and the anti-slop frontier. The law lives in `AGENTS.md` §4; this document explains each barrier and how to satisfy it.

---

## 1. Principles & Zero Tolerance

The compiler/typechecker and the automated tests are the ground truth. Clean-code debt is never inflation to be paid later: it is a defect of the change that introduced it. Every `CC-*` barrier is blocking under the `strict` profile and advisory under `standard` and under any adoption mode (`legacy`/`upgrade`), except `CC-04` (secret/placeholder) which blocks under every profile.

| Principle | Consequence |
| :--- | :--- |
| Compiler/typechecker > tests > source > docs > memory > intuition | No suppression may silence a barrier. |
| Zero silent debt | A violation is fixed where it is introduced, not deferred. |
| Simplest correct diff | The barrier is satisfied by design, not by a waiver. |

---

## 2. Meaningful Names (`CC-01`, `CC-02`)

An identifier states why it exists, what it does and how it is used. A name that needs a comment has failed.

| Banned token | Canonical replacement | Barrier |
| :--- | :--- | :--- |
| `cb` | `callback` | `CC-02` |
| `fn` | `function` (or the domain verb) | `CC-02` |
| `res`, `req` | `response`, `request` | `CC-02` |
| `btn`, `val` | `button`, `value` | `CC-02` |
| `tmp`, `cnt`, `idx` | `temporary...`, `count`, `index` | `CC-02` |
| `usr`, `mgr`, `buf`, `str`, `num`, `doc`, `elem`, `curr`, `prev`, `ctx`, `el` | `user`, `manager`, `buffer`, `text`, `amount`, `document`, `element`, `current`, `previous`, `context`, `element` | `CC-02` |

Single-letter identifiers are banned (`CC-01`). Only `i`/`j` inside an iteration block of five lines or fewer and the discard name `_` are allowed. Framework-mandated bindings (for example a `context` parameter required by a UI framework signature) are the only exception, and they keep their mandated name.

Dummy or placeholder keys (`dummy_`, `changeme`, `TODO_KEY`, `api_key = ""`, `secret = ""`, `password = "..."`) are a `CC-04` finding under every profile: secrets and tunables are sourced from configuration or the environment.

---

## 3. Immutability & Injection (`CC-03`)

Dependencies arrive through the constructor or the parameter list and are stored in a `final`/`readonly`/`val` field. A field that is assigned lazily on first use (`??=`, `x = x or ...`, `if x is None: x = ...`) is a `CC-03` finding: the wiring is invisible at the construction site and mutable after construction. There is no ambient lookup inside business logic; see §5.

---

## 4. Non-Nullable Collections (`CC-08`)

A public signature never accepts or returns a nullable collection without a non-null constant-empty default. An "optional list" is a design smell: it forces every caller to branch on absence that almost always means empty.

```pseudo
// anti-pattern: nullable collection parameter
processEvents(events: List<Event>?)        // every caller must null-check

// canonical: constant empty default
processEvents(events: List<Event> = emptyList)
```

On the stacks whose type system cannot express a non-null collection default (Go, Rust), `CC-08` is a documented no-op and the rule degrades to the advisory "collection parameters must be documented as nil-safe" at the declaration site.

---

## 5. Service-Locator Confinement (`CC-07`)

A service locator, global container or static registry is resolved **only** in the composition root and the presentation layer.

| Stack family | Allowed resolution roots |
| :--- | :--- |
| Dart/Flutter | `main.*`, `**/di/**`, screens/views/widgets/mixins, `**/presentation/**`, `**/debug/**` |
| TypeScript/React/Expo | composition root only; banned in `**/domain/**`, `**/data/**`, `**/services/**`, `**/repositories/**` |
| Python | `main.py`, `**/di/**`, `**/composition_root*` |
| Kotlin | `**/di/**`, `*Module.kt`, `*Application*`, `*Activity*` |
| Swift | `**/App*/**`, `*Assembly.swift`, `**/DI/**` |
| .NET | `Program.cs`, `Startup.cs`, `*CompositionRoot*` |

A leak looks like a repository, service or domain object resolving `container.get(...)` / `getIt<...>` / `inject<...>` / `ServiceLocator.Get<...>` mid-method. It blocks because the dependency graph becomes untraceable and untestable: the caller can no longer see what the unit needs.

---

## 6. Zero Silent Exception Swallowing (`CC-06`)

An empty `catch`/`except`/`if err != nil` block, with neither a log call nor a rethrow, is a defect. The disposition is one of:

1. **Log** with structured context plus error and stack trace, then continue or propagate.
2. **Rethrow** the error unchanged.
3. **Wrap and route** into a domain error or result type.

Recognized log calls are any identifier containing `log`/`logger`/`Log`, or the platform logging API (`os_log`, `NSLog`, `Console.`, `fmt.` with a severity verb, `tracing::`, `log::`). A handler whose body is only a comment counts as empty.

---

## 7. Memory & GC Discipline (Lazy-Copy) (`CC-11`)

On a hot path, allocate nothing that can be avoided:

* **Inspect without copying** — iterate, filter and query the original structure instead of materializing an intermediate collection inside a loop.
* **Return the original reference when nothing changes** — a transformation that produces an equal result returns the input, not a new equal instance.
* **No discarded intermediates** — a collection built and consumed in the same loop iteration is replaced by direct traversal.

`CC-11` is advisory in every profile: the reviewer decides what "hot path" means for the stack, and the rule is evaluated on both production and test files.

---

## 8. Anti-AI-Slop & the Ponytail Ladder

Before writing code, climb the seven rungs and stop at the first that solves the real problem:

1. **YAGNI** — delete the requirement that does not exist yet.
2. **Reuse in the codebase** — the pattern already exists.
3. **Language / standard-library primitive** — the platform ships it.
4. **Platform-native capability** — the OS, browser, runtime or framework does it.
5. **Already-installed dependency** — no new dependency for a solved problem.
6. **One-line idiomatic expression** — the smallest readable expression.
7. **Smallest correct diff** — only what must change changes.

**Banned ceremonies**: a one-line pass-through use case, a single-implementation interface with no mock need, a wrapper that only forwards arguments, and narration comments that restate the next line.

**Debt markers**: a deliberate simplification is declared on the spot with the grammar `// ponytail: <ceiling + evolution trigger>`, audited report-only by `PT-01`.

**Remediation tags** used by `code-review` and `oaef ponytail audit`: `[DELETE]` dead weight, `[STDLIB]` replace custom code with a primitive, `[NATIVE]` platform capability, `[YAGNI]` speculative feature, `[SHRINK]` shrink a multi-line construct to one line.

**Safety frontier — never pruned**: input validation, error routing, privacy/consent, accessibility and every Quality Gate stay. Simplicity never licenses an unsafe shortcut.

---

## 9. Two-Layer Resilience

1. **Infrastructure layer** — catch the failure, log it with structured context plus error and stack trace, then propagate it or wrap it into a domain error/result.
2. **Coordination layer** — add the defensive barrier that protects the caller: timeout, retry policy, circuit breaker, and per-provider/dependency failure isolation so one failing dependency never aborts the whole operation.

---

## 10. Automated Enforcement

| Check | Semantics | Strict profile | Reported by |
| :--- | :--- | :--- | :--- |
| `CC-01` | Single-letter identifier outside a tiny loop or `_`. | blocking | `oaef clean-code` |
| `CC-02` | Cryptic abbreviation used as an identifier. | blocking | `oaef clean-code` |
| `CC-03` | Mutable lazy initialization. | blocking | `oaef clean-code` |
| `CC-04` | Hardcoded placeholder/secret key. | blocking (all profiles) | `oaef clean-code` |
| `CC-05` | Raw print/debug output in production code. | blocking | `oaef clean-code` |
| `CC-06` | Silent exception swallowing. | blocking | `oaef clean-code` |
| `CC-07` | Service-locator resolution outside the composition root. | blocking | `oaef clean-code` |
| `CC-08` | Nullable collection parameter without a constant-empty default. | blocking (no-op on Go/Rust) | `oaef clean-code` |
| `CC-09` | Unimplemented placeholder in a production contract (LSP). | blocking | `oaef clean-code`, `oaef lint` |
| `CC-10` | Concrete network-client instantiation outside the composition root (DIP). | blocking | `oaef clean-code` |
| `CC-11` | Avoidable allocation on a hot path. | advisory | `oaef clean-code` |

Identifiers, tokens and canonical messages are specified in [`governance_checks.md`](governance_checks.md).

<!-- /oaef:section:standard:clean_code -->
