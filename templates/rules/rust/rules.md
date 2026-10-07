### Stack-Specific Architectural Rules (Rust)

1. **Strict Anti-Suppression Policy**:
   - Suppressing compiler warnings or clippy lints via `#[allow(...)]` or `#![allow(...)]` is strictly forbidden.
   - **Permitted Scoped Deprecation Exception**: `#[allow(deprecated)]` is permitted solely when calling deprecated functions or types from third-party crates during active library migration.
   - **Permitted Code-Gen Exception**: `#[allow(clippy::all)]` is permitted solely on macro-expanded or build-script generated output files.
   - Blanket or unqualified `#[allow(...)]` attributes on domain code are strictly forbidden.

2. **Strict Error Handling with Result & Option**:
   - Calling `.unwrap()` or `.expect()` in domain, library, or production code is strictly forbidden.
   - Propagate errors idiomatically using the `?` operator, or handle them exhaustively with `match` or `if let`.

3. **Borrowing vs. Defensive Cloning**:
   - Do not call `.clone()` defensively simply to satisfy the borrow checker.
   - Structure data ownership, lifetimes, and borrowed references intentionally.

4. **Newtype Pattern for Domain Primitives**:
   - Prevent primitive obsession by wrapping raw identifiers and values in strongly typed newtypes (e.g. `struct AccountId(Uuid)`).
   - Leverage Rust's zero-cost abstractions to enforce compile-time domain invariants.

5. **Structured Error Types**:
   - Use `thiserror` to define precise, enumerated error types for library modules and domain services.
   - Reserve `anyhow` for top-level binaries and CLI orchestration boundaries.

---

### Simplicity Ladder & Anti-AI-Slop

1. Climb seven rungs before writing code: YAGNI → reuse an existing item in `src/` → stdlib primitive (`Option`/`Result`, iterators, `Cow`, `slice::from_ref`, `Default`, `From`) → platform-native capability → already-declared crate in `Cargo.toml` → one-line idiomatic expression → smallest correct diff. Never add a crate for a problem the stdlib already solves.
2. Banned ceremonies: a one-line pass-through `impl` block, a trait with a single implementation and no fake in `tests/`, a forwarding wrapper that only calls the inner method, and narration comments that restate the code.
3. Mark a deliberate ceiling with `// ponytail: <ceiling + evolution trigger>` (e.g. `// ponytail: in-memory cache, move to persistent storage once writes exceed 10k/day`). Reported by `PT-01`, never blocking.
4. Remediation tags: `[DELETE]` dead item, `[STDLIB]` replace a crate with the stdlib, `[NATIVE]` use a platform capability, `[YAGNI]` drop a speculative generic, `[SHRINK]` reduce a signature or module.
5. Safety frontier — validation, error routing, privacy, accessibility and Quality Gates are never pruned.

### SOLID & Substitutability

1. **S**: one reason to change per `struct`/`impl`; split a module mixing I/O and domain logic.
2. **O**: extend through new `impl` blocks and enums, not by editing a closed match arm's callers.
3. **L**: an implementation of a trait must honor the trait contract; a partial implementation that reaches `unimplemented!()` or `todo!()` is a substitutability failure.
4. **I**: prefer narrow, consumer-owned traits over one fat `trait Service` with unused methods.
5. **D**: high-level `src/<feature>/domain` depends on traits it owns, never on a concrete `src/<feature>/data` or `src/<feature>/infra` type.
6. A production implementation never contains `unimplemented!()` or `todo!()` (`CC-09`); implement the contract or do not declare it.

### Dependency Inversion & Container Confinement

1. Dependencies are injected through function parameters, generic bounds (`impl Trait`, `<T: Trait>`) or trait objects (`Box<dyn Trait>`); the decision between them is made by the composition root `src/main.rs`.
2. Rust has no idiomatic global service locator: `CC-07` is a **documented no-op**. The review guidance stands — domain, data and infra modules never reach for a global singleton or a `once_cell`/`lazy_static` service registry to obtain collaborators.
3. `CC-10` is a **documented no-op**; nonetheless a concrete network client (for example `reqwest::Client::new(`) is constructed only at the composition root, and `src/<feature>/domain`/`data` depend on an abstraction over it.
4. Allowed root of this stack: `src/main.rs` and the wiring module it calls.

