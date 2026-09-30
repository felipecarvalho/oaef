---
name: test-generator
description: Specialized test-generator skill for React Native under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: react-native
  version: 1.0.0
---

# Test Generator (React Native)

> **Stack Profile:** React Native  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Generate component and unit tests using Jest and React Native Testing Library (RNTL).

## Guidelines & Invariants
- Test user interactions using fireEvent and user-event from RNTL.
- Verify UI state rendering and accessibility queries (getByRole, getByText).
- Mock native modules cleanly using jest.mock.
