<!-- oaef:section:standard:governance_checks -->
# Cross-Language Governance Checks (Normative Catalog)

> **Normative source of truth** for every mechanical barrier shipped with OAEF: the `CC-*` clean-code checks, the `SK-*` skill-activation invariants and the `PT-01` simplicity-debt report. Every governance engine in `tool/` (12 language realizations) MUST implement this catalog with the canonical messages and the canonical output contract defined here. When a runtime and this document disagree, this document wins.

---

## 1. Output Contract

Every finding is printed on a single line, in this exact shape:

```
<CHECK-ID> <path>:<line> — <message>
```

- `<CHECK-ID>` — one of the identifiers in §3 (`CC-01` … `CC-11`, `SK-01` … `SK-06`, `PT-01`).
- `<path>` — repository-relative path, using `/` as separator on every platform.
- `<line>` — 1-based line number; `0` when the finding is not line-scoped (for example a missing skill directory).
- `— ` — em dash plus one space, then the canonical message from §5, verbatim.

Each suite closes with exactly one summary line:

```
Clean Code: <N> violation(s) (strict profile: blocking)
```

`<N>` counts every `CC-*` finding, blocking or advisory. The profile word is `strict`, `standard` or `legacy` and mirrors the effective profile (§9). When no `CC-*` finding exists the summary is `Clean Code: 0 violation(s) (strict profile: blocking)`.

### 1.1 Exit codes

| Suite | Exit `1` when |
| :--- | :--- |
| `clean-code` (alias `governance-check`) | At least one **blocking** `CC-*` finding under the effective profile. |
| `lint` | Mirror parity failure, secret finding, unallowed suppression, or any blocking `SK-*` finding. |
| `skills-audit [--selftest]` | Any blocking `SK-*` finding (`--selftest` adds `SK-06`). |
| `ponytail-debt`, `ponytail-audit` | Never. Both are report-only (`PT-01`). |
| `quality-gate` / `audit` | Tests fail, coverage or sizing floors are missed, or the effective profile is `strict` and the `CC-*` blocking count is greater than `0`. |
| `doctor` / `conform` | Any structural, skill, standard or self-test prerequisite fails. |

Every non-blocking finding MUST still be printed and MUST be labelled `[advisory]` inside its message when the canonical message carries that prefix (§5).

---

## 2. Production Scopes & Exclusions

`CC-*` and `PT-01` scan **production code only**. Test trees, tooling, documentation and generated code are never scanned.

### 2.1 Production scope per stack

| Stack | Scanned roots |
| :--- | :--- |
| `dart-flutter` | `lib/` |
| `typescript-web` | `src/` |
| `react-native` | `src/`, `app/` |
| `expo` | `src/`, `app/` |
| `python` | repository root (recursive), excluding the directories in §2.2 |
| `go` | repository root (recursive), `*.go` only, excluding the directories in §2.2 |
| `rust` | `src/` |
| `kotlin`, `kotlin-multiplatform` | `src/main/`, `src/commonMain/`, `src/androidMain/`, `src/iosMain/` |
| `swift` | `Sources/`, `Source/`, plus root-level `*.swift` |
| `dotnet` | repository root (recursive), `*.cs` only, excluding the directories in §2.2 |
| `universal` (shell engine) | repository root (recursive), over the extension set in §2.3, excluding the directories in §2.2 |

### 2.2 Universal exclusion set

A path is excluded when any of its segments matches, case-sensitively:

`.git`, `.github`, `.agents`, `.claude`, `.cursor`, `.windsurf`, `.cline`, `.grok`, `.oaef`, `node_modules`, `vendor`, `build`, `dist`, `target`, `obj`, `bin`, `tool`, `docs`, `templates`, `examples`, `coverage`, `generated`, `.venv`, `venv`, `__pycache__`, `.dart_tool`, `.gradle`, `.idea`

Plus the file-name patterns: `*.g.*`, `*_pb2.py`, `*_pb2_grpc.py`, `*.min.js`, `*.generated.*`, `*.freezed.*`, `*.designer.*`.

A file is additionally classified as a **test file** when any of its path segments is `test`, `tests`, `__tests__`, `spec`, `specs`, `androidTest` or `iosTest`, or when its name matches `*_test.*`, `*.spec.*`, `*.test.*`, `test_*.py`, `*Tests.cs` or `*Test.kt`. Every `CC-*` check except `CC-11` skips test files; `CC-11` is evaluated on both production and test files because allocation discipline is measured where the code runs.

### 2.3 Extension set for the shell engine