### Non-Nullable Collections & Nullability Minimization

1. Absence carries business meaning: model it with `Option<T>` deliberately, never as an implicit "field may be unset".
2. A collection parameter or return defaults to a constant empty collection — `&[]`, `Vec::new()`, `Default::default()` — rather than admitting `Option<Vec<T>>` with no domain reason.
3. `CC-08` is a **documented no-op** on Rust: the type system expresses the empty default directly. The advisory contract holds — a collection parameter that accepts `None` because the type is not expressible must be documented as nil-safe in its rustdoc.
4. Non-null assertion is impossible by construction; the analogue is `.unwrap()`/`.expect()`, which stays banned in production logic (see the stack-specific block).

### Two-Layer Resilience & Zero Silent Exception Swallowing

1. Layer 1 (infrastructure, `src/<feature>/infra`): handle the error, log it with structured context plus the error value and its source chain, then propagate with `?` or wrap it in a domain error type.
2. Layer 2 (coordination): apply a timeout, a retry with backoff, or a circuit breaker around fallible calls at the boundary.
3. Prohibited swallowing shapes (`CC-06`): a discarded `.ok();`, `if let Err(_) = ... { }`, and `Err(_) => { }` with no log and no rethrow.
4. Logging interface: the `tracing` or `log` crate with structured fields; a bare `println!` is not a log call and is itself a `CC-05` finding.

### DRY Test Factories

1. One local factory per entity per suite, named `make_<entity>` (e.g. `fn make_order(id: OrderId) -> Order`), living next to the tests in `tests/` or the `#[cfg(test)]` module.
2. Expose only the parameters that actually vary across the suite; remove dead parameters and never thread an "unused for now" argument.
3. Builders are deterministic: no ambient clock, randomness, filesystem or network; inject a fixed value or a `Clock` trait.
4. Test facility: `#[test]` functions, integration tests under `tests/`, hand-written fakes implementing the consumer-owned trait.

### Solution Abstraction Elevation (Rule of Two)

1. The same solution appearing in two or more places is elevated to one shared abstraction in the same change set, under `src/<feature>/domain` or a shared module.
2. A single-implementation abstraction with no fake or mock need is prohibited — it is a ceremonial layer and must be `[DELETE]`d.
3. Every elevation documents its ceiling and the trigger that invalidates it, either in rustdoc or with a `// ponytail:` marker.

### Native / Multi-Platform Dependency Audit

1. Native dependencies are declared in `Cargo.toml` and locked in `Cargo.lock`; audit any `-sys` crate and the system libraries it links against.
2. Prove the build across target triples before accepting the dependency: `aarch64-apple-darwin`, `x86_64-unknown-linux-gnu`, `*-pc-windows-msvc`.
3. In downstream host repositories, verify transitive version compatibility and check for duplicate linked symbols or duplicated native libraries across the crate graph.

### Memory & Allocation Discipline

1. Avoidable-allocation shapes (`CC-11`, advisory): `.clone()` inside a loop body, and an intermediate `Vec`/`String` materialized only to be iterated once.
2. Inspect without copying: take `&T`, use `slice::from_ref`, borrow fields, and prefer iterators over the data instead of collecting.
3. Return the original reference (or `Cow::Borrowed`) when nothing changes; keep hot paths free of needless allocation.

### Privacy by Design (Consent & PII Redaction)

1. No personal data leaves the process or is persisted before the consent gate has recorded a positive consent.
2. Redaction is lazy and allocation-free on the clean path: when nothing is redactable, return `Cow::Borrowed` of the original value, not a rebuilt copy.
3. Keep one keyword list of blocked keys (email, phone, token, etc.) in a single module; third-party SDKs are not initialized before consent.
4. See `docs/standards/analytics_and_telemetry.md` for the provider contract and the PII sanitizer.

### Applicable Governance Checks

- Applies to this stack: `CC-01`, `CC-02`, `CC-04`, `CC-05`, `CC-06`, `CC-09`, `CC-11`. Documented no-ops: `CC-03` (no lazy-init idiom), `CC-07`, `CC-08`, `CC-10`. `oaef clean-code` enforces these; see `docs/standards/governance_checks.md`.
