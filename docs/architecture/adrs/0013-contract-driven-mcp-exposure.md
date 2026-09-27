# ADR 0013: Contract-Driven MCP Exposure

- Status: Accepted
- Date: 2026-09-27
- GitHub issue: [#21](https://github.com/jho/nemeo/issues/21)
- Related decisions: [ADR 0004](0004-typespec-fastify-vertical-slice-backend.md), [ADR 0006](0006-application-api-standards.md), [ADR 0012](0012-identity-tenancy-authorization-and-secrets.md)

## Context

MCP is a primary Nemeo client surface for ChatGPT, Claude Desktop, and other agents. It should stay
close to the HTTP API without creating a second hand-maintained contract or exposing every HTTP
endpoint as an agent tool.

## Decision

- TypeSpec remains the source contract. It emits the versioned OpenAPI contract and explicit MCP
  metadata for operations intended for agent use.
- MCP exposure is opt-in through TypeSpec annotations or equivalent contract metadata. Unannotated,
  internal, administrative, web-only, and unsafe operations are not exposed automatically.
- The generation pipeline is:

  ```text
  TypeSpec + MCP metadata
       ├── OpenAPI / HTTP contract
       └── MCP tool definitions and thin adapters
                └── shared vertical-slice application capability
  ```

- Generated MCP definitions reuse operation identifiers, schemas, pagination, and error meanings
  from the API contract. Generated artifacts contain transport mapping and metadata, not business
  logic.
- MCP metadata MUST express at least capability kind (`read`, `suggest`, `classify`, or `execute`),
  audience (`manager` or `viewer`), confirmation requirement, and whether the operation is
  destructive or idempotent. Freshness, pagination, and rate-limit hints are included where the
  operation needs them.
- MCP adapters invoke the shared application capability directly inside the modular monolith. They
  MUST NOT call the local HTTP API over the network or duplicate domain authorization and validation.
- Authentication, household scope, role checks, confirmation, and domain invariants are enforced at
  the application boundary defined by ADR 0012. Tool metadata informs clients but is not a security
  boundary.
- Local and hosted MCP deployments expose the same generated capability model. Only authentication
  and transport adapters may differ.
- MCP read results identify freshness or partial-data state when relevant. Cursor pagination,
  structured errors, retry behavior, and unknown mutation outcomes follow the API contract and the
  jobs/rate-limit decisions in issue [#19](https://github.com/jho/nemeo/issues/19).
- Search and analytics tools remain explicitly allowlisted capabilities governed by ADR 0007; a
  generic query endpoint is not exposed as an unrestricted MCP tool.

## Alternatives considered

### Generic OpenAPI-to-MCP exposure

Rejected as a blanket rule. It could expose internal or dangerous operations and cannot infer the
required audience, confirmation, tenancy, freshness, or financial-safety policy reliably.

### Hand-written parallel MCP API

Rejected. It duplicates schemas and behavior, increases drift, and makes API/MCP consistency harder
to maintain.

### MCP calling the HTTP API internally

Rejected for the modular monolith. It adds needless serialization and network failure modes; both
transports should call the same application capability directly.

## Consequences

Nemeo gets the low-maintenance ergonomics of generated MCP tools while retaining explicit exposure
and safety controls. TypeSpec metadata becomes part of the contract review and compatibility checks,
and the generated MCP surface can stay close to the API without becoming an accidental mirror of it.
