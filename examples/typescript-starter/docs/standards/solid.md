<!-- oaef:section:standard:solid -->
# SOLID & Substitutability Standard

> The working reference for the five SOLID principles as they are enforced in OAEF: pragmatic application, language-agnostic anti-patterns, canonical refactors and the mechanical checks (`CC-07`, `CC-09`, `CC-10`). The law lives in `AGENTS.md` §4.8–§4.9.

## 1. Fundamentals

SOLID is not a license to abstract. The five principles exist to keep change local, contracts honest and dependencies pointing at policy instead of detail. They interact directly with the Ponytail ladder: an abstraction is earned when it removes a real duplication or answers a real substitution need, never to anticipate one. The invariant of the standard: a production implementation fulfills its entire contract — it never narrows preconditions, widens postconditions, raises unexpected errors, or ships an unimplemented placeholder (`CC-09`).

## 2. Single Responsibility

**Principle** — a module, class or function has exactly one reason to change.

**Anti-pattern** (one type doing persistence, formatting and notification):

```pseudo
class InvoiceService:
    save(invoice)            // persistence reason
    renderPdf(invoice)       // presentation reason
    emailCustomer(invoice)   // delivery reason
```

**Canonical refactor** — one collaborator per reason to change:

```pseudo
class InvoiceRepository: save(invoice)
class InvoiceRenderer:   render(invoice) -> Document
class InvoiceNotifier:   notify(customer, document)
```

**Mechanical check** — functions over 50 LOC or files over 300 LOC are flagged by the sizing gates (`oaef audit`); responsibility itself is a human review call.

## 3. Open/Closed

**Principle** — behavior is extended by adding new implementations, not by editing every caller.

**Anti-pattern** (a growing conditional per case):

```pseudo
function charge(method):
    if method == "card":   ...
    else if method == "bank": ...
    else if method == "wallet": ...   // edit this function for every new method
```

**Canonical refactor** — a role interface with one implementation per case:

```pseudo
interface PaymentMethod: charge(amount)
class CardPayment implements PaymentMethod
class BankPayment implements PaymentMethod
registry.register(cardPayment)      // new case = new file, no caller edit
```

**Mechanical check** — none specific; the anti-pattern is detected by review. The counter-blade is §7: do not introduce the interface before a second case exists.

## 4. Liskov Substitution

**Principle** — an implementation fulfills the whole contract of the abstraction it stands in for: no narrowed preconditions, no widened postconditions, no unexpected errors.

**Anti-pattern** (a partial implementation that throws):

```pseudo
interface Exporter: export(dataset) -> Report
class CsvExporter implements Exporter:
    export(dataset): throw UnimplementedError("use the other exporter")
```

**Canonical refactor** — either implement the contract or do not claim it:

```pseudo
class CsvExporter implements Exporter:
    export(dataset): return Report(csvRows(dataset))
```

**Mechanical check** — `CC-09`: `UnimplementedError`, `NotImplementedException`, `NotImplementedError`, `unimplemented!()`, `todo!()`, `panic("not implemented")` in a production implementation is blocking. A method that only rethrows is the same violation in disguise.

## 5. Interface Segregation

**Principle** — many small role interfaces beat one fat interface; a consumer depends only on the members it calls.

**Anti-pattern** (one interface for every consumer):

```pseudo
interface UserGateway:
    findById(id)
    updateProfile(user)
    resetPassword(id)
    exportAudit()   // the read-only widget needs findById only
```

**Canonical refactor** — one interface per role:

```pseudo
interface UserReader:  findById(id)
interface UserWriter:  updateProfile(user); resetPassword(id)
interface AuditExport: exportAudit()
```

**Mechanical check** — none specific; the sizing gates discourage the fat type, and review names the pattern.

## 6. Dependency Inversion

**Principle** — high-level policy depends on abstractions it owns; concrete I/O lives at the edge.

**Anti-pattern** (policy reaching for a concrete client):

```pseudo
class PriceSynchronizer:
    private client = new HttpClient("https://analytics.example")
    sync(): this.client.get("/prices")
```

**Canonical refactor** — depend on an owned abstraction, choose the implementation at the composition root:

```pseudo
interface PriceSource: fetch() -> Prices
class PriceSynchronizer(private source: PriceSource):
    sync(): this.source.fetch()
// composition root: new PriceSynchronizer(new HttpPriceSource(client))
```

**Mechanical check** — `CC-10` (concrete network-client instantiation outside the composition root) and `CC-07` (service-locator resolution outside the composition root/presentation layer), both blocking.

## 7. SOLID × Ponytail Balance

**Rule of Two** — the same solution appearing in two or more places is elevated into one shared abstraction in the same change set. Before the second occurrence, duplication is cheaper than the abstraction.

**Single-implementation prohibition** — an interface with exactly one implementation and no mock need is speculation, never design. It is deleted, or it earns its place when a second implementation or a test double appears. An abstraction is earned by a second real implementation, a test seam that must be substituted, or a platform capability wrapped for a downstream host — never by "we might need it later" (`[YAGNI]`). When elevation happens, the shared module documents its ceiling and the evolution trigger that would make it wrong (`// ponytail: ...`).

## 8. Quick Audit Table

| Principle | Self-review question | Automated check |
| :--- | :--- | :--- |
| Single Responsibility | Does this type have more than one reason to change? | sizing gates (`oaef audit`) |
| Open/Closed | Does a new case force edits across existing callers? | review |
| Liskov Substitution | Does every implementation fulfill the full contract? | `CC-09` |
| Interface Segregation | Does any consumer depend on members it never calls? | review |
| Dependency Inversion | Does policy reach a concrete client or the container? | `CC-07`, `CC-10` |
| Rule of Two | Is this abstraction used (or mocked) in fewer than two places? | review, `oaef ponytail audit` |

Identifiers and canonical messages are specified in [`governance_checks.md`](governance_checks.md).

<!-- /oaef:section:standard:solid -->
