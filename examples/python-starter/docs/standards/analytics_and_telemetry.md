<!-- oaef:section:standard:analytics_and_telemetry -->
# Analytics & Telemetry Standard

> The working reference for product telemetry: the provider abstraction, the dual event taxonomy, the consent gate, the PII sanitizer contract and the testing seams. The law lives in `AGENTS.md` §4.17.

---

## 1. Provider Abstraction Contract

Telemetry goes through one dispatcher that owns a set of providers. The dispatcher never knows a vendor; the application never knows a provider.

```pseudo
interface TelemetryProvider:
    name: String
    track(event: TelemetryEvent)
    identify(user: Identifier)
    dispose()

class TelemetryDispatcher(providers: List<TelemetryProvider>, sanitizer: PiiSanitizer, logger: Logger):
    register(provider):
        providersByName.putIfAbsent(provider.name, provider)   // idempotent
    track(event):
        for provider in providersByName.values:
            try: provider.track(sanitizer.sanitize(event))
            catch failure: logger.error("telemetry provider failed", provider.name, failure)
    reset(): providersByName.clear()
    dispose(): for provider in providersByName.values: provider.dispose(); reset()
```

Rules:

* **Idempotent registration** — `Map.putIfAbsent` (or the language equivalent: `setdefault`, `entry().or_insert`, `computeIfAbsent`) guarantees one provider per name; re-registering never duplicates delivery.
* **Failure isolation** — one provider raising never aborts the dispatch loop; the failure is logged and the remaining providers still receive the event (§9 of `clean_code.md`).
* **Lifecycle** — `dispose` releases each provider exactly once; `reset` clears the registry between tests and on sign-out.

---

## 2. Dual Event Taxonomy

Two naming systems coexist, joined by one explicit mapper. They never bleed into each other.

| Layer | Naming | Example | Audience |
| :--- | :--- | :--- | :--- |
| Behavioral analytics | lower `snake_case` | `booking_flow_completed` | product funnels, warehouse |
| CRM projection | self-explanatory `PascalCase` | `BookingFlowCompleted` | CRM pipelines, automations |

The behavioral name is the event type; the CRM projection is derived on dispatch through one function:

```pseudo
function mapToCrmEventName(behavioralName: String) -> String:
    return behavioralName.split("_").map(capitalize).join("")
```

The mapping table lives beside the mapper so a new event cannot ship without its CRM name:

| Behavioral (`snake_case`) | CRM (`PascalCase`) |
| :--- | :--- |
| `session_started` | `SessionStarted` |
| `network_retry_succeeded` | `NetworkRetrySucceeded` |
| `booking_flow_completed` | `BookingFlowCompleted` |

---

## 3. Consent Gate

No analytics event, user identifier or third-party SDK call leaves the process before consent is granted. Rules:

* The dispatcher is inert until the consent store reports `granted`.
* Third-party SDKs are not initialized at startup; they initialize on the first consented event.
* Withdrawal stops collection immediately: the gate closes before the next event is evaluated, and `reset` releases the providers.

Every event dispatch is gated by the same check, so a new call site cannot bypass consent.

---

## 4. PII Sanitizer Contract

Sanitization removes personal data from any payload before it is persisted, logged or sent. The contract:

* **Lazy-copy** — when a payload contains no blocked key, the original reference is returned untouched and nothing is allocated. A copy happens only when something actually changes.
* **Blocked-key keyword list** — one list, declared in one place, matched case-insensitively against key names: `password`, `token`, `email`, `phone`, `document`, `address`, `birthDate`, `cardNumber`, plus the equivalent terms in any other domain vocabulary (never product-specific identifiers).

| Disposition | When | Effect |
| :--- | :--- | :--- |
| Substitute | The key must remain present for schema stability. | Value becomes `[REDACTED]`. |
| Strip | The key is not part of the contract. | The entry is removed from the payload. |

* **Allocation-free clean path** — a clean payload is returned by reference; the sanitizer never builds an equal copy.

---

## 5. Logger Injection

The logger arrives through the constructor as an abstraction, never from a static singleton or an ambient lookup. Telemetry components log through that injected logger, so provider failures are recorded with structured context (`provider.name`, the error, the stack trace) under the logging standard [`logging.md`](logging.md).

---

## 6. Testing with Mocks

Each seam of the dispatcher is asserted directly:

1. **Dispatch** — a recording fake provider asserts the exact event type and payload received.
2. **Isolation** — one provider double configured to fail; assert every other provider still received the event and the failure was logged.
3. **Sanitizer** — assert that a blocked key becomes `[REDACTED]` (or is stripped), and that a clean payload is returned by reference (identity check), proving the lazy-copy contract.
4. **Consent** — assert that no provider call happens while consent is absent and that withdrawal stops subsequent delivery.

Test data uses the DRY factories of [`testing.md`](testing.md); no network, no ambient clock.

---

## 7. Multi-Provider Registration Example

```pseudo
dispatcher.register(AnalyticsSink(endpoint))
dispatcher.register(CrmSink(apiClient))
dispatcher.register(BrokenSink())      // fails on track()

dispatcher.track(TelemetryEvent("session_started", payload))
// AnalyticsSink and CrmSink receive the sanitized event;
// BrokenSink raises, its failure is logged, and the dispatch completes.
```

Registration is idempotent: registering `CrmSink` twice delivers one copy. Identifiers and canonical messages are specified in [`governance_checks.md`](governance_checks.md).

<!-- /oaef:section:standard:analytics_and_telemetry -->
