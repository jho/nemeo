# ADR 0006: Constrained Search and Metric-Oriented Analytics

- Status: Accepted for query-model direction
- Date: 2026-09-16
- GitHub issue: [#34](https://github.com/jho/nemeo/issues/34)
- Related Event Model context: Reporting
- Related persistence decision: [#17](https://github.com/jho/nemeo/issues/17)

## Context

Nemeo needs useful transaction search and budget reporting without turning the public API into a
raw database query surface. The Event Model includes a Reporting context for budget progress and
pace warnings, and future MCP clients will need safe access to both individual records and metrics.

Stripe's API demonstrates two useful but distinct patterns: a constrained search language over
resources, and a metric-oriented analytics API with named metrics, dimensions, time ranges, and
time-series responses. Nemeo can preserve those ergonomics without adopting Stripe's domain model
or implementing the full feature set for MVP.

## Decision

Search and analytics are separate read capabilities.

### Search

- MVP search begins with typed, resource-specific filters, indexed PostgreSQL queries, and stable
  cursor pagination.
- The API MAY later expose a resource-specific search endpoint such as
  `GET /v1/transactions/search?q=...`.
- A search language MUST be field-allowlisted and compiled into an internal query representation.
  It MUST never be translated from user input directly into SQL.
- Search is read-only, always tenant/household scoped, and permission checked.
- Search is not the read-after-write path. Immediate consistency uses the primary query model;
  asynchronously indexed search results must expose their freshness limitations if introduced.
- MCP receives structured filters or curated search capabilities by default, not unrestricted query
  strings.

### Analytics

- The Reporting context owns metric definitions, reporting projections, and metric query handlers.
- Metrics have stable names, explicit units, supported dimensions, time ranges, and granularities.
- Analytics responses are time-series oriented and include timestamps, dimensions, values, and
  explicit handling for empty time buckets.
- MVP exposes fixed reporting queries for core use cases such as spending, budget progress, and
  pace. A general metric-query endpoint is deferred until real reporting use cases justify it.
- Analytics queries run against reporting projections or other explicitly defined read models. The
  public API MUST NOT expose raw SQL or arbitrary expression evaluation.
- Analytics capabilities are tenant/household scoped and permission checked. MCP may expose a
  curated subset as named metric tools.

Search and analytics do not create alternate command paths. Commands continue to flow through the
Event Model slice capabilities, while events feed the read models used by search and reporting.

## Alternatives considered

### One generic query language for every endpoint

Rejected. It would increase ambiguity, security risk, testing cost, and coupling between clients
and storage. Search grammars should be specific to the resource being searched.

### Raw SQL or arbitrary expressions in the API

Rejected. This would expose persistence details, complicate authorization and tenant isolation, and
make future storage changes unnecessarily expensive.

### Full analytics query API for MVP

Deferred. Named metrics and dimensional time series are a useful long-term model, but fixed
Reporting queries are sufficient until the product has learned which metrics users actually need.

### Treat analytics as queries over the event store

Rejected as the default. Reporting projections provide a stable read boundary and avoid coupling
interactive dashboards to event-store layout or replay costs. The persistence decision may refine
how those projections are built.

## Consequences

The API can provide Stripe-like discoverability and ergonomics while keeping query power bounded
and safe. The architecture supports simple indexed PostgreSQL queries now and a richer search
language or metric API later without making either one a prerequisite for MVP.

The Reporting context becomes an explicit owner of derived metrics. This creates projection and
freshness concerns that belong in the persistence, jobs, and testing decisions, but it keeps those
concerns out of command handlers and transport-specific code.

