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