`.dart`, `.ts`, `.tsx`, `.js`, `.mjs`, `.cjs`, `.jsx`, `.py`, `.go`, `.rs`, `.kt`, `.kts`, `.swift`, `.cs`, `.sh`, `.bash`

---

## 3. Check Catalog

| ID | Semantics | Strict profile |
| :--- | :--- | :--- |
| `CC-01` | Single-letter identifiers in closures/lambdas, `catch`/`except` bindings and local declarations. Allowed: `i`/`j` inside the body of a block of 5 lines or fewer; discard `_`. | blocking |
| `CC-02` | Cryptic abbreviations used as identifiers: `cb`, `fn`, `res`, `req`, `btn`, `val`, `tmp`, `ctx`, `el`, `usr`, `mgr`, `idx`, `cnt`, `buf`, `str`, `num`, `doc`, `elem`, `curr`, `prev`. | blocking |
| `CC-03` | Mutable lazy initialization (late assignment to a client/service/instance/provider field). | blocking |
| `CC-04` | Hardcoded placeholder or secret keys (`dummy_`, `changeme`, `TODO_KEY`, `api_key = ""`, `secret = ""`, `password = "..."`). | blocking (all profiles) |
| `CC-05` | Raw print/debug output in production directories. | blocking |
| `CC-06` | Silent exception swallowing: an empty `catch`/`except`/`if err != nil` block with neither a log call nor a rethrow. | blocking |
| `CC-07` | Service-locator or global-container resolution outside the composition root and the presentation layer. | blocking |
| `CC-08` | Nullable/optional collection in a public signature without a non-null constant-empty default. | blocking\* |
| `CC-09` | Unimplemented placeholder in production code (LSP violation). | blocking |
| `CC-10` | Concrete network-client instantiation outside the composition root/presentation layer (DIP violation). | blocking |
| `CC-11` | Avoidable allocation on a hot path. | advisory |
| `SK-01` | Skill parity: the catalog count is declared and every canonical skill is present and listed by `AGENTS.md`, `llms.txt` (and `README.md` when present). | blocking |
| `SK-02` | Frontmatter quality: `Use when`, `Triggers on:` and `Chains into:` present, description density ≥ 150 characters, `name` equal to the directory name, no unknown frontmatter key. | blocking |
| `SK-03` | Entrypoint parity: `llms.txt` lists every skill; `README.md` (when present), `docs/INDEX.md` and `docs/MANIFESTO.md` reference `llms.txt`. | blocking |
| `SK-04` | Trigger coherence: every dispatch-matrix trigger keyword appears in the matching skill frontmatter; every catalog skill has a matrix row. | blocking |
| `SK-05` | Harness mirror parity: for every present harness skills directory, each canonical skill exists with identical content (byte comparison). | blocking (all profiles) |
| `SK-06` | Routing self-test: the fixture table in §7 resolves exactly. | blocking |
| `PT-01` | `// ponytail:` debt-marker report: every marker with `file:line` and reason. | report-only |

\* `CC-08` is a documented no-op on stacks whose type system cannot express a non-null collection default (Go, Rust). In those stacks the rule degrades to the advisory “collection parameters must be documented as nil-safe”, which is never emitted mechanically.

---

## 4. Per-Stack Realization (Normative Tokens)

Each engine translates the semantics of §3 into the native mechanisms below. Token lists are exhaustive for detection purposes; an engine MUST NOT invent additional tokens.

