# ADR 0006: Application API Standards and Ergonomics

- Status: Accepted
- Date: 2026-09-17
- GitHub issue: [#34](https://github.com/jho/nemeo/issues/34)
- Platform decision: [ADR 0004](0004-typespec-fastify-vertical-slice-backend.md)
- Query-model follow-up: [ADR 0007](0007-search-and-analytics-query-model.md)
- Topology decision: [ADR 0005](0005-modular-monolith-topology.md)

## Context

Nemeo's application API is the contract between the web client, backend slices, workers, MCP, and
future first-party clients. It should have the predictable, discoverable ergonomics of a mature
resource-oriented API while still representing Event Model commands that are not generic CRUD.

The API must be TypeSpec-first, compatible with the modular monolith, safe for household-scoped
financial data, and suitable for generated clients and contract testing. Search and analytics have
distinct read models and are governed by ADR 0007.

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
- URL path segments use lowercase kebab-case. Resource IDs are path parameters, not query
  parameters, when addressing one resource.
- Resource retrieval uses standard `GET` operations and returns resource representations directly.
- CRUD operation selection is fixed:

  | Intent | Method | Example |
  |---|---|---|
  | Create a resource | `POST` collection | `POST /v1/budgets` |
  | Update a resource | `PATCH` member | `PATCH /v1/budgets/{budget_id}` |
  | Delete a resource | `DELETE` member | `DELETE /v1/budgets/{budget_id}` |
  | Retrieve a resource | `GET` member | `GET /v1/budgets/{budget_id}` |
  | List resources | `GET` collection | `GET /v1/budgets` |

- `PATCH` is a typed partial-update request: the body is a TypeSpec model whose optional fields
  represent the fields the client chooses to change. It is not an RFC 6902 JSON Patch operation
  list and it is not a full replacement document.
- A typed `PATCH` request MUST contain at least one changeable field. Unknown fields are rejected.
  Each resource defines the meaning of `null` for nullable fields; omission means “leave unchanged.”
- `PUT` is not part of the normal domain-resource API. It may be introduced only for a resource
  whose semantics genuinely require complete replacement, such as a file or image, and the ADR or
  feature specification MUST document why replacement is safe.
- A slice MUST NOT use `POST` for CRUD updates or deletes.
- Collections return a consistent envelope with `data`, `hasMore`, and an opaque continuation
  cursor. Collection-specific summary fields may be added without changing the envelope.
- CRUD operations use conventional REST semantics: `POST` creates a resource, `PATCH` updates a
  resource, and `DELETE` removes a resource. CRUD commands MUST NOT be represented as
  action paths such as `POST /v1/budgets/{budget_id}/update` or
  `POST /v1/budgets/{budget_id}/delete`.
- Non-CRUD Event Model commands use `POST` operations with explicit action paths such as
  `POST /v1/budgets/{budget_id}/approve-targets`.
- Action names use lowercase kebab-case verbs and describe a business operation, not a persistence
  operation: `approve-targets`, `confirm-category`, and `start-sync` are valid; `update`, `delete`,
  and `save` are not.
- Command endpoints return the resulting resource or a documented command outcome. Long-running work
  returns `202 Accepted` and an operation representation with a status URL; it MUST NOT hide
  asynchronous behavior behind a successful synchronous response.
- Public APIs expose capabilities and representations, not internal events, aggregates, repositories,
  or database tables.

### Request and response conventions

- JSON property names use lower camel case (`budgetId`, `createdAt`, `hasMore`).
- Request and response bodies use explicit TypeSpec models. A response model is not automatically
  the same model as its persistence record or command input.
- Single-resource success responses return the resource representation directly, not `{ "data": ... }`.
- Create responses return `201 Created` and a `Location` header when a resource is created.
- Successful retrieval and synchronous commands return `200 OK`.
- Successful deletes return `204 No Content` unless the operation must return a documented outcome.
- Empty collections return `{ "data": [], "hasMore": false, "nextCursor": null }` rather than
  `404 Not Found`.
- Dates and times use RFC 3339 strings in UTC unless a TypeSpec model explicitly represents a
  calendar-local date. Monetary values use an explicit amount/currency model and never floating
  point JSON numbers.

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
- Status codes use these defaults: `400` malformed request, `401` unauthenticated, `403` not
  authorized, `404` resource absent, `409` state/concurrency/idempotency conflict, `422` valid
  request that violates a domain rule, `429` rate limited, `502`/`503` dependency unavailable, and
  `500` unexpected server failure.
- A handler MUST preserve the stable `code` when the same failure is returned through HTTP, MCP, or a
  worker-facing adapter. Transport-specific status and serialization may differ.

### Pagination, filtering, and sorting

- Cursor pagination is the default for collections and must use a stable explicit ordering.
- Clients may request a bounded `limit` between 1 and 100; the server owns the maximum page size and
  may return fewer items.
- Collection responses use `hasMore` and `nextCursor`. Cursors are opaque and clients MUST NOT parse
  or construct them.
- Offset pagination is not used for user-facing collection APIs.
- Default ordering is newest-first by a stable timestamp plus opaque ID tie-breaker unless a slice
  documents a different business ordering.
- Resource-specific filters and sorts are typed in TypeSpec and validated by the server.
- Search uses the constrained model in ADR 0007. No endpoint accepts raw SQL or arbitrary expression
  evaluation.

### Idempotency and concurrency

- Every state-changing `POST` command accepts an `Idempotency-Key`.
- Resource creation `POST` and non-CRUD action `POST` both accept an `Idempotency-Key`. `GET`,
  `HEAD`, and `DELETE` do not use one. `PATCH` is made safe through resource version or
  conditional-request semantics where concurrent edits matter.
- An idempotency key is scoped to the authenticated principal, endpoint, and request parameters.
- Repeating the same request returns the original outcome; reusing a key with different parameters is
  a conflict.
- The server returns the same status and response body for a replayed completed request.
- Idempotency retention, retry behavior, and worker coordination are refined by issue [#19](https://github.com/jho/nemeo/issues/19).
- Optimistic concurrency is exposed explicitly where a resource can be edited concurrently. Clients
  must not silently overwrite a newer version.

### Authentication and scope

- Every request is evaluated in an authenticated principal and household/tenant scope where the
  resource requires it.
- API handlers MUST enforce authorization before invoking a slice capability.
- The detailed identity, tenancy, secret, and role model remains governed by issue [#20](https://github.com/jho/nemeo/issues/20).

### Contract delivery and testing

- TypeSpec compilation, OpenAPI validation, generated-client type checks, and a breaking-change
  comparison against the previous version run in CI.
- Runtime contract checks are required because TypeSpec cannot prove that manually composed Fastify
  routes implement the emitted contract. For each operation, a focused integration test MUST cover
  route registration, representative valid input, response shape/status, and representative invalid
  input or error behavior. These tests use the generated contract or validator; they do not duplicate
  every TypeSpec field as hand-written assertions.
- Additive versioned changes do not require a new API version, but new operations, fields, or enum
  values require the affected contract and runtime tests to be updated. Breaking changes fail the
  compatibility check or require a new major API version.
- Consumer-driven contract testing across independently deployed clients is deferred until Nemeo
  has external API consumers or independently released services.
- Each API operation maps to an Event Model slice or an explicitly documented cross-slice query.
- Frontend, MCP, and integration tests consume the contract or generated client types rather than
  importing backend implementation modules.
- API documentation is generated from TypeSpec/OpenAPI and published with the versioned contract.

Search and analytics remain separate read capabilities under ADR 0007. MCP exposure is curated under
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
