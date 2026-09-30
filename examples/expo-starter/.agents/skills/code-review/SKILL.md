---
name: code-review
description: Specialized code-review skill for Expo under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: expo
  version: 1.0.0
---

# Code Review (Expo)

> **Stack Profile:** Expo  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Conduct rigorous pre-PR self-audits verifying OAEF Quality Gates, Expo Router rules, and Clean Code.

## Guidelines & Invariants
- Verify zero unallowed linter ignore directives.
- Ensure Clean Sizing compliance (files <= 300 LOC, functions <= 50 LOC).
- Check that npx expo-doctor reports zero dependency or configuration issues.
