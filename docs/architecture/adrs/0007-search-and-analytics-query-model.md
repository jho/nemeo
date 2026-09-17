# ADR 0007: Search and Analytics Query Model (API Standards Follow-up)

- Status: Accepted as a follow-up to [ADR 0006](0006-application-api-standards.md)
- Date: 2026-09-16
- GitHub issue: [#34](https://github.com/jho/nemeo/issues/34)
- Parent API decision: [ADR 0006](0006-application-api-standards.md)
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

- MVP search uses typed, resource-specific query parameters over indexed PostgreSQL read models.
  The first consumers are transaction review, categorization review, transfer review, and account
  discovery.
- MVP collection endpoints use explicit filters such as `categoryId`, `accountId`, `from`, `to`,
  `minAmount`, `maxAmount`, and `reviewStatus`. Every filter must be declared in TypeSpec and
  supported by the resource's query handler; unknown filters are rejected.
- The API may add a dedicated search endpoint after MVP, for example
  `GET /v1/transactions/search?q=...`. A search endpoint is resource-specific, read-only, and
  returns the same collection envelope and cursor semantics defined by ADR 0006.
- The future query language uses a deliberately small grammar:

  | Form | Meaning | Example |
  |---|---|---|
  | `field:value` | exact token/string match | `status:"uncategorized"` |
  | `field~value` | allowlisted substring match | `merchant~"coffee"` |
  | `field>value`, `field>=value` | numeric/date comparison | `amount>5000` |
  | `field<value`, `field<=value` | numeric/date comparison | `postedAt<"2026-09-01"` |
  | `-field:value` | negated clause | `-categoryId:"cat_food"` |
  | `A AND B` or `A OR B` | Boolean combination | `status:"open" AND amount>5000` |

- The future grammar supports either `AND` or `OR` in one query, not mixed precedence or arbitrary
  parentheses in the first version. String values require quotes; numeric values may omit them.
- Each resource publishes its searchable fields, field types, allowed operators, and freshness
  behavior. Unsupported operators are validation errors, not silently ignored filters.
- The server parses search text into an internal AST, validates it against the resource allowlist,
  applies tenant/household scope, and only then produces a parameterized query plan. User input is
  never translated directly into SQL.
- Search defaults to stable newest-first ordering by timestamp plus opaque ID tie-breaker. Relevance
  ordering is not assumed unless a resource defines it.
- Search is read-only, always tenant/household scoped, and permission checked.
- Search is not the read-after-write path. Immediate consistency uses the primary query model;
  asynchronously indexed results must expose freshness limitations if introduced.
- MCP receives structured filters or curated search capabilities by default, not unrestricted query
  strings. Natural-language agent requests are translated into the same allowlisted filter/AST
  model, never into raw SQL.

### Analytics

- The Reporting context owns metric definitions, reporting projections, freshness metadata, and
  metric query handlers. Transaction, budget, and pace slices publish the events or state changes
  from which Reporting builds its read models.
- A metric definition includes a stable key, display name, unit, source projection, supported
  dimensions, supported granularities, allowed filters, and freshness expectation. Metric keys are
  versioned when their meaning changes; a renamed display label is not a metric-definition change.
- MVP exposes fixed reporting queries for the user journey, such as:

  - `GET /v1/reports/spending`
  - `GET /v1/reports/budget-progress`
  - `GET /v1/reports/pace`

- MVP reports define their own typed filters and response models in TypeSpec. They do not expose a
  general-purpose metric expression language.
- A future metric query API may use a request such as:

  ```json
  {
    "metrics": ["spend.total", "budget.remaining"],
    "startsAt": "2026-09-01T00:00:00Z",
    "endsAt": "2026-10-01T00:00:00Z",
    "granularity": "week",
    "filters": {"categoryId": ["cat_food"]},
    "groupBy": ["category"]
  }
  ```

- Future metric responses are chart-oriented: they include the metric key, unit, timestamp,
  dimensions, value, and `refreshedAt`. Requested time buckets with no value are returned as zero
  where zero is mathematically meaningful; otherwise the metric definition specifies null behavior.
- Supported granularities are explicitly declared per metric. The API does not silently change a
  requested range or granularity; invalid combinations return a validation error.
- Small, precomputed metric queries may be synchronous. Large exports, arbitrary historical rebuilds,
  and warehouse-style queries are asynchronous jobs and use the jobs decision in issue #19.
- Analytics queries run against Reporting projections or other explicitly defined read models. The
  public API MUST NOT expose raw SQL, arbitrary expression evaluation, or direct event-store scans.
- Analytics capabilities are tenant/household scoped and permission checked. MCP may expose a
  curated subset as named metric tools with explicit descriptions and units.

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
