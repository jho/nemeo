# ADR 0004: TypeSpec-First Fastify Backend with Vertical Feature Slices

- Status: Accepted
- Date: 2026-09-16
- GitHub issue: [#33](https://github.com/jho/nemeo/issues/33)
- Related API issue: [#34](https://github.com/jho/nemeo/issues/34)
- Related persistence issue: [#17](https://github.com/jho/nemeo/issues/17)

## Context

Nemeo needs a backend platform that supports the Event Model, TypeSpec-first API design, MCP,
provider integrations, scheduled work, PostgreSQL, and the Compose-first hosting contract. The
backend should allow the implementation to follow Event Model slices without forcing a distributed
system or an event-sourcing decision before the persistence decision is complete.

The API is intended to be designed contract-first. The same contract should support the web client,
documentation, validation, generated clients, and an MCP integration. The application code should
be organized around business capabilities and user-visible behaviors rather than technical layers.

## Decision

Nemeo's MVP backend platform is Node.js with TypeScript and Fastify.

- The supported runtime line is Node.js 24 LTS. The repository MUST pin the concrete major version
  in its toolchain and container configuration.
- TypeScript MUST use strict type checking and ESM modules.
- Fastify is the HTTP runtime and transport adapter. HTTP concerns such as routing, authentication
  hooks, serialization, and error translation MUST remain at the edge of the application.
- TypeSpec is the API-first source of truth. TypeSpec MUST emit the versioned OpenAPI contract;
  handwritten OpenAPI is not a parallel source of truth.
- The OpenAPI contract MAY generate validation, documentation, client types, and MCP scaffolding.
  Generated artifacts MUST be reproducible and MUST NOT contain business logic.
- MCP capabilities MUST be curated from the contract and application capabilities. A generic
  endpoint-to-tool generator MUST NOT automatically expose every API operation or bypass the
  authorization, confirmation, and tenancy rules defined by the MCP boundary decision.
- Backend code MUST be organized by vertical feature slice. A slice groups the behavior's transport
  mapping, command or query handler, domain rules, persistence interaction, and tests. Shared code
  is allowed when it represents a proven cross-slice concern; vertical slicing does not require
  duplicated code or a separate database per slice.
- Commands and queries MUST remain distinct at the application boundary. CQRS is an organizational
  and behavioral separation, not a requirement for separate databases, asynchronous messaging, or
  event sourcing.
- API, worker, scheduled-command, and MCP entry points SHOULD reuse the same slice application
  capabilities rather than calling one another over HTTP inside the Compose deployment.
- Emmett MAY be used behind a slice-level persistence boundary. Direct CQRS over PostgreSQL is also
  valid for MVP slices. Adoption of Emmett, event sourcing, event-store schemas, projections, and
  consistency choices remains the subject of [issue #17](https://github.com/jho/nemeo/issues/17).

## Alternatives considered

### Node.js with TypeScript and Fastify

Selected. It keeps the API, MCP, worker, and tooling ecosystem in one language, supports TypeSpec's
OpenAPI workflow, works with Docker Compose, and has a direct Fastify integration available for
Emmett if the persistence decision adopts it.

### Node.js with TypeScript and Express

Rejected for the MVP baseline. It is viable and has an Emmett integration, but Fastify provides a
better fit for schema-aware HTTP boundaries and the desired lightweight transport layer.

### Kotlin/JVM or another backend language

Rejected for now. It would be a valid future implementation target, but it adds a second toolchain
without a current product or Event Model requirement. TypeSpec and OpenAPI preserve a migration path
if that tradeoff changes later.

### Generate the entire server from TypeSpec

Rejected as the primary implementation model. TypeSpec remains authoritative for the API contract,
but generated server scaffolding must not dictate vertical-slice boundaries or own business logic.

### Generic OpenAPI-to-MCP exposure

Rejected as the complete MCP design. It may be used for scaffolding or low-risk read operations,
but Nemeo's agent tools require explicit capability selection, authorization, confirmation, and
tenancy handling.

## Consequences

This gives Nemeo one primary backend language and a clear contract pipeline:

```text
TypeSpec -> OpenAPI -> Fastify boundary -> vertical slice capability
                         └-------------> curated MCP capability
```

The architecture can begin with simple PostgreSQL-backed command and query handlers and introduce
Emmett selectively where event sourcing, projections, or workflow support provide enough value.
The tradeoff is that the repository must maintain TypeSpec compilation, generated-artifact checks,
Fastify integration conventions, and explicit MCP curation. Runtime process boundaries, API policy
details, and the final persistence strategy remain separate decisions.
