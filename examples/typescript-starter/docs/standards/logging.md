<!-- oaef:section:standard:logging -->
# Structured Logging & Diagnostics Standards

> Canonical logging guidelines for `typescript-starter`.

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

---

## 3. Severity Mapping

The four canonical levels map to the stack-native severity, a defined production behaviour and a telemetry destination. Each logger adapter (see `analytics_and_telemetry.md` §5) performs this mapping; call sites use the canonical level and never a raw platform verb.

| Canonical level | Stack-native severity | Production behaviour | Telemetry destination |
| :--- | :--- | :--- | :--- |
| **DEBUG** | `debug` / `fine` / `verbose` | No-op (compiled out) | None |
| **INFO** | `info` / `notice` | No-op in release; emitted only when the environment enables it | Lifecycle breadcrumb |
| **WARN** | `warn` / `warning` | Emitted | Breadcrumb preceding a failure |
| **ERROR** | `error` / `severe` / `fatal` | Emitted with the error object and stack trace | Crash/error monitoring |

The severity value itself always comes from the canonical enum; the adapter is the only place the platform-specific translation exists.

## 4. Namespace Discipline

- Namespaces use dot-notation and are hierarchical: `app.checkout.payment`, `app.session.restore`.
- Application code MUST prefix every namespace with `app.`; framework and library namespaces never use that prefix, so application records stay filterable.
- One namespace per module: the namespace is derived from the module path, not invented per log statement.
- The namespace is a stable contract. Renaming a module renames its namespace in the same change; ad-hoc one-off namespaces are forbidden.

| Example namespace | Owns |
| :--- | :--- |
| `app.session` | Session lifecycle and restore |
| `app.checkout.payment` | Payment adapter within checkout |
| `app.network` | HTTP client and retry policy |

## 5. Release Behaviour

1. Debug output MUST be a complete no-op in release builds: not merely filtered, but absent from the shipped binary where the toolchain supports it.
2. The debug guard pattern wraps every diagnostic call:

```text
if (diagnosticsEnabled) {
  logger.debug('app.session', 'restoring session', attributes: {'sessionId': session.id});
}
```

3. The guard is a single environment/compile-time flag resolved at the composition root and injected; a scattered `kDebugMode`-style check per file is a defect.
4. WARN and ERROR are never guarded: they are part of production observability and always reach the telemetry sink.

## 6. Language & Privacy

- **100% English**: every message, key and attribute name is professional English. No emojis, no decorative symbols, no mixed-language strings.
- **Zero PII**: passwords, tokens, API keys, card numbers, e-mail addresses, phone numbers and any other personal identifier MUST NEVER be logged.
- The PII sanitizer reuses the **blocked-key keyword list defined in `analytics_and_telemetry.md` §4**; logger adapters apply the same redaction contract (`[REDACTED]` for values whose shape must survive, stripping for the rest) and the same lazy-copy discipline, so the clean path allocates nothing.
- Sanitization happens at the logging boundary, not at each call site: a raw payload is never handed to the transport.

## 7. Injection Matrix

A logger is a dependency like any other. Prefer an injected logger interface over a global static utility; the static form is acceptable only where no composition root can reach.

| Layer | Verdict | Rationale |
| :--- | :--- | :--- |
| **Composition root** | `static utility` | The root wires the concrete logger; no injection target exists yet. |
| **Application service** | `Logger interface injection` | Testable, mockable, and namespace-scoped per instance. |
| **Domain** | `Logger interface injection` | Domain outcomes are logged through an injected port; the domain never imports a platform logger. |
| **Infrastructure** | `Logger interface injection` | Adapters log through the interface so the concrete sink stays swappable. |

`Logger interface injection` is the default; a `static utility` call outside the composition root is a service-locator smell and is subject to the confinement rule of `coding_patterns.md` §8.

<!-- /oaef:section:standard:logging -->
