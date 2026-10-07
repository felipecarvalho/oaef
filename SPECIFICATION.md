# Open Agentic Engineering Framework (OAEF) Specification
> **Specification Version:** 1.1.0  
> **Status:** Canonical Standard  
> **Author & Creator:** Felipe Carvalho  
> **License:** Apache License 2.0  
> **Date:** September 2026

---

## Abstract

This document defines the formal specification for the **Open Agentic Engineering Framework (OAEF)**. OAEF specifies a standardized architecture, context engineering model, behavioral contracts, and automated quality gates enabling autonomous artificial intelligence (AI) coding agents and human software engineers to collaborate reliably within a living repository without architectural drift or ungrounded assumptions.

---

## 1. Terminology & Conformance Notation

The key words **"MUST"**, **"MUST NOT"**, **"REQUIRED"**, **"SHALL"**, **"SHALL NOT"**, **"SHOULD"**, **"SHOULD NOT"**, **"RECOMMENDED"**, **"MAY"**, and **"OPTIONAL"** in this document are to be interpreted as described in BCP 14 [RFC 2119] [RFC 8174].

- **Living Repository**: A software repository containing its own machine-readable architecture, operational guidelines, executable contracts, and persistent inter-session memory.
- **Autonomous Agent**: An LLM-driven coding agent (e.g. Claude Code, Codex, OpenCode, Google Antigravity, Cursor, Windsurf, Copilot) capable of executing file modifications, terminal commands, or git commits.
- **Harness**: The runtime system around a model — execution loop, tool registration, sandboxing, context management, and recovery — that turns it into a working agent (e.g. Claude Code, Codex, OpenCode, Antigravity, Cursor). The verified compatibility matrix is maintained in `docs/HARNESSES.md`.
- **Inviolable Trust Hierarchy**: The deterministic priority ordering governing decision-making in the presence of conflicting information.
- **Monotonic Ratchet**: An algorithmic rule ensuring that repository quality thresholds (test coverage, branch coverage, linting) can only increase and NEVER decrease over time.
- **Zero-Pollution**: The invariant requiring consuming projects to contain strictly the files, skills, and runtimes applicable to their selected programming stack.

---

## 2. The Inviolable Trust Hierarchy

When an agent or engineer encounters conflicting information, ambiguity, or contradiction, the resolution MUST follow the strict hierarchy:

$$\mathbf{Compiler / Typechecker} > \mathbf{Automated Tests} > \mathbf{Source Code} > \mathbf{Wiki / Docs} > \mathbf{Ephemeral Memory} > \mathbf{LLM Hallucination}$$

1. **Compiler / Static Analyzer**: If the compiler or static typechecker rejects code, the code is definitively erroneous. Suppressions via `// ignore:` or language-equivalent linter directives MUST NOT be used, except for officially deprecated third-party member usage.
2. **Automated Tests**: Executable tests validate business contracts and regression guarantees. A failing test MUST supersede human or agent assumptions.
3. **Committed Source Code**: Executable implementation in the primary branch supersedes outdated prose documentation.
4. **Living Documentation & ADRs**: Architecture Decision Records and specifications represent design intent and architectural boundaries.
5. **Ephemeral Memory (`handoff.md`)**: Notes recorded in the session handoff file provide short-term context across session transitions.
6. **LLM Hallucination / Intuition**: Any assumption or deduction by an AI model not anchored in levels 1 through 5 is defined as void and MUST be discarded.

---

## 3. The 5 Pillars of OAEF

### Pillar 1: Context Engineering (Google OKF & Karpathy LLM Wiki)
1. **Metadata Frontmatter**: Key documentation nodes in `docs/` MUST include YAML frontmatter compliant with the Google Open Knowledge Format (OKF):
   ```yaml
   ---
   type: routing | architecture | standard | spec
   title: <Document Title>
   description: <Concise 1-2 sentence description>
   tags: [tag1, tag2]
   timestamp: <ISO-8601 UTC>
   ---
   ```
2. **Context Router (`docs/INDEX.md`)**: Repositories MUST maintain a task-based routing matrix. Agents MUST consult `docs/INDEX.md` prior to loading files into context, loading strictly the documents required for the immediate task.
3. **Open AI Discovery (`/llms.txt`)**: Repositories MUST maintain an `/llms.txt` file at the root providing semantic navigation for web and agent crawlers.

