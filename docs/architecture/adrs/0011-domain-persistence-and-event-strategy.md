# ADR 0011: Selective Event Sourcing over PostgreSQL

- Status: Accepted
- Date: 2026-09-21
- GitHub issue: [#17](https://github.com/jho/nemeo/issues/17)
- Related backend decision: [ADR 0004](0004-typespec-fastify-vertical-slice-backend.md)
- Related topology decision: [ADR 0005](0005-modular-monolith-topology.md)

## Context

Nemeo's Event Model describes business behavior as commands, events, views, and processors, but
does not by itself require event sourcing. The persistence strategy must support the product's
need for understandable financial history, explainable automation, and the ability to improve
categorization, budgeting, pace, and reporting logic without losing the original facts or
decisions.

Nemeo is a PostgreSQL-first, Compose-first application. It does not want to introduce a separate
event-specific datastore for MVP. The implementation also needs to preserve the vertical-slice
boundaries and keep the option of replacing event sourcing with conventional relational persistence
if its operational cost is not justified.

## Decision

Nemeo will use selective event sourcing over PostgreSQL for the Transaction and Budget domains.
The event history is the authoritative, immutable record of meaningful domain facts and decisions.
Current state and query models are derived through projections.

### Domain scope

- Transaction streams capture provider import/update facts and meaningful categorization,
  transfer, split, exclusion, and correction decisions. Raw provider payloads are not
  automatically domain events; they are normalized into the Nemeo transaction lifecycle.
- Budget streams capture budget creation, target decisions, caps, protected categories, carryover,
  resets, rebalancing, and taxonomy decisions.
- Identity, provider connections, accounts, sync jobs, household permissions, operational
  metadata, and reporting infrastructure remain conventional relational state or derived views.
- Pace calculations, dashboard summaries, analytics, notifications, and review queues are
  projections, not additional event-sourced aggregates.

### Application and persistence boundaries

Application command handlers MUST depend on aggregate-specific repository ports owned by their
vertical slice, such as `TransactionRepository` or `BudgetRepository`. They MUST NOT depend
directly on Emmett, a generic event-store API, projection checkpoints, or database serialization.

The repository implementation may be event-sourced or conventional relational persistence:

```text
TransactionRepository
  ├── EventSourcedTransactionRepository
  │     └── PostgreSQL event store / Emmett adapter
  └── RelationalTransactionRepository
        └── current-state tables plus optional audit history
```

The domain remains pure and expresses behavior through decisions and state evolution. Emmett's
`CommandHandler` is optional infrastructure convenience and is not part of Nemeo's application
or domain contracts.

### Infrastructure capabilities

The event-sourcing infrastructure uses two conceptual, application-owned capabilities:

1. `EventStore` loads an aggregate stream and appends events with optimistic concurrency.
2. `ProjectionRunner` consumes or replays events, invokes projection handlers, tracks progress,
   and rebuilds projections.

These capabilities MUST remain below the aggregate-specific repository boundary and MUST NOT
mirror the complete API of a selected event-sourcing library. Emmett may implement them directly
inside the infrastructure adapter.

### Projection consistency

Projection tables live in PostgreSQL and every projection MUST be idempotent and rebuildable.

- Inline projections MAY update critical current-state models in the same PostgreSQL transaction
  as the event append when immediate consistency is required.
- Async projections MAY commit events first and update derived or analytical views through a
  background consumer when brief lag is acceptable.
- Any consistency requirement for a user-visible command MUST be explicit in the slice design.

### Event history and replay

Events MUST preserve sufficient metadata for auditability, explainability, and deterministic
replay, including stable aggregate identifiers, stream versions, event types and schema versions,
timestamps, actor or source information, causation/correlation identifiers, and relevant provider
identifiers.

Improved categorization models, budget rules, pace algorithms, or reporting logic MUST produce new
suggestions, decisions, or projection versions. They MUST NOT silently rewrite historical facts or
user decisions.

Event payload design and deletion behavior MUST comply with the retention and deletion decision in
[product issue #9](https://github.com/jho/nemeo/issues/9). This ADR does not pre-decide the legal
retention period or erasure implementation.

## Rationale

The decision combines two related benefits:

1. **Auditability and explainability.** Nemeo can show what the provider supplied, what automation
   proposed, what a user confirmed or corrected, and how budget decisions changed over time.
2. **Replayability and rebuildability.** Nemeo can reprocess historical transactions, test new
   algorithms against real behavior, rebuild projections after logic changes, and recover derived
   state without treating read models as authoritative.

Either benefit alone could be addressed with conventional audit tables. Together they justify an
authoritative, structured event history for the Transaction and Budget domains.

## Alternatives considered

### Conventional relational state with audit tables

Rejected as the primary MVP strategy for Transaction and Budget. It would provide a simpler
operational model and can preserve useful history, but replay would depend on an audit schema being
complete enough to reconstruct every business transition. It remains a supported replacement
strategy behind the aggregate-specific repository ports.

### Full event sourcing for every domain

Rejected. Identity, provider operations, sync workflows, access control, and reporting do not
derive enough value from replayable aggregate history to justify the additional complexity.

### KurrentDB or another external event store

Rejected for MVP. Nemeo's PostgreSQL-first and no-external-datastore constraint is more important
than adopting an event-specific database.

### NestJS CQRS

Rejected as the persistence or command architecture. `@nestjs/cqrs` could provide framework
conveniences in a Nest application, but Nemeo uses Fastify and vertical-slice application
capabilities. CQRS behavior will remain explicit in Nemeo-owned code.

### Emmett as a direct application dependency

Rejected. Emmett remains a candidate PostgreSQL implementation adapter, but its types and command
handler abstractions must not leak into domain or application contracts. This preserves a path to a
direct PostgreSQL implementation or conventional relational persistence if licensing, maturity,
or operational fit changes.

## Consequences

Nemeo gains a durable source of domain history for the two areas where user trust, correction, and
algorithmic improvement matter most. Transaction, budget, and projection tests must cover event
evolution, optimistic concurrency, schema evolution, replay, idempotence, and rebuild behavior.

The tradeoff is more implementation and operational discipline: event schemas require versioning,
projections require checkpoints and rebuild procedures, and sensitive data in immutable history
requires an explicit deletion strategy. Those concerns are constrained to the selected domains
rather than imposed on the whole application.