| Check | dart-flutter | typescript-web / expo / react-native | python | go | rust | kotlin / kotlin-multiplatform | swift | dotnet | universal |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `CC-01` | `(x) =>`, `.having((x) =>`, `catch (e)`, `final x =` / `var x =` (excludes `for (var i =`) | `(x) =>`, `catch (e)`, `const x =` / `let x =` | `lambda x:`, `except ... as x`, single-letter local assignment | closure `func(x T)`, `x :=` | `\|x\|`, `let x =` | `{ x ->`, `val x =` / `var x =` | `{ x in`, `let x =` / `var x =` | `(x) =>`, `catch (Exception x)`, `var x =` / `string x =` / `bool x =` | shell `local x=`; JS/TS tokens |
| `CC-02` | declaration/parameter regex over the token list | same | same | same | same | same | same | same | same |
| `CC-03` | `??=` over `_?client\|instance\|service\| no-op | `??=` over the same field names | no-op | `??=` over the same field names | no-op | `??=` over the same field names | no-op | `??=` over the same field names | `??=` over the same field names |
| `CC-04` | placeholder/secret assignment and identifier tokens | same | same | same | same | same | same | same | same |
| `CC-05` | `print(` | `console.log(`, `console.debug(`, `console.warn(` | `print(` | `fmt.Print`, `fmt.Println`, `fmt.Printf`, `println(` | `println!`, `print!`, `dbg!` | `println(` | `print(` | `Console.Write`, `Console.WriteLine`, `Debug.WriteLine`, `Console.Error.Write` | the union of the tokens above (polyglot tree) |
| `CC-06` | empty inline and multiline `catch (...) { }` | `catch (...) { }` | `except [^:]*: pass` and body-only `pass` | empty `if err != nil { }`, `_ = err`, empty `recover()` | discarded `.ok();`, `if let Err(_) = ... { }`, `Err(_) => { }` | `catch (...) { }` | empty `catch { }` | empty `catch { }` | the union of the handler shapes above (polyglot tree) |
| `CC-07` | `getIt<`, `GetIt.instance<`, `getIt(` — allowed only in `**/di/**`, `main.*`, `*_screen.*`, `*_view.*`, `*_widget.*`, `*_mixin.*`, `**/presentation/**`, `**/debug/**` | `container.get(`, `Container.get(`, `container.resolve(`, `getService(` — banned in `**/domain/**`, `**/data/**`, `**/services/**`, `**/repositories/**` | `injector.get(`, `container.resolve(`, `Container().resolve(` — allowed only in `main.py`, `**/di/**`, `**/composition_root*` | documented no-op | documented no-op | `inject<`, `KoinComponent`, `getKoin().get(`, `GlobalContext.get().get(` — allowed only in `**/di/**`, `*Module.kt`, `*Application*`, `*Activity*` | `Resolver.resolve(`, `DependencyContainer.shared`, `container.resolve(` — allowed only in `**/App*/**`, `*Assembly.swift`, `**/DI/**` | `serviceProvider.GetService<`, `GetRequiredService<`, `ServiceLocator.Get<` — allowed only in `Program.cs`, `Startup.cs`, `*CompositionRoot*` | documented no-op |
| `CC-08` | `(Map<...>?\|List<...>?\|Set<...>?)\s+\w+` (excludes `copyWith`) | parameter `\w+\??:\s*(Array\|ReadonlyArray\|Map\|Set\|\[\])` or a union with `\|undefined` | `Optional[List\|Dict\|Set]` and `list\|dict\|set[...] \| None` in a signature | no-op (documented nil-safe) | no-op (documented idiomatic `Option`) | `List<T>?` / `Map<K,V>?` / `Set<T>?` parameter | `[T]?` / `[K:V]?` / `Set<T>?` parameter | `List<T>?` / `IEnumerable<T>?` / `Dictionary<K,V>?` parameter | no-op |
| `CC-09` | `throw UnimplementedError(` | `throw new Error('Not implemented'` | `raise NotImplementedError` | `panic("not implemented"`, `panic("TODO"` | `unimplemented!()`, `todo!()` | `TODO(`, `throw NotImplementedError(` | `fatalError("TODO`, `preconditionFailure(` | `throw new NotImplementedException(` | the union of the placeholder tokens above (polyglot tree) |
| `CC-10` | `(new\s+)?(HttpClient\|Dio)\s*\(` | `axios.create(`, `new XMLHttpRequest(`, `new HttpClient(` | `requests.Session(`, `httpx.Client(`, `aiohttp.ClientSession(` | `http.Client{` (allowed only in the composition root) | `reqwest::Client::new(` | `OkHttpClient(`, `HttpClient(` | `URLSession.shared` (allowed only in the composition root) | `new HttpClient(` | no-op |
| `CC-11` | `List.from(`, `Map.from(`, `[...spread]` inside a loop body | `[...spread]`, `.map(...)` materialized inside a loop body | `list(...)`, `dict(...)`, `[...]` materialized inside a loop body | `append(` inside a loop body over an unbounded slice | `.clone()` inside a loop body | `.toList()` / `.toMutableList()` inside a loop body | `Array(` inside a loop body | `.ToList()` inside a loop body | no-op |

### 4.1 Shared detection rules

1. **`CC-01` / `CC-02`** are identifier-scoped: an engine parses the line for *declaration* or *binding* sites only (`=`, closure/lambda parameter lists, `catch`/`except` bindings, `for` bindings of the language in use). Mentioning a forbidden token inside a string literal, a comment, or a member access (`response.body`) is not a finding.
2. **Loop-counter allowance**: `i` and `j` are accepted only in loop bindings (a `for` construct on the same line, whichever loop syntax the language uses: `for (var i =`, `for i in`, `for i :=`, `|i|`), and `_` is always accepted as a discard name. Any other single-letter binding is a finding.
3. **`CC-05` raw output** is matched on the *call* form, not on a method reference passed as a value.
4. **`CC-06` empty handler**: a handler body counts as empty when it contains at most a comment and no log call, no rethrow and no error routing. Recognized log calls: any identifier containing `log`, `logger`, `Log`, or the platform logging API (`os_log`, `NSLog`, `Console.`, `fmt.` + severity verb, `tracing::`, `log::`).
5. **`CC-09`** never fires inside the `tool/` directory, in documentation, or in a method whose next statement rethrows (a documented partial implementation is still a violation: implement the contract).
6. **`CC-10`** allows the composition root of each stack: `main.*`, `**/di/**`, `**/composition_root*`, `Program.cs`, `Startup.cs`, `*Application*`, `AppDelegate.swift`, `main.dart`.
7. Every regex MUST be applied line by line, except `CC-06` which inspects a handler body spanning consecutive lines.

---

## 5. Canonical Messages (Verbatim, English)

```
CC-01 — prohibited single-letter identifier "<name>"; use a descriptive name
CC-02 — prohibited cryptic abbreviation "<name>"; use the full identifier
CC-03 — prohibited mutable lazy initialization; inject the dependency via constructor
CC-04 — prohibited hardcoded placeholder/secret; source it from configuration/environment
CC-05 — prohibited raw print/debug output in production code; use the logging interface
CC-06 — prohibited silent exception swallowing; log with error+stack trace or rethrow
CC-07 — prohibited service-locator resolution outside the composition root/presentation layer; inject via constructor
CC-08 — prohibited nullable collection parameter; default to a constant empty collection
CC-09 — prohibited unimplemented placeholder in production contract; implement the contract (LSP)
CC-10 — prohibited concrete network-client instantiation outside the composition root; depend on an abstraction (DIP)
CC-11 — [advisory] avoidable allocation on hot path; inspect without copying and return the original reference
SK-01 — skill "<name>" is not listed in <README.md|AGENTS.md|llms.txt> (parity required)
SK-02 — skill "<name>" frontmatter must declare "Use when", "Triggers on:" and "Chains into:" with >=150 characters and name==directory
SK-03 — skill "<name>" is not listed in llms.txt / entrypoint <file> does not reference llms.txt
SK-04 — trigger "<keyword>" for skill "<name>" is missing from its frontmatter "Triggers on:" / skill "<name>" has no dispatch-matrix row
SK-05 — harness mirror "<dir>" diverges from .agents/skills for skill "<name>" (run: oaef skills sync-mirrors)
SK-06 — routing self-test failed: prompt "<prompt>" resolved to "<got>" but expected "<expected>"
PT-01 — ponytail debt marker (emitted as: PT-01 <path>:<line> — <reason>)
```

`CC-04` is blocking under every profile. `SK-05` is blocking under every profile. Everything else in the `CC-*` family is blocking under `strict` and advisory under `standard` and under any adoption mode (§9).

---

## 6. Skill Activation Invariants

### 6.1 Conformance with the Agent Skills specification

1. The skill directory name equals the frontmatter `name`.
2. The frontmatter is the first YAML block of the file, delimited by `---` on its own line.
3. The allowed top-level frontmatter keys are exactly: `name`, `description`, `argument-hint`, `license`, `metadata`. Any other key is reported as `SK-02`.
4. `description` is written in the third person, starts with `Use when`, contains the literal markers `Triggers on:` and `Chains into:`, and has at least 150 characters of content after folding the YAML block scalar.
5. The body contains `## Territory` and `## Repository Conformance Gate`.

### 6.2 Harness mirrors

Harnesses that discover skills in a private directory MUST be served a mirror of the canonical catalog:

| Harness | Mirror directory |
| :--- | :--- |
| Claude Code | `.claude/skills/` |
| Cursor | `.cursor/rules/` |
| Windsurf | `.windsurf/skills/` |
| Cline | `.cline/skills/` |
| Grok Build | `.grok/agents/` |

- `oaef skills sync-mirrors` (alias `skills sync-mirrors`) creates a **relative symlink** to `.agents/skills/` when the platform supports it, and falls back to a recursive copy otherwise.
- `oaef skills sync-mirrors --check` validates parity without writing. `SK-05` is the audit form of the same rule.
- `.agents/skills/` is the canonical source: a divergent mirror entry is reported by `--check` and `SK-05`, and `oaef skills sync-mirrors` repairs it, printing every repair it performs. Nothing user-authored is lost, because a mirror is by definition derived.
- Only present mirror directories are audited. Absent harness directories are not findings.

---

## 7. Routing Self-Test Fixture Table

`oaef skills route "<prompt>"` MUST resolve each prompt below to the expected primary skill. `oaef skills audit --selftest` fails with `SK-06` when any pair diverges.

| Prompt | Expected skill |
| :--- | :--- |
| `create a new screen for the booking flow` | `screen-builder` |
| `build a reusable button component` | `component-author` |
| `the layout overflows on small screens` | `fix-layout-issues` |
| `add responsive breakpoints for tablet` | `responsive-layout` |
| `write unit tests for the payment service` | `test-generator` |
| `collect coverage and check the branch floor` | `collect-coverage` |
| `fix all analyzer warnings` | `run-static-analysis` |
| `this optional list parameter is always null` | `nullable-types` |
| `audit module boundaries and cyclic imports` | `architecture-audit` |
| `verify the repo conforms to the framework` | `conformance-audit` |
| `review my PR before I open it` | `code-review` |
| `remove the dead code and the 1-line use case` | `ponytail` |

### 7.1 Scoring algorithm (normative)

The router is deterministic and identical in all engines:

1. Normalize the prompt to lowercase. Tokenize on every character that is not `a-z`, `0-9` or `-`.
2. Build the **candidate forms** of a token: the token itself, plus the token with a trailing `ies`→`y`, `es`, `s`, `ing`, `ed` or `ion` removed.
3. A **match** between a token form and a canonical word holds when they are equal, or when their common prefix is at least 4 characters long. Words shorter than 4 characters match only by equality.
4. Score each of the 13 skills, in dispatch-matrix order:
   * `5` points per matched **name word** (the skill name split on `-`).
   * `3 + min(length(trigger), 8)` points per matched **trigger term**: a multi-word term matches when the prompt contains it as a substring; a single word matches through rule 3. The extra term length is the specificity weight — a precise trigger such as `overflow` outranks a generic one such as `screen`.
   * `1` point per prompt token that appears in the territory vocabulary (`features`, `screens`, `pages`, `components`, `shared`, `ui`, `core`, `domain`, `data`, `infra`, `test`, `tests`).
5. The highest score wins; on a tie the earlier matrix row wins. When every score is `0` the router resolves `ponytail` (the default meta-skill).
6. The router always also reports the skill's meta-skill and every recipe of `AGENTS.md` §3.2 that contains the resolved primary skill.

Reference implementation: `tool/governance.sh skills-route "<prompt>"` in the universal runtime, evaluated in a single process.

---

## 8. Simplicity Debt Markers (`PT-01`)

A `// ponytail:` marker declares the ceiling of a deliberate simplification together with the trigger that must reopen the decision:

```text
// ponytail: in-memory cache, move to persistent storage once writes exceed 10k/day
```

The canonical grammar is `ponytail: <ceiling + evolution trigger>`, introduced by the platform comment syntax (`//`, `#`, `--`, `/*`, `///`, `<!--`). Markers are never blocking: `PT-01` lists them, and `oaef ponytail debt` prints that list.

`oaef ponytail audit` extends the report with an advisory anti-slop sweep, printed as `[advisory] [TAG] <path>:<line> — <reason>` where `TAG` is one of the §4.7 remediation tags (`[DELETE]`, `[STDLIB]`, `[NATIVE]`, `[YAGNI]`, `[SHRINK]`). It exits `0` under every profile.

---

## 9. Profile & Adoption Degradation

| Effective profile | `CC-*` behavior | Exceptions |
| :--- | :--- | :--- |
| `strict` | blocking when the count exceeds the matching `baseline.clean_code.max_*` | none |
| `standard` | advisory; the summary line still reports the counts | `CC-04`, `CC-11` stay as declared (`CC-04` blocking, `CC-11` advisory) |
| `legacy` / `upgrade` (adoption) | advisory; counts are recorded in the Adoption Debt Ledger | `CC-04` blocking, `SK-05` blocking |

The effective profile is read from `oaef.context.json` (`strictness`, then `adoption_mode`) and falls back to `baseline.json` (`profile`), then to `strict`.

In an adoption mode (`adoption_mode` = `legacy` or `upgrade`), the skills declared in `docs/wiki/metrics/adoption.json` under `user_skills` are user-owned: `SK-02` and `SK-04` findings for those skills are advisory. Every other `SK-*` invariant keeps its declared severity.
<!-- /oaef:section:standard:governance_checks -->