### Pillar 2: Spec-Driven Development (SDD)
1. **Executable Specifications**: New vertical features or user-facing behaviors MUST be specified via Gherkin `.feature` files under `docs/bdd/` before implementation.
2. **Design Boundaries**: Visual components MUST adhere to tokens defined in `docs/DESIGN.md`.
3. **Architecture Records**: Non-trivial architectural decisions or structural changes MUST be recorded as numbered Architecture Decision Records under `docs/adr/`.

### Pillar 3: Multidimensional Quality Gates
A compliant OAEF repository MUST maintain a machine-readable `docs/wiki/metrics/baseline.json`. Verification scripts MUST audit the following dimensions:
1. **Line Coverage**: Target `>= 95.0%` (Baseline minimum configurable via interview).
2. **Branch Coverage**: Target `>= 90.0%` (Baseline minimum configurable via interview).
3. **Clean Sizing Bounds**:
   - File length: Maximum 300 physical lines of code (LOC).
   - Method/Function length: Maximum 50 physical lines of code (LOC).
4. **Code Duplication**: Maximum 3.0% total duplication and zero identical fragments `>= 15` lines.
5. **Static Analysis & Suppressions**: Zero errors, zero warnings, and zero unallowed ignores.
6. **The Monotonic Ratchet Rule**: When test coverage increases in a session, running the finish workflow with `--record` MUST update `baseline.json` to lock in the new threshold. Future runs MUST NOT allow metrics to degrade below this new floor.

### Pillar 4: Zero-Docker Living Memory
1. **Session Handoff Ledger (`docs/wiki/memory/handoff.md`)**: At the end of every work session, the active agent or developer MUST update `handoff.md` with:
   - Accomplished tasks;
   - Architectural decisions made;
   - Remaining pending tasks;
   - Open contradictions or blockers.
2. **Append-Only History Log (`docs/wiki/log.md`)**: Major milestones MUST be appended to `docs/wiki/log.md` with ISO-8601 UTC timestamps.
3. **Secret & PII Guard**: Agents MUST NOT write API keys, access tokens, credentials, or personally identifiable information into living memory files. Governance tools MUST scan and block secret leaks.
4. **Zero-Daemon Tooling**: Governance audits and index synchronization MUST execute natively in the host language without requiring background containers or daemons.

### Pillar 5: Minimalism & Design Integrity (Simplicity Ladder + SOLID)
1. **The Simplicity Ladder (the Ponytail Ladder)**: Before writing code, agents and engineers MUST climb the ladder and stop at the first rung that solves the real problem:
   1. **YAGNI** — delete the requirement that does not exist yet.
   2. **Reuse in the codebase** — the pattern already exists; use it instead of a twin.
   3. **Language / standard-library primitive** — the platform already ships it.
   4. **Platform-native capability** — the OS, browser, runtime or framework already does it.
   5. **Already-installed dependency** — no new dependency for a solved problem.
   6. **One-line idiomatic expression** — the smallest expression that is still readable.
   7. **Smallest correct diff** — the change touches only what must change.

   The best code is the code that did not have to be written; there is zero tolerance for AI slop and speculative abstraction. A deliberate simplification is declared on the spot with a `// ponytail: <ceiling + evolution trigger>` marker (`PT-01`). Ceremonial layers (one-line pass-through use cases, single-implementation interfaces with no mock need, forwarding wrappers, narration comments) are banned, but the safety frontier — input validation, error routing, privacy/consent, accessibility and every Quality Gate — is never pruned.
2. **SOLID Principles**: Classes, modules, services and components MUST operate under **Single Responsibility** (one reason to change), **Open/Closed** (extend through composition, not by editing every caller), **Liskov Substitution** (every implementation fulfills the whole contract, with no `UnimplementedError`/`NotImplementedException`/`NotImplementedError`/`unimplemented!()`/`todo!()`/`panic("not implemented")` in a production implementation — `CC-09`), **Interface Segregation** (many small role interfaces beat one fat interface), and **Dependency Inversion** (high-level policy depends on abstractions it owns; concrete I/O lives at the edge). The full obligations are normative in `docs/standards/solid.md`.

---

