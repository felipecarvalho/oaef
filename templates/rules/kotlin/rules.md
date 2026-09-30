### Stack-Specific Architectural Rules (Kotlin & Android)

1. **Strict Anti-Suppression Policy**:
   - Suppressing compiler warnings or detekt/ktlint rules via `@Suppress(...)` or `@file:Suppress(...)` is strictly forbidden.
   - **Permitted Scoped Deprecation Exception**: `@Suppress("DEPRECATION")` or `@Suppress("DeprecatedCallableAddReplaceWith")` is permitted solely when invoking deprecated APIs from external Java/Kotlin libraries during active migration.
   - **Permitted Code-Gen Exception**: `@file:Suppress("UNCHECKED_CAST")` or `@Generated` is permitted solely in build-tool generated files (e.g. Room, Dagger, Wire outputs).
   - Blanket suppressions without specific warning tokens are strictly forbidden.

2. **Prohibition of Monolithic Composable Functions**:
   - In Jetpack Compose, avoid monolithic `@Composable` functions.
   - Extract distinct UI sub-elements into dedicated `@Composable` functions in separate files, annotated with `@Preview`.
   - Maintain a clean separation between stateful container composables and stateless presentation composables.

3. **Strict Null Safety Discipline**:
   - The non-null assertion operator `!!` is strictly forbidden in production and domain code.
   - Use safe calls `?.`, the Elvis operator `?:`, or explicit precondition functions (`checkNotNull`, `requireNotNull`).

4. **Sealed Interfaces for Domain State Modeling**:
   - Model UI and business state using `sealed interface` or `sealed class` hierarchies.
   - Process states using exhaustive `when` expressions without a fallback `else` branch, ensuring compile-time safety when new states are added.

5. **Structured Coroutines & Scope Binding**:
   - Never launch coroutines into `GlobalScope`.
   - Always bind asynchronous tasks to structured scopes (`viewModelScope`, `lifecycleScope`, or an injected `CoroutineScope`).
