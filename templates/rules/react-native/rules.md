### Stack-Specific Architectural Rules (React Native)

1. **Strict Anti-Suppression Policy**:
   - Suppressing compiler, linter, or typechecker diagnostics via `/* eslint-disable */`, `// eslint-disable-next-line`, `// @ts-ignore`, or `// biome-ignore` is strictly forbidden.
   - **Permitted Scoped Deprecation Exception**: `// eslint-disable-next-line @typescript-eslint/no-deprecated` is permitted solely when calling deprecated APIs from external npm dependencies during active transitional migrations.
   - **Permitted Code-Gen Exception**: Generated code in `codegen/`, `specs/`, or files with `@generated` markers are exempt from manual linter rules.
   - Blanket suppressions without specific rule tokens on domain code are strictly forbidden.

2. **Prohibition of Helper Render Functions in UI**:
   - Never create helper rendering functions inside components (e.g., `const renderRow = () => ...` or `function renderHeader()`).
   - Every UI sub-view or component MUST be extracted into a dedicated functional component with an explicit, typed props interface in its own file.
   - This keeps React reconciliation bounds optimal and enables granular memoization with `React.memo`.

3. **StyleSheet Discipline & Performance Optimization**:
   - All style declarations MUST be defined statically via `StyleSheet.create` outside component render functions.
   - Inline style objects (e.g. `style={{ padding: 16 }}`) inside render loops or list items are strictly prohibited to prevent garbage collection pressure.

4. **New Architecture & TurboModule Specifications**:
   - Native module bridges must target the New Architecture (Fabric renderer, TurboModules, Bridgeless mode).
   - Define typed native specs using TypeScript Codegen protocols (`TurboModuleRegistry.getEnforcing<Spec>('...')`).

5. **Strict Mobile Accessibility**:
   - All interactive elements (`Pressable`, `Touchable`) MUST specify `accessibilityRole` and `accessibilityLabel`.
   - Maintain a minimum touch target size of 44x44 dp across all interactive elements.
