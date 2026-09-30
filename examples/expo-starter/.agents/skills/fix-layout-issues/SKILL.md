---
name: fix-layout-issues
description: Specialized fix-layout-issues skill for Expo under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: expo
  version: 1.0.0
---

# Fix Layout Issues (Expo)

> **Stack Profile:** Expo  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Diagnose and correct layout overflows, safe area clipping, and responsive viewport issues in Expo.

## Guidelines & Invariants
- Integrate SafeAreaView and useSafeAreaInsets for notch/island accommodation.
- Use dynamic window dimensions (useWindowDimensions) for adaptive tablet and web rendering.
- Prevent flexbox sizing bugs in nested scroll views.
