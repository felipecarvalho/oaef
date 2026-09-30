### Stack-Specific Architectural Rules (TypeScript & Web)

1. **Strict Anti-Suppression Policy**:
   - Suppressing compiler, linter, or typechecker diagnostics via `/* eslint-disable */`, `// eslint-disable-next-line`, `// @ts-ignore`, `// @ts-nocheck`, or `// biome-ignore` is strictly forbidden.
   - **Permitted Scoped Deprecation Exception**: `// eslint-disable-next-line @typescript-eslint/no-deprecated` is permitted solely when calling deprecated APIs from external npm dependencies during active transitional migrations.
   - **Permitted Code-Gen Exception**: `/* eslint-disable */` or `// biome-ignore lint: generated` is permitted solely at the file header of machine-generated files (matching `*.g.ts`, `*.generated.ts`, or files with `@generated` markers).
   - Blanket suppressions without specific rule tokens or on custom domain code are strictly forbidden.

2. **Prohibition of Helper Render Functions in UI**:
   - Never create helper rendering functions inside components (e.g., `const renderHeader = () => ...` or `function renderListItem()`).
   - Every UI sub-view or component MUST be extracted into a dedicated functional component with an explicit, typed props interface in its own file.
   - This ensures React/Vue/Solid reconciliation boundaries remain optimal and allows targeted memoization.

3. **Type Soundness & Ban on `any`**:
   - The `any` type is strictly forbidden. Use `unknown` with runtime type narrowing, zod/valibot schemas, or generics.
   - Prefer discriminated unions over loosely typed payloads.

4. **String Literal Unions over Numeric Enums**:
   - Prefer string literal unions (`type RequestStatus = 'idle' | 'loading' | 'success' | 'failure'`) over TypeScript numeric enums.
   - This eliminates runtime enum boilerplate and produces cleaner serialization.

5. **State Immutability**:
   - Direct mutation of state objects or arrays is strictly forbidden. Always use immutable update patterns, object spreads, or immutable libraries.
