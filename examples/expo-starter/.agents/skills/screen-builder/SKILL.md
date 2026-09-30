---
name: screen-builder
description: Specialized screen-builder skill for Expo under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: expo
  version: 1.0.0
---

# Screen Builder (Expo)

> **Stack Profile:** Expo  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Build file-based routes in Expo Router adhering to Clean Sizing and typed navigation.

## Guidelines & Invariants
- Keep app/ route files <= 200 LOC by extracting UI logic to src/features/.
- Use Expo Router typed routes (<Link href="/details/[id]" />).
- Configure screen options and headers declaratively using Stack.Screen.
