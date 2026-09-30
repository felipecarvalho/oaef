---
name: component-author
description: Specialized component-author skill for Swift & Apple Platforms under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: swift
  version: 1.0.0
---

# Component Author (Swift & Apple Platforms)

> **Stack Profile:** Swift & Apple Platforms  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Author modular, decoupled components and domain entities in Swift & Apple Platforms following design tokens and architectural boundaries.

## Architecture Guidelines
- **State Management**: `SwiftUI @Observable / Observation framework`.
- **Token Compliance**: Consume visual tokens defined in `docs/DESIGN.md`. Never hardcode colors, padding, or dimensions.
- **Encapsulation**: Expose clean public APIs; hide implementation details behind private/internal visibility.
- **Clean Sizing**: Ensure component files remain strictly `<= 300 LOC`.
