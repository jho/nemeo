# ADR 0015: PostgreSQL Automation Jobs and Scheduling

- Status: Accepted
- Date: 2026-09-27
- GitHub issue: [#19](https://github.com/jho/nemeo/issues/19)
- Related persistence decision: [ADR 0011](0011-domain-persistence-and-event-strategy.md)
- Related topology decision: [ADR 0005](0005-modular-monolith-topology.md)
- Related provider decision: [ADR 0014](0014-provider-adapter-contract.md)

## Context

Nemeo's Event Model contains scheduled and event-triggered automations for provider sync,
categorization, transfer matching, budget recalculation, pace evaluation, and projections. MVP needs
durable work across restarts and safe retries without adding Redis, Kafka, a hosted queue, or a
second application process.

The queue must remain useful at the automation level. Enqueuing one job per transaction would create
unnecessary operational noise and couple the scheduler to record-level business decisions. Detailed
candidate records belong in projections derived from the Event Model.

## Decision

Nemeo will use a PostgreSQL-backed job queue and an in-process scheduler/worker for MVP. The queue,
scheduler, and application event publisher are application-owned ports with PostgreSQL and local
in-process adapters. The ports preserve a future seam for an external distributed queue and broker.

### Event Model mapping

| Event Model pattern | Runtime mapping |
|---|---|
| State Change | A command capability validates intent and transactionally appends domain events. |
| State View | A projection builds a query or work view, including views of eligible automation work. |
| Automation | An automation reads a work view, claims a bounded batch, and invokes command capabilities. |
| Translation | An adapter translates provider or external data into Nemeo-owned commands or events. |
| Time trigger | The scheduler invokes a named automation when its schedule is due. |

The scheduler triggers an automation; it does not select individual business records or mutate
domain state. The automation reads the relevant projection, selects and claims work, and invokes the
appropriate command capability. Event-triggered and time-triggered paths converge on the same
automation and job-claiming behavior.

### Application-owned ports

- `JobQueue` creates, claims, leases, heartbeats, checkpoints, retries, completes, fails, and
  cancels coarse automation runs.
- `Scheduler` determines when named automations should be invoked and creates or coalesces eligible
  automation runs. It does not contain provider, categorization, budget, or record-selection rules.
- `ApplicationEventPublisher` publishes committed application event envelopes to local subscribers.
  Events carry stable IDs, event type/version, scope, causation/correlation IDs, and occurred-at
  metadata.
- `Clock` supplies time to scheduling, leases, backoff, and tests.

Ports MUST be owned by the application and MUST NOT expose PostgreSQL, queue-library, Redis, Kafka,
or worker-framework types. An automation is an application capability, not a queue adapter.

### MVP job model

Each job represents an automation run, not an individual record. A job contains at least:

- automation type and contract version;
- household and optional connection/account scope;
- a deduplication key and causation/event reference;
- eligibility time, attempt count, lease/heartbeat state, and terminal status;
- optional cursor/checkpoint, batch size, and progress metadata;
- redacted failure classification and operator/user-facing status.

Examples include `sync-provider-connection`, `categorize-uncategorized-transactions`,
`match-transfer-candidates`, `recalculate-budget`, and `evaluate-pace`. The corresponding
automation reads a projection such as `Uncategorized Transactions` or `Transfer Candidate Queue`
and processes a bounded batch. The queue MUST NOT be populated with one task per transaction unless
a later decision establishes a specific need.

Work views are projections, not queue state. They may be rebuilt from domain events, and their
freshness/consistency requirements are explicit in the slice design. A job checkpoint records
automation progress; it is not a replacement for the projection or domain event history.

### Transaction and event semantics

The PostgreSQL adapter MUST use one transaction for a domain state change, its domain event append,
and any known coarse automation-job creation or coalescing required by that change. Application
events are published only after commit. The local adapter MAY stage committed event envelopes in a
PostgreSQL-backed dispatch record before publishing them in-process; this is a local transactional
mechanism, not a requirement to operate an external broker.

If a local notification is missed, a scheduled automation sweep or projection-based reconciliation
MUST be able to recover eligible work. A notification is a trigger or optimization, never the only
durable record of required business work.

Domain events remain the source of financial truth. Job lifecycle changes, lease renewals, retry
attempts, and worker diagnostics are operational records and MUST NOT become financial domain events
unless they represent a meaningful business fact.

### Claiming, leases, and idempotency

Workers claim eligible jobs using a database lease. A worker MUST renew the lease while running and
the job MUST become reclaimable after lease expiry. The system assumes at-least-once execution:
crashes, lease expiry, retries, and duplicate notifications may cause the same automation run to be
attempted more than once.

Every automation and command it invokes MUST be idempotent. Deduplication keys are scoped to the
automation, tenant/resource scope, logical trigger, and relevant contract/version. Repeated provider
pages, event notifications, manual refresh requests, and scheduler ticks MUST coalesce when they
refer to already pending work. Idempotency does not mean that unrelated user actions are silently
merged.

### Retry and failure policy

- Transient infrastructure/provider failures retry with bounded exponential backoff and jitter.
- A provider `retry-after` or equivalent limit takes precedence over the generic backoff.
- Authentication, revocation, invalid request, unsupported capability, and policy failures become
  terminal or paused states requiring user/operator action.
- A partial automation commits successful bounded batches and records the failed scope for retry;
  it does not roll back unrelated successful domain events.
- Exhausted retries become an actionable terminal failure and do not block future scheduled runs.
- Retry policy is centralized in the job adapter/orchestration layer; provider adapters only provide
  capability and retry hints as defined by ADR 0014.

### Cancellation and manual refresh

MVP supports cancellation of queued jobs. Running automations use cooperative cancellation and
bounded provider call timeouts; cancellation does not undo committed domain events. A manual refresh
creates or coalesces a scoped automation run, subject to provider capability and rate-limit policy.
The API/UI reports when a refresh is queued, running, unavailable, or deferred by rate limits.

### Status and observability

Job status is available to operators and, where relevant, users through projections or connection
status views. At minimum the product can show last successful run, current state, partial/failed
scope, next eligible attempt, and required user action. Logs and traces include job, automation,
connection, household, event, and correlation identifiers without provider secrets or financial
payloads beyond the approved redacted metadata.

### Future distributed migration

The MVP does not require an external queue or broker. A future distributed adapter may replace the
local scheduler/worker and in-process event delivery with a transactional outbox and Redis, Kafka,
or another queue/broker. The application contracts remain stable if the distributed implementation
preserves post-commit publication, at-least-once delivery, stable event IDs, scoped ordering where
required, retry behavior, and idempotent job handling.

## Rationale

PostgreSQL provides durable coordination and transaction boundaries without adding infrastructure to
the single-developer MVP. Coarse automation jobs plus projection-backed work views preserve control
over batch size, retries, and selection policy while avoiding a record-per-task queue. The ports keep
the application independent of this deployment choice and make later distribution an adapter and
delivery-semantics migration rather than a rewrite of domain capabilities.

## Alternatives considered

### Redis, Kafka, or a hosted job platform for MVP

Rejected. An external queue adds deployment, operations, local-development, and recovery complexity
before Nemeo needs independent worker scaling.

### One queue task per transaction

Rejected. It pollutes operational state, increases scheduling overhead, and moves business selection
logic into the queue. Automations should read projections and choose bounded batches.

### In-process timers with no durable queue

Rejected. Process restarts could lose work, retries would be ad hoc, and provider rate limits would
be difficult to coordinate.

### Exactly-once execution

Rejected as an infrastructure guarantee. PostgreSQL transactions provide atomic writes, but process
crashes and external provider calls still require at-least-once execution and idempotent handlers.

## Consequences

Nemeo gets durable, inspectable automation work with simple Compose deployment and a clear Event
Model-aligned execution pattern. New automations add a named work view, an automation capability,
job policy, and command/event behavior without changing the queue mechanism.

The tradeoff is that projections, job checkpoints, leases, and idempotency require deliberate
testing. Distributed migration will require an outbox/transport adapter and operational work, but
the domain and automation capabilities do not need to depend on the external queue choice.
