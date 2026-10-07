<!-- oaef:section:standard:testing -->
# Automated Testing & Verification Standards

> Canonical automated testing strategy for `typescript-starter`.

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

---

## 5. DRY Test Factories (`make*`)

Test data construction is repeated far more often than production code; duplicated literals rot silently the moment a model gains a field. Every entity used across more than one test gets a single local factory.

### 5.1 Canonical Anatomy

| Element | Rule |
| :--- | :--- |
| **Name** | `make<Entity>` (for example `makeSession`, `makeBooking`), colocated with the suite that owns the entity. |
| **Parameters** | Only the fields that **vary per test** are exposed. |
| **Defaults** | Deterministic and self-consistent: calling `makeSession()` with no arguments yields a valid, representative instance. |
| **Return** | A fully constructed entity; never a partially initialized builder the test must finish. |

```text
Session makeSession({String id = 'session-1', bool isActive = true}) =>
    Session(id: id, isActive: isActive, startedAt: fixedStart, device: defaultDevice);
```

### 5.2 Anti-Pattern: factory over-parameterization

A factory that mirrors **every** field of the entity is a constructor with extra steps: each test restates fields it does not care about, and the factory becomes a second, silently-diverging schema. Expose a parameter only when at least one test in the suite varies it.

### 5.3 Dead Parameters Are Deleted

A parameter that no test ever sets is not kept "for later": it is removed from the factory signature in the same change. Dead parameters hide intent and imply variation that does not exist. Optional collection parameters on a factory MUST default to a constant empty collection (see §7 of `coding_patterns.md`).

<!-- /oaef:section:standard:testing -->