## 4. Agent Autonomy & Contradiction Triage Protocol

### Autonomy Matrix
| Repository Area | Autonomy Level | Execution Requirement |
| :--- | :--- | :--- |
| **Feature & Business Code** | **Autonomous** | Must pass automated tests and Quality Gates. |
| **Test Creation & Refactoring**| **Autonomous** | Must adhere to TDD and branch coverage standards. |
| **Handoff & Log Append** | **Autonomous** | Must update after session completion; zero secret leaks. |
| **Architecture Decision Records**| **Restricted** | Requires explicit human review and approval. |
| **Baseline Threshold Lowering**| **Prohibited** | Baseline can only be raised, never lowered. |
| **Canonical Rule / Standard Elevation** | **Restricted** | Elevating a recurring review finding into a canonical rule/standard requires human approval. |
| **Rule Suppressions**| **Prohibited** | Zero tolerance (except scoped external deprecation migration & code-gen linter meta). |

### Canonical Rule Elevation
A recurring review finding MUST NOT be elevated into a canonical rule (a new `AGENTS.md` §4 invariant) or a canonical standard (`docs/standards/*`) autonomously. Elevation is **Restricted**: the agent MUST propose the rule change and wait for explicit human approval before writing it into the canonical contract. Once approved, the elevation is documented in the pull request that introduces it, and the affected governance engines and `docs/INDEX.md` are updated in the same change.

### Contradiction Triage Protocol
If an agent detects a discrepancy between documentation and code, or between two specifications:
1. The agent **MUST NOT** silently choose an interpretation.
2. The agent **MUST** record the contradiction in `docs/wiki/memory/handoff.md` under `## Active Contradictions`.
3. The agent **MUST** surface the conflict to the human user for explicit arbitration.

---

## 5. Multi-Tool Synchronization Invariant

To ensure seamless collaboration across different AI agent harnesses:
1. `AGENTS.md` is the canonical root rulebook, consumed natively by `AGENTS.md`-native harnesses (Codex, OpenCode, Antigravity, Cursor, Pi, Cline, Goose, and others).
2. `.agents/skills/` is the portable Agent Skills catalog, auto-discovered natively by harnesses such as Codex, OpenCode, Antigravity, Cursor, Windsurf, Goose, OpenHands, Cline, and Factory.
3. `CLAUDE.md` MUST remain in exact functional parity with `AGENTS.md`. Running `oaef sync` MUST regenerate the `CLAUDE.md` mirror for Claude Code.
4. Harnesses without native `AGENTS.md` support (e.g. Aider) MAY be pointed at it through their own configuration. The verified per-harness compatibility matrix is maintained in `docs/HARNESSES.md`.

---

## 6. Zero-Pollution Target Isolation Invariant

When OAEF is instantiated into a consuming repository:
1. The target repository MUST receive strictly the skills, architectural rules, and governance scripts of its selected tech stack.
2. Template directories, unused runtime scripts, and skills for unselected languages MUST NOT be copied into the target project.
3. Language-specific rules MUST be dynamically injected into `AGENTS.md` and `CLAUDE.md` at setup time.

---

## 7. Cross-Language Anti-Suppression Equivalence Specification

To enforce compiler inviolability across heterogeneous tech stacks, OAEF defines exact syntax mappings for permitted exceptions:

| Stack / Ecosystem | Permitted Deprecation Exception | Permitted Generated Code Exception |
| :--- | :--- | :--- |
| **Dart / Flutter** | `// ignore: deprecated_member_use` | `// ignore: type=lint` |
| **React Native** | `// eslint-disable-next-line @typescript-eslint/no-deprecated` | `/* eslint-disable */` (`*.g.tsx`, `codegen/`) |
| **Expo** | `// eslint-disable-next-line @typescript-eslint/no-deprecated` | `/* eslint-disable */` (`.expo/`, `@generated`) |
| **TypeScript / Web** | `// eslint-disable-next-line @typescript-eslint/no-deprecated` | `/* eslint-disable */` (`*.g.ts` / `@generated`) |
| **Kotlin Multiplatform (KMP)** | `@Suppress("DEPRECATION")`, `DeprecatedCallableAddReplaceWith` | `@file:Suppress("UNCHECKED_CAST")` (`build/generated/`, `@Generated`) |
| **Kotlin / Android** | `@Suppress("DEPRECATION")`, `DeprecatedCallableAddReplaceWith` | `@file:Suppress("UNCHECKED_CAST")` (`@Generated`) |
| **Python** | `# noqa: W1505`, `# noqa: B005`, `# type: ignore[deprecated]` | `# type: ignore` (`*_pb2.py` / `# Generated by`) |
| **Go** | `//lint:ignore SA1019 <reason>` | `// Code generated by ... DO NOT EDIT.` |
| **Rust** | `#[allow(deprecated)]` | `#[allow(clippy::all)]` (macro/build outputs) |
| **Swift / iOS** | `// swiftlint:disable:next deprecated`, `deprecated_call` | `// swiftlint:disable all` (`*.generated.swift`) |
| **C# / .NET** | `#pragma warning disable CS0618`, `CS0612` | `<auto-generated />` / `[GeneratedCode]` |
| **Universal** | Scoped external API deprecation directive | Machine-generated code header |

