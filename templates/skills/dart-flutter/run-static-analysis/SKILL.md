---
name: run-static-analysis
description: Specialized run-static-analysis skill for Dart & Flutter under the Open Agentic Engineering Framework (OAEF).
metadata:
  framework: OAEF
  stack: dart-flutter
  version: 1.0.0
---

# Run Static Analysis (Dart & Flutter)

> **Stack Profile:** Dart & Flutter  
> **Governance Standard:** OAEF v1.0.0 (Author: Felipe Carvalho)  
> **Quality Gate Policy:** Strict mathematical audit and Clean Sizing.

## Mission & Scope
Execute strict static analysis and apply mechanical automated fixes in Dart & Flutter.

## Commands
```bash
# Static analysis check:
dart analyze --fatal-infos

# Automated mechanical fixes:
dart fix --apply
```

## Rules
- Zero warnings and zero errors allowed.
- Never add inline ignore comments to bypass rules. Fix the underlying architectural violation.
