### Stack-Specific Architectural Rules (Swift & iOS)

1. **Strict Anti-Suppression Policy**:
   - Suppressing compiler warnings or SwiftLint diagnostics via `// swiftlint:disable`, `// swiftlint:disable:next`, or `// swiftlint:disable:this` is strictly forbidden.
   - **Permitted Scoped Deprecation Exception**: `// swiftlint:disable:next deprecated` or `// swiftlint:disable:next deprecated_call` is permitted solely when calling deprecated Apple framework or external package APIs during active migration.
   - **Permitted Code-Gen Exception**: `// swiftlint:disable all` is permitted solely at the file header of machine-generated files (matching `*.generated.swift` or SwiftGen/Sourcery outputs).
   - Blanket suppressions without specific rule tokens on domain code are strictly forbidden.

2. **Prohibition of Helper ViewBuilder Functions**:
   - In SwiftUI, avoid creating `@ViewBuilder func buildHeader() -> some View` helper functions inside a parent view.
   - Extract sub-views into dedicated `View` structs in their own files to allow fine-grained SwiftUI body invalidation and preview generation.

3. **Strict Swift 6 Concurrency Compliance**:
   - Enable complete concurrency checking. Ensure all types crossing actor boundaries conform to `Sendable`.
   - UI updates, ViewModel state changes, and navigation must be explicitly bound to `@MainActor`.

4. **Zero Force Unwrapping**:
   - Force unwrapping (`!`) and force casting (`as!`) are strictly prohibited in domain and production logic.
   - Use `guard let`, `if let`, or optional chaining to safely handle nil and downcasting.

5. **Exhaustive Pattern Matching**:
   - Use exhaustive `switch` statements over domain enums without relying on a catch-all `default:` clause, ensuring compiler checks catch any new enum cases.
