### Stack-Specific Architectural Rules (Universal / Polyglot)

1. **Strict Anti-Suppression Policy**:
   - Suppressing compiler, linter, or static analyzer warnings via inline suppression comments is strictly forbidden.
   - **Permitted Scoped Deprecation Exception**: Scoped suppressions targeting specific external third-party API deprecations are permitted solely during active library migration (e.g. `deprecated_member_use`, `SA1019`, `CS0618`, `DEPRECATION`, `@typescript-eslint/no-deprecated`, `W1505`).
   - **Permitted Code-Gen Exception**: Tool-generated file exemptions are permitted solely for machine-generated files carrying canonical headers (`DO NOT EDIT`, `@generated`, `.g.*`).
   - Blanket or unadorned suppressions across custom domain code are strictly forbidden.

2. **Clean Separation of Concerns**:
   - Maintain clear boundaries between Presentation, Domain/Business Logic, and Infrastructure/Persistence layers.
   - Domain logic must remain independent of external frameworks and delivery mechanisms.

3. **Early Guard Clauses & Unindented Happy Path**:
   - Validate preconditions and handle edge cases at the very start of functions.
   - Keep the primary "happy path" flow unindented at the base level of the function.

4. **Pure Functions & Determinism**:
   - Keep business logic computations pure and side-effect free.
   - Isolate side effects (network, storage, time, randomness) at the system boundaries.

---

### Simplicity Ladder & Anti-AI-Slop

- Climb, in order, before writing anything: **YAGNI** → reuse an existing script/module in this repository → a POSIX shell built-in or the stdlib of whichever embedded language owns the file → a platform-native capability → an already-installed dependency → a one-line idiomatic expression → the smallest correct diff. The best code is the code you did not write.
- Prefer shell built-ins (`case`, `test`/`[`, parameter expansion `${var%%...}`, `printf`) over spawning external binaries (`sed`, `awk`, `cut`, `basename`, `dirname`) when the shell does the job; `coreutils` before a new dependency.
- Banned ceremonies: one-line forwarding wrapper scripts, single-implementation abstractions with no fake need, pass-through functions that only rename arguments, and narration comments that restate the next line.
- Declare a deliberate simplification ceiling with a comment marker in the file's own syntax (`# ponytail: <ceiling + evolution trigger>`, `// ponytail: ...`, `<!-- ponytail: ... -->`); markers are report-only (`PT-01`).
- Remediation tags for anti-slop sweeps: `[DELETE]`, `[STDLIB]`, `[NATIVE]`, `[YAGNI]`, `[SHRINK]`.
- Safety frontier: validation, error routing, privacy, accessibility and Quality Gates are never pruned for brevity.

### SOLID & Substitutability

- **S**ingle responsibility — one script/function/package changes for one reason.
- **O**pen/closed — extend by new executables/plugins, not by threading flags through existing branches.
- **L**iskov — a swap of an implementation must honor the same command contract: argument shape, stdout format and exit code.
- **I**nterface segregation — expose the narrowest env/stdin/stdout contract a caller needs, never a kitchen-sink entry point.
- **D**ependency inversion — depend on an interface (interface of the embedded language) or an explicit parameter, not a hardcoded concrete collaborator.
- Concrete substitutability failure to reject: a program that still runs but returns a different exit code or output shape than the contract its callers rely on.
- A production implementation never contains the stack's unimplemented placeholder; here `echo "not implemented"` (advisory under `CC-09`) and the language-specific `CC-09` token of the matching rule file.

### Dependency Inversion & Container Confinement

- Pass dependencies explicitly: function parameters, environment variables, config files or stdin; the composition root wires the concrete implementations together.
- No global mutable singletons acting as a hidden service locator; shared state is passed down the call chain.
- The universal engine is a documented no-op for `CC-07` (service-locator) and `CC-10` (concrete network client): there is no container idiom in this stack. Apply the matching `templates/rules/<stack>/rules.md` for the embedded language in use.
- Allowed composition roots are the entry point of each embedded language: `main.dart`, `main.ts`, `main.py`, `main.go`, `src/main.rs`, `Program.cs`, `*Application*`, `main.*` launch scripts — resolution and concrete client construction happen only there.

### Non-Nullable Collections & Nullability Minimization