Blanket suppressions without specific rule tokens or error codes MUST trigger an immediate Quality Gate failure.

---

## 8. Cross-Language Governance Check Equivalence Specification

Every governance engine shipped by OAEF (one per supported stack) MUST realize the same check catalog with identical identifiers, identical canonical messages and the same output contract, so that a finding is byte-comparable across stacks. The normative source of this equivalence is `docs/standards/governance_checks.md`; when a runtime and this specification disagree, the catalog wins.

### 8.1 Output Contract

Every finding is printed on a single line, in this exact shape:

```
<CHECK-ID> <path>:<line> — <message>
```

- `<CHECK-ID>` — one of the identifiers in §8.2 (`CC-01` … `CC-11`, `SK-01` … `SK-06`, `PT-01`).
- `<path>` — repository-relative path, using `/` as separator on every platform.
- `<line>` — 1-based line number; `0` when the finding is not line-scoped (for example a missing skill directory).
- `— ` — em dash plus one space, then the canonical message from §8.4, verbatim.

Each suite closes with exactly one summary line:

```
Clean Code: <N> violation(s) (<profile> profile: <blocking|advisory>)
```

`<N>` counts every `CC-*` finding, blocking or advisory. The `<profile>` word is `strict`, `standard` or `legacy` and mirrors the effective profile. When no `CC-*` finding exists the summary is `Clean Code: 0 violation(s) (strict profile: blocking)`.

**Exclusion set.** The `CC-*` and `PT-01` suites scan production code only. A path is excluded when any of its segments is `.git`, `.github`, `.agents`, `.claude`, `.cursor`, `.windsurf`, `.cline`, `.grok`, `.oaef`, `node_modules`, `vendor`, `build`, `dist`, `target`, `obj`, `bin`, `tool`, `docs`, `templates`, `examples`, `coverage`, `generated`, `.venv`, `venv`, `__pycache__`, `.dart_tool`, `.gradle` or `.idea`; plus the file-name patterns `*.g.*`, `*_pb2.py`, `*_pb2_grpc.py`, `*.min.js`, `*.generated.*`, `*.freezed.*` and `*.designer.*`. A file is classified as a test file when any segment is `test`, `tests`, `__tests__`, `spec`, `specs`, `androidTest` or `iosTest`, or when its name matches `*_test.*`, `*.spec.*`, `*.test.*`, `test_*.py`, `*Tests.cs` or `*Test.kt`. Every `CC-*` check except `CC-11` skips test files; `CC-11` runs on both production and test files.

**Exit-code rule.** A suite exits `1` when it produces at least one **blocking** finding under the effective profile. `ponytail-debt` and `ponytail-audit` are report-only and exit `0` under every profile. In the `strict` profile the `CC-*` family is blocking; in `standard` and in every adoption mode it is advisory, except `CC-04` and `SK-05`, which are blocking under every profile. Every non-blocking finding MUST still be printed and labelled `[advisory]` inside its message where the canonical message carries that prefix.

### 8.2 Check Catalog (§3 of the catalog)

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
| `SK-06` | Routing self-test: the fixture table in §9.4 resolves exactly. | blocking |
| `PT-01` | `// ponytail:` debt-marker report: every marker with `file:line` and reason. | report-only |

