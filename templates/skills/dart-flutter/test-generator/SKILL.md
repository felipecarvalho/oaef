---
name: test-generator
description: Specialized test-generator skill for Dart & Flutter under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: dart-flutter
  version: 1.0.0
---

# Test Generator (Dart & Flutter)

> **Stack Profile:** Dart & Flutter  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Generate high-coverage unit, component, and integration tests for Dart & Flutter to achieve and maintain OAEF Quality Gate thresholds:
- **Lines Coverage**: `>= 95.0%`
- **Branches Coverage**: `>= 90.0%`
- **Zero Flaky Tests**: Deterministic, hermetic, and fast execution.

## Tooling & Libraries
- **Test Runner**: `flutter test --coverage`
- **Mocking Library**: `package:mocktail & package:bloc_test`

## Testing Rules & Invariants
1. **Follow the AAA Pattern**: Every test must clearly demarcate Arrange, Act, and Assert.
2. **Exhaustive Branch Coverage**: You MUST write tests covering error conditions, timeouts, invalid payloads, and fallback logic (testing `else` and exception blocks).
3. **Hermetic Isolation**: Never perform real external network calls or persist state across tests. Always use mocks or in-memory fixtures.