- `null`/`nil`/`None` carries business meaning only; "absent collection" is not a third state — a collection parameter or return defaults to a constant empty collection.
- In shell, distinguish an unset variable (`set -u` discipline) from an empty one; never let an empty value silently stand in for "unknown".
- The universal engine is a documented no-op for `CC-08`; follow the language-specific realization: mechanical for Dart, TypeScript, Kotlin, Swift and .NET, nil-safe documented contract for Go and Rust.
- Non-null assertion operators — `!`, `!!`, `.unwrap()`, `.expect()`, unchecked casts — stay banned in production logic; guard and return an explicit domain value instead.

### Two-Layer Resilience & Zero Silent Exception Swallowing

- Layer 1 (infrastructure): catch, log with structured context plus the error and stack trace, then propagate or wrap into a domain error/result.
- Layer 2 (coordination): timeout, retry with backoff, barrier/circuit breaker at call sites that cross a boundary.
- The universal shell engine is a documented no-op for `CC-06` (it relies on exit codes); authoring must still apply the language-specific swallowing shapes: Dart/JS/TS/Kotlin/Swift/C# empty `catch { }`, Python `except ...: pass`, Go empty `if err != nil { }` / `_ = err`, Rust discarded `.ok();`.
- In shell, never blanket-suppress failure with `|| true` or an empty `if ! cmd; then :; fi`; check the exit code and either log or exit non-zero.
- Use the stack's logging interface (any identifier containing `log`/`logger`/`Log`, or the platform logging API) instead of raw output; raw `echo` in production scripts is `CC-05`.

### DRY Test Factories

- One local factory/helper per entity per suite, named `run_case` or `make_<entity>`/`make<Entity>` per the embedded language idiom; fixtures live in fixture directories.
- Only parameters that actually vary; no dead parameters, no null placeholders passed to satisfy a signature.
- Deterministic data only: no ambient clock, randomness, network or filesystem state in a fixture; inject fakes at boundaries.
- Runner is `bash test.sh`, which delegates to each embedded language's runner (`flutter test`, `jest`, `pytest`, `go test`, `cargo test`, `dotnet test`).

### Solution Abstraction Elevation (Rule of Two)

- Two occurrences of the same solution in the same change set become one shared function/script; never copy a third time.
- A single-implementation abstraction with no fake or mock need is prohibited — inline it until a second concrete use exists.
- Every elevation documents its ceiling and the trigger that invalidates it (`ponytail:` marker), so the next author knows when to reopen the decision.

### Native / Multi-Platform Dependency Audit

- Declare dependencies in the per-language manifest (`pubspec.yaml`, `package.json`, `pyproject.toml`/`requirements.txt`, `go.mod`, `Cargo.toml`, `build.gradle.kts`, `Package.swift`, `*.csproj`) and keep the lockfile in the change set.
- Prove the polyglot build matrix before accepting a dependency: the targets of every embedded language this repository must ship (Debug/Profile/Release or the stack's device/runtime matrix).
- Forbid a dependency that only one embedded language needs but that every build must carry; keep per-language dependency graphs isolated, and audit transitive native/ABI compatibility in downstream host repositories.

### Memory & Allocation Discipline

- The universal engine is a documented no-op for `CC-11`; apply the language-specific hot-path shapes from the matching rule file (spread/copy inside loops in Dart/TS, `toList` in Kotlin, `.clone()` in Rust, `Array(` in Swift, `.ToList()` in .NET).
- Inspect without copying and return the original reference when nothing changes; avoid intermediate collections and gratuitous string concatenation on hot paths.
- In shell, prefer built-ins over subshells and `$(cat)` inside loops; stream with pipes instead of materializing intermediate files.

### Privacy by Design (Consent & PII Redaction)

- No personal data leaves the process or is persisted without an explicit consent gate evaluated first.
- Redaction is lazy and allocation-free on the clean path: return the original reference when nothing is redactable; keep one blocked-key keyword list in a single module.
- Third-party SDKs are not initialized before consent; sanitize before logging, sending or storing; see `docs/standards/analytics_and_telemetry.md`.

### Applicable Governance Checks

- `oaef clean-code` enforces these; see `docs/standards/governance_checks.md`. Applies here: `CC-01` (single-letter bindings; shell `local x=` plus JS/TS tokens), `CC-02` (cryptic abbreviations), `CC-04` (hardcoded placeholder/secret, blocking in every profile), `CC-05` (`echo` in production scripts), `CC-09` (`echo "not implemented"`, advisory). Documented no-ops: `CC-03`, `CC-06`, `CC-07`, `CC-08`, `CC-10`, `CC-11` — consult `templates/rules/<stack>/rules.md` for the embedded language in use.
