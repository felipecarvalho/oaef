### Stack-Specific Architectural Rules (Kotlin Multiplatform / KMP)

1. **Strict Anti-Suppression Policy**:
   - Suppressing compiler warnings or detekt/ktlint rules via `@Suppress(...)` or `@file:Suppress(...)` is strictly forbidden.
   - **Permitted Scoped Deprecation Exception**: `@Suppress("DEPRECATION")` or `@Suppress("DeprecatedCallableAddReplaceWith")` is permitted solely when invoking deprecated APIs from external multiplatform libraries during active migration.
   - **Permitted Code-Gen Exception**: `@file:Suppress("UNCHECKED_CAST")` or `@Generated` is permitted solely in build-tool generated files (e.g. SQLDelight, KSP, Wire outputs).
   - Blanket suppressions without specific warning tokens are strictly forbidden.

2. **Source-Set Separation (`commonMain` vs Platform Sets)**:
   - All domain business logic, data models, repositories, and Compose Multiplatform UI components MUST reside in `commonMain`.
   - Platform-specific implementations (`androidMain`, `iosMain`, `desktopMain`) are strictly restricted to hardware/OS bridging via `expect`/`actual` declarations or injected interfaces.
   - Platform SDK dependencies (e.g. Android `Context`, Apple `UIViewController`) MUST NOT leak into `commonMain`.

3. **Compose Multiplatform UI Decomposition**:
   - Prohibit monolithic `@Composable` functions. Extract distinct sub-views into dedicated `@Composable` functions in separate files.
   - Maintain a strict boundary between stateful container composables and stateless presentation composables.
   - Preview annotations (`@Preview`) must be used for modular visual verification.

4. **Strict Null Safety Discipline**:
   - The non-null assertion operator `!!` is strictly forbidden in production and domain code.
   - Use safe calls `?.`, the Elvis operator `?:`, or explicit precondition functions (`checkNotNull`, `requireNotNull`).

5. **Multiplatform Coroutines & Flow Discipline**:
   - All asynchronous state streaming must flow through `StateFlow` or `SharedFlow`.
   - Never launch coroutines into `GlobalScope`. Always bind jobs to structured, cancelable scopes (e.g. `viewModelScope` or injected `CoroutineScope`).
