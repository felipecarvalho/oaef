# Automated Testing & Verification Standards

> Canonical automated testing strategy for `expo-starter`.

---

## 1. Quad Coverage Targets

Quality in OAEF is verified algorithmically. The test suite must satisfy:

| Coverage Dimension | Minimum Baseline Floor | Target |
| :--- | :--- | :--- |
| **Line Coverage** | **>= 95.0%** | **100.0%** |
| **Statement Coverage** | **>= 95.0%** | **100.0%** |
| **Function Coverage** | **>= 95.0%** | **100.0%** |
| **Branch Coverage** | **>= 90.0%** | **95.0%** |

---

## 2. Testing Pyramid & Structure

1. **Unit Tests**:
   - Verify business logic, domain models, state machines, and pure transformation functions in total isolation.
   - External dependencies (APIs, databases, device features) must be mocked using test doubles.
2. **Component / Widget Tests**:
   - Verify that UI components render correctly under varying states (loading, success, error, empty).
   - Simulate user interactions (taps, scrolling, form input) and assert expected state emissions.
3. **Integration & Flow Tests**:
   - Verify vertical end-to-end user journeys and state transitions across layers.

---

## 3. The AAA Testing Pattern (Arrange, Act, Assert)

Every test must follow the clear, three-phase AAA pattern:
```
// 1. Arrange: setup inputs, fixtures, and mock expectations
// 2. Act: invoke the method under test
// 3. Assert: verify state changes and emitted events
```

---

## 4. Testing Negative Pathways & Branch Coverage
- A test suite that only tests the "happy path" is insufficient.
- You MUST write explicit tests for error states, network exceptions, invalid payloads, timeouts, and fallback mechanisms to achieve the required 90%+ branch coverage.
