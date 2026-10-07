# ADR 0018: Domain Correctness and Replay Verification

- Status: Accepted
- Date: 2026-10-06
- GitHub issue: [#24](https://github.com/jho/nemeo/issues/24)
- Related persistence: [ADR 0011](0011-domain-persistence-and-event-strategy.md)
- Related automation: [ADR 0015](0015-postgres-automation-jobs-and-scheduling.md)
- Related testing: [ADR 0017](0017-test-architecture-and-tooling.md)

## Context

Nemeo's Event Model and selective event-sourcing strategy make replayability, projection rebuilds,
idempotency, and concurrency important correctness properties. These properties must be tested at
the real PostgreSQL persistence boundary rather than inferred from an in-memory substitute.

## Decision

PostgreSQL-backed integration tests are the canonical confidence layer for domain correctness and
replay behavior.

### Event Model scenarios

Each ratified slice maps its meaningful Given/When/Then scenarios and invariants to tests at the
application capability boundary. Tests should exercise the command or query path and the resulting
domain events, state, and views. Pure tests may cover complicated local decisions, but they do not
replace the slice integration test.

### Persistence and event verification

Relevant integration suites MUST cover:

- aggregate decisions, invariants, and authorization outcomes;
- optimistic concurrency and stream-version conflicts;
- event schema and version evolution;
- projection updates from committed events;
- rebuilding projections from an empty database;
- idempotent replay of the same event history;
- inline versus asynchronous consistency requirements defined by the slice; and
- at-least-once job retry behavior and checkpoint/progress handling.

Event fixtures are reusable deterministic inputs for these tests. They are not a second event-store
implementation and must not become a parallel source of truth.

### Execution tiers

Slice-relevant PostgreSQL integration tests run on every pull request. A broader repository-wide
replay/rebuild suite MAY run on main or on a scheduled cadence when its runtime becomes too costly
for every PR. Tests must remain deterministic and must not depend on Emmett internals; they verify
Nemeo-owned repository, projection, job, and application ports.

## Consequences

The tests validate the persistence architecture Nemeo actually intends to operate, including the
failure modes that motivate selective event sourcing. The tradeoff is a need for fast database
reset/fixture tooling and careful test isolation. In-memory tests remain useful, but only for pure
logic where they add speed or precision without duplicating persistence confidence.
