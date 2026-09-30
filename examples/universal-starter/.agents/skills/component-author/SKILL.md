---
name: component-author
description: Specialized component-author skill for Universal / Polyglot under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: universal
  version: 1.0.0
---

# Component Author (Universal / Polyglot)

> **Stack Profile:** Universal / Polyglot  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Author modular, decoupled components and domain entities in Universal / Polyglot following design tokens and architectural boundaries.

## Architecture Guidelines
- **State Management**: `Modular architecture`.
- **Token Compliance**: Consume visual tokens defined in `docs/DESIGN.md`. Never hardcode colors, padding, or dimensions.
- **Encapsulation**: Expose clean public APIs; hide implementation details behind private/internal visibility.
- **Clean Sizing**: Ensure component files remain strictly `<= 300 LOC`.