\* `CC-08` is a documented no-op on stacks whose type system cannot express a non-null collection default (Go, Rust). In those stacks the rule degrades to the advisory “collection parameters must be documented as nil-safe”, which is never emitted mechanically.

### 8.3 Per-Stack Realization (§4 of the catalog)

Each engine translates the semantics of §8.2 into the native mechanisms below. Token lists are exhaustive for detection purposes; an engine MUST NOT invent additional tokens.

| Check | dart-flutter | typescript-web / expo / react-native | python | go | rust | kotlin / kotlin-multiplatform | swift | dotnet | universal |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `CC-01` | `(x) =>`, `.having((x) =>`, `catch (e)`, `final x =` / `var x =` (excludes `for (var i =`) | `(x) =>`, `catch (e)`, `const x =` / `let x =` | `lambda x:`, `except ... as x`, single-letter local assignment | closure `func(x T)`, `x :=` | `\|x\|`, `let x =` | `{ x ->`, `val x =` / `var x =` | `{ x in`, `let x =` / `var x =` | `(x) =>`, `catch (Exception x)`, `var x =` / `string x =` / `bool x =` | shell `local x=`; JS/TS tokens |
| `CC-02` | declaration/parameter regex over the token list | same | same | same | same | same | same | same | same |
| `CC-03` | `??=` over `_?client\|instance\|service\|provider` | `??=` over the same field names | `x = x or ...`, `if x is None: x = ...` over the same field names | `??=` over the same field names | no-op | `??=` over the same field names | no-op | `??=` over the same field names | `??=` over the same field names |
| `CC-04` | placeholder/secret assignment and identifier tokens | same | same | same | same | same | same | same | same |
| `CC-05` | `print(` | `console.log(`, `console.debug(`, `console.warn(` | `print(` | `fmt.Print`, `fmt.Println`, `fmt.Printf`, `println(` | `println!`, `print!`, `dbg!` | `println(` | `print(` | `Console.Write`, `Console.WriteLine`, `Debug.WriteLine`, `Console.Error.Write` | the union of the tokens above (polyglot tree) |
| `CC-06` | empty inline and multiline `catch (...) { }` | `catch (...) { }` | `except [^:]*: pass` and body-only `pass` | empty `if err != nil { }`, `_ = err`, empty `recover()` | discarded `.ok();`, `if let Err(_) = ... { }`, `Err(_) => { }` | `catch (...) { }` | empty `catch { }` | empty `catch { }` | the union of the handler shapes above (polyglot tree) |
| `CC-07` | `getIt<`, `GetIt.instance<`, `getIt(` — allowed only in `**/di/**`, `main.*`, `*_screen.*`, `*_view.*`, `*_widget.*`, `*_mixin.*`, `**/presentation/**`, `**/debug/**` | `container.get(`, `Container.get(`, `container.resolve(`, `getService(` — banned in `**/domain/**`, `**/data/**`, `**/services/**`, `**/repositories/**` | `injector.get(`, `container.resolve(`, `Container().resolve(` — allowed only in `main.py`, `**/di/**`, `**/composition_root*` | documented no-op | documented no-op | `inject<`, `KoinComponent`, `getKoin().get(`, `GlobalContext.get().get(` — allowed only in `**/di/**`, `*Module.kt`, `*Application*`, `*Activity*` | `Resolver.resolve(`, `DependencyContainer.shared`, `container.resolve(` — allowed only in `**/App*/**`, `*Assembly.swift`, `**/DI/**` | `serviceProvider.GetService<`, `GetRequiredService<`, `ServiceLocator.Get<` — allowed only in `Program.cs`, `Startup.cs`, `*CompositionRoot*` | documented no-op |
| `CC-08` | `(Map<...>?\|List<...>?\|Set<...>?)\s+\w+` (excludes `copyWith`) | parameter `\w+\??:\s*(Array\|ReadonlyArray\|Map\|Set\|\[\])` or a union with `\|undefined` | `Optional[List\|Dict\|Set]` and `list\|dict\|set[...] \| None` in a signature | no-op (documented nil-safe) | no-op (documented idiomatic `Option`) | `List<T>?` / `Map<K,V>?` / `Set<T>?` parameter | `[T]?` / `[K:V]?` / `Set<T>?` parameter | `List<T>?` / `IEnumerable<T>?` / `Dictionary<K,V>?` parameter | no-op |
| `CC-09` | `throw UnimplementedError(` | `throw new Error('Not implemented'` | `raise NotImplementedError` | `panic("not implemented"`, `panic("TODO"` | `unimplemented!()`, `todo!()` | `TODO(`, `throw NotImplementedError(` | `fatalError("TODO`, `preconditionFailure(` | `throw new NotImplementedException(` | the union of the placeholder tokens above (polyglot tree) |
| `CC-10` | `(new\s+)?(HttpClient\|Dio)\s*\(` | `axios.create(`, `new XMLHttpRequest(`, `new HttpClient(` | `requests.Session(`, `httpx.Client(`, `aiohttp.ClientSession(` | `http.Client{` (allowed only in the composition root) | `reqwest::Client::new(` | `OkHttpClient(`, `HttpClient(` | `URLSession.shared` (allowed only in the composition root) | `new HttpClient(` | no-op |
| `CC-11` | `List.from(`, `Map.from(`, `[...spread]` inside a loop body | `[...spread]`, `.map(...)` materialized inside a loop body | `list(...)`, `dict(...)`, `[...]` materialized inside a loop body | `append(` inside a loop body over an unbounded slice | `.clone()` inside a loop body | `.toList()` / `.toMutableList()` inside a loop body | `Array(` inside a loop body | `.ToList()` inside a loop body | no-op |

