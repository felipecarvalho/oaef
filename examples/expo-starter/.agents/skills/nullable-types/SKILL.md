---
name: nullable-types
description: Specialized nullable-types skill for Expo under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: expo
  version: 1.0.0
---

# Nullable Types (Expo)

> **Stack Profile:** Expo  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Enforce strict TypeScript null safety across all Expo screens and hooks.

## Guidelines & Invariants
- Enforce strict TypeScript compiler flags (strict: true).
- Handle undefined search params and route params defensively using zod schemas or type guards.
- Ban non-null assertions (!) in route handlers.
