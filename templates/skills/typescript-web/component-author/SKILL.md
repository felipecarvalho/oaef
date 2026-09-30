---
name: component-author
description: Specialized component-author skill for TypeScript & React/Next.js under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: typescript-web
  version: 1.0.0
---

# Component Author (TypeScript & React/Next.js)

> **Stack Profile:** TypeScript & React/Next.js  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Author modular, decoupled components and domain entities in TypeScript & React/Next.js following design tokens and architectural boundaries.

## Architecture Guidelines
- **State Management**: `React hooks / Zustand`.
- **Token Compliance**: Consume visual tokens defined in `docs/DESIGN.md`. Never hardcode colors, padding, or dimensions.
- **Encapsulation**: Expose clean public APIs; hide implementation details behind private/internal visibility.
- **Clean Sizing**: Ensure component files remain strictly `<= 300 LOC`.