### 8.4 Canonical Messages (Verbatim, English)

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
PT-01 — ponytail debt marker: <path>:<line> — <reason>
```

---

## 9. Skill Activation & Harness Mirror Invariant

A skill is only useful when the harness actually activates it. OAEF therefore guarantees activation through four verifiable mechanisms: conformance with the Agent Skills specification, per-harness mirrors, dispatch-matrix coherence (`SK-04`) and the routing self-test (`SK-06`). The normative source is §6 and §7 of `docs/standards/governance_checks.md`.

### 9.1 Agent Skills Conformance

A canonical `SKILL.md` MUST satisfy:

1. The skill directory name equals the frontmatter `name`.
2. The frontmatter is the first YAML block of the file, delimited by `---` on its own line.
3. The allowed top-level frontmatter keys are exactly: `name`, `description`, `argument-hint`, `license`, `metadata`. Any other key is reported as `SK-02`.
4. `description` is written in the third person, starts with `Use when`, contains the literal markers `Triggers on:` and `Chains into:`, and has at least 150 characters of content after folding the YAML block scalar.
5. The body contains `## Territory` and `## Repository Conformance Gate`.

### 9.2 Harness Mirrors

Harnesses that discover skills in a private directory MUST be served a mirror of the canonical catalog:

| Harness | Mirror directory |
| :--- | :--- |
| Claude Code | `.claude/skills/` |
| Cursor | `.cursor/rules/` |
| Windsurf | `.windsurf/skills/` |
| Cline | `.cline/skills/` |
| Grok Build | `.grok/agents/` |

`oaef skills sync-mirrors` (alias `skills sync-mirrors`) creates a **relative symlink** to `.agents/skills/` when the platform supports it, and falls back to a recursive copy otherwise. `oaef skills sync-mirrors --check` validates parity without writing; `SK-05` is the audit form of the same rule. `.agents/skills/` is the canonical source: a divergent mirror entry is reported by `--check` and `SK-05`, and `oaef skills sync-mirrors` repairs it, printing every repair it performs. Only present mirror directories are audited; absent harness directories are not findings.

### 9.3 Dispatch-Matrix Coherence (`SK-04`)

The canonical dispatch matrix of `AGENTS.md` §3.3 is the bridge between in-repository dispatch and harness-side activation: every trigger keyword of the matrix MUST appear in the `Triggers on:` list of the matching skill frontmatter, and every catalog skill MUST have a row in the matrix. `oaef skills audit` parses the matrix and reports the first divergence as `SK-04` (blocking). This guarantees that the keyword that routes a prompt at runtime is the same keyword declared to the harness.

### 9.4 Routing Self-Test Fixture Table (`SK-06`)

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

### 9.5 Scoring Algorithm (Normative)

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

Reference implementation: the `skills-route` subcommand of the universal runtime, evaluated in a single process.
