# Structured Logging & Diagnostics Standards

> Canonical logging guidelines for `kotlin-starter`.

---

## 1. Principles of Production-Safe Logging

1. **Debug Only**: Logs must never pollute the console or device output in Release or Production builds. Output is strictly gated by debug environment flags.
2. **Structured & Predictable**: Messages should include consistent severity levels (DEBUG, INFO, WARN, ERROR) and the originating subsystem tag.
3. **100% Strict English & Zero Emojis**: All log messages must be written in professional, concise English following sober UNIX style.
4. **Zero Sensitive Data (LGPD / GDPR / PII Safe)**: Never log passwords, authentication tokens, API keys, credit cards, or personally identifiable customer data.

---

## 2. Severity Levels

| Level | When to Use | Production Behavior |
| :--- | :--- | :--- |
| **DEBUG** | Granular diagnosis, internal state changes, HTTP headers | No-op (disabled) |
| **INFO** | Significant lifecycle milestones (app bootstrap, route change) | No-op / Telemetry only |
| **WARN** | Recoverable anomalies, fallback mechanism activations | Telemetry breadcrumb |
| **ERROR** | Unhandled exceptions, failed operations, network breaks | Sent to crash monitoring |
