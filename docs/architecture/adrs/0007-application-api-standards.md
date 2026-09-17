# ADR 0007: Application API Standards and Ergonomics

- Status: Accepted
- Date: 2026-09-17
- GitHub issue: [#34](https://github.com/jho/nemeo/issues/34)
- Platform decision: [ADR 0004](0004-typespec-fastify-vertical-slice-backend.md)
- Query-model decision: [ADR 0006](0006-search-and-analytics-query-model.md)
- Topology decision: [ADR 0005](0005-modular-monolith-topology.md)

## Context

Nemeo's application API is the contract between the web client, backend slices, workers, MCP, and
future first-party clients. It should have the predictable, discoverable ergonomics of a mature
resource-oriented API while still representing Event Model commands that are not generic CRUD.

The API must be TypeSpec-first, compatible with the modular monolith, safe for household-scoped
financial data, and suitable for generated clients and contract testing. Search and analytics have
distinct read models and are governed by ADR 0006.

## Decision

### Contract and media type

- TypeSpec is the source of truth. It emits versioned OpenAPI 3.1 artifacts.
- The public API is JSON over HTTPS using `application/json` for successful requests and
  `application/problem+json` for errors.
- Generated OpenAPI and client artifacts are reproducible outputs. They are not hand-edited and do
  not contain business logic.
- The public API is versioned with a path prefix such as `/v1`. Additive compatible changes may be
  released within a version; breaking changes require a new version.

### Resources and commands

- Resource URLs use plural, stable nouns: `/v1/transactions`, `/v1/budgets`, and
  `/v1/connections`.
- Resource retrieval uses standard `GET` operations and returns resource representations directly.
- Collections return a consistent envelope with `data`, cursor metadata, and any relevant summary
  information.
- CRUD operations use conventional REST semantics: `POST` creates a resource, `PATCH` or `PUT`
  updates a resource, and `DELETE` removes a resource. CRUD commands MUST NOT be represented as
  action paths such as `POST /v1/budgets/{budget_id}/update` or
  `POST /v1/budgets/{budget_id}/delete`.
- Non-CRUD Event Model commands use `POST` operations with explicit action paths such as
  `POST /v1/budgets/{budget_id}/approve-targets`.
- Command endpoints return the resulting resource or command outcome. Long-running work returns an
  accepted operation representation that can be queried, rather than hiding asynchronous behavior
  behind a successful synchronous response.
- Public APIs expose capabilities and representations, not internal events, aggregates, repositories,
  or database tables.

### Schemas and identifiers

- IDs are opaque strings and clients MUST NOT infer their structure.
- Timestamps use RFC 3339/ISO 8601 representations with explicit timezone semantics.
- Domain-specific values such as money, percentages, and durations use explicit TypeSpec models and
  units; clients must not infer units from field names alone.
- Request schemas reject unknown or invalid fields unless a TypeSpec model explicitly permits them.
- Response schemas may add nullable or optional fields compatibly, but removing or changing the
  meaning of an existing field is breaking.

### Errors

Errors use Problem Details with stable machine-readable extensions:

```json
{
  "type": "https://api.nemeo.example/problems/invalid-command",
  "title": "The command could not be completed",
  "status": 422,
  "code": "category_confirmation_required",
  "detail": "A category must be confirmed before the transaction can be finalized.",
  "field": "category_id",
  "request_id": "req_01..."
}
```

- `type`, `title`, and `status` follow Problem Details semantics.
- `code` is stable and suitable for programmatic handling.
- `detail` is human-readable and must not be the only source of meaning.
- `field` is included when an error maps to a request field.
- `request_id` is returned on every response and used for support and observability.
- Status codes distinguish validation, authentication, authorization, not-found, conflict,
  dependency, rate-limit, and server failures consistently.

### Pagination, filtering, and sorting

- Cursor pagination is the default for collections and must use a stable explicit ordering.
- Clients may request a bounded `limit`; the server owns maximum page sizes.
- Collection responses expose a continuation cursor rather than requiring clients to construct
  offsets.
- Resource-specific filters and sorts are typed in TypeSpec and validated by the server.
- Search uses the constrained model in ADR 0006. No endpoint accepts raw SQL or arbitrary expression
  evaluation.

### Idempotency and concurrency

- Every state-changing `POST` command accepts an `Idempotency-Key`.
- An idempotency key is scoped to the authenticated principal, endpoint, and request parameters.
- Repeating the same request returns the original outcome; reusing a key with different parameters is
  a conflict.
- Idempotency retention, retry behavior, and worker coordination are refined by issue [#19](https://github.com/jho/nemeo/issues/19).
- Optimistic concurrency is exposed explicitly where a resource can be edited concurrently. Clients
  must not silently overwrite a newer version.

### Authentication and scope

- Every request is evaluated in an authenticated principal and household/tenant scope where the
  resource requires it.
- API handlers MUST enforce authorization before invoking a slice capability.
- The detailed identity, tenancy, secret, and role model remains governed by issue [#20](https://github.com/jho/nemeo/issues/20).

### Contract delivery and testing

- TypeSpec compilation, OpenAPI validation, generated-client type checks, and API contract tests run
  in CI once the application exists.
- Each API operation maps to an Event Model slice or an explicitly documented cross-slice query.
- Frontend, MCP, and integration tests consume the contract or generated client types rather than
  importing backend implementation modules.
- API documentation is generated from TypeSpec/OpenAPI and published with the versioned contract.

Search and analytics remain separate read capabilities under ADR 0006. MCP exposure is curated under
ADR 0004 and issue [#21](https://github.com/jho/nemeo/issues/21); the existence of an API operation
does not automatically make it an MCP tool.

## Alternatives considered

### Pure CRUD REST

Rejected. It would force meaningful Event Model commands into vague updates and obscure business
intent. Resource operations and explicit command actions are both required.

### RPC-only API

Rejected. RPC can model commands well but loses the predictable resource retrieval, collection, and
client ergonomics that are valuable for the web client and future consumers.

### GraphQL or unrestricted query APIs

Deferred. They are not required for MVP and would introduce a second contract and authorization
surface. The constrained search and metric query models leave room to reconsider with evidence.

### Date-based versioning

Rejected for MVP. A path-based major version is easier to understand in TypeSpec, generated clients,
documentation, and deployment routing. The policy can evolve if compatibility needs justify a richer
version scheme.

## Consequences

Nemeo gets a coherent, Stripe-inspired API surface without treating REST as a CRUD-only doctrine.
The API is discoverable for clients, expressive for Event Model commands, safe for financial data,
and friendly to TypeSpec/OpenAPI generation.

The tradeoff is that API design becomes a real contract: changing a schema, error code, pagination
rule, or command semantics requires compatibility review and contract tests. Some details remain
intentionally delegated to identity, jobs, persistence, and MCP decisions.
