---
name: test-generator
description: Specialized test-generator skill for Python 3 & FastAPI under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: python
  version: 1.0.0
---

# Test Generator (Python 3 & FastAPI)

> **Stack Profile:** Python 3 & FastAPI  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Generate high-coverage unit, component, and integration tests for Python 3 & FastAPI to achieve and maintain OAEF Quality Gate thresholds:
- **Lines Coverage**: `>= 95.0%`
- **Branches Coverage**: `>= 90.0%`
- **Zero Flaky Tests**: Deterministic, hermetic, and fast execution.

## Tooling & Libraries
- **Test Runner**: `pytest --cov=. --cov-report=lcov`
- **Mocking Library**: `pytest-mock (mocker)`

## Testing Rules & Invariants
1. **Follow the AAA Pattern**: Every test must clearly demarcate Arrange, Act, and Assert.
2. **Exhaustive Branch Coverage**: You MUST write tests covering error conditions, timeouts, invalid payloads, and fallback logic (testing `else` and exception blocks).
3. **Hermetic Isolation**: Never perform real external network calls or persist state across tests. Always use mocks or in-memory fixtures.
