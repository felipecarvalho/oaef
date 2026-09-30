### Stack-Specific Architectural Rules (Dart & Flutter)

1. **Strict Anti-Suppression Policy**:
   - Suppressing static analysis warnings via `// ignore:` or `// ignore_for_file:` is strictly forbidden.
   - **Permitted Scoped Deprecation Exception**: `// ignore: deprecated_member_use` is permitted solely when invoking deprecated APIs from external packages/SDKs during active framework migration.
   - **Permitted Code-Gen Exception**: `// ignore: type=lint` is permitted solely at the header of code-generator outputs (`*.g.dart`, `*.freezed.dart`).
   - Blanket suppressions without specific rule tokens are strictly forbidden.

2. **Prohibition of Helper Build Functions in UI**:
   - Never create helper rendering methods (e.g., `Widget _buildHeader()`, `Widget _buildItem()`).
   - Every UI sub-view or component MUST be extracted into a dedicated `StatelessWidget` (preferring `const` constructors) in its own file.
   - This enables granular element tree reconciliation, const caching, and keeps file sizes within Clean Sizing limits.

3. **Dot-Shorthand Syntax**:
   - Whenever the target context type is inferred by the Dart analyzer, use concise dot-shorthand syntax (`.s400`, `.large`, `.min`, `.loading`, `.start`, `.zero`) in constructors, typed arguments, switch expressions, and state mutations (`state.copyWith(status: .loading)`).
   - Explicit enum qualification (e.g. `SessionStatus.loading`) is reserved for generic parameters (`Object?` or `dynamic`), such as test matchers (`equals`, `having`).

4. **Strict Internationalization & Localization**:
   - Hardcoded user-facing strings in visual widgets are strictly forbidden.
   - All text rendered to users MUST be resolved via localization keys (e.g., `context.l10n.<key>`).

5. **State Management & Unidirectional Data Flow**:
   - Presentation widgets must never interact directly with database clients, network clients, or repositories.
   - All state mutations and asynchronous orchestrations must flow through Cubits or Blocs.
