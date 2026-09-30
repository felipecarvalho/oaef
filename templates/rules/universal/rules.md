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
