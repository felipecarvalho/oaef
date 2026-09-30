---
name: component-author
description: Specialized component-author skill for React Native under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: react-native
  version: 1.0.0
---

# Component Author (React Native)

> **Stack Profile:** React Native  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Build accessible, performant React Native visual components adhering to design system tokens.

## Guidelines & Invariants
- Define styles statically with StyleSheet.create outside the component render function.
- Prohibit helper render methods (e.g. renderHeader). Extract sub-views into dedicated functional components with typed props.
- Include accessibilityRole, accessibilityLabel, and ensure 44x44 dp minimum touch target size.
