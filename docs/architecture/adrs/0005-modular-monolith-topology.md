# ADR 0005: Conventional Modular Monolith Topology

- Status: Accepted
- Date: 2026-09-16
- GitHub issue: [#16](https://github.com/jho/nemeo/issues/16)
- Related API decision: [ADR 0004](0004-typespec-fastify-vertical-slice-backend.md)
- Related operations decision: [#19](https://github.com/jho/nemeo/issues/19)

## Context

Nemeo is being built by a single developer and an agent. MVP priorities are simplicity, delivery
speed, and rapid vertical-slice iteration rather than independent service scalability. The system
still needs distinct API, web, MCP, worker, scheduler, and projection responsibilities, but those
responsibilities do not yet justify separate deployments.

The Compose-first hosting model provides a low-cost container contract. The backend platform is
Node.js/TypeScript with Fastify, TypeSpec-first API contracts, and Event Model-aligned vertical
slices. The topology must preserve those boundaries without introducing a custom build system,
service framework, or process supervisor.

## Decision

Nemeo will use a conventional modular monolith for MVP.

- The repository will contain one application package and one standard Node.js toolchain.
- The MVP will produce one `nemeo` Docker image and run one application container/process.
- The application process will compose the web UI, Fastify API, MCP endpoint, worker/scheduler, and
  projections as separate internal interfaces and modules.
- Each interface will have a clear entry module so it can become a separate process or image later.
- Vertical slices remain the primary organization. A slice owns its user-facing behavior, command or
  query capability, domain rules, persistence port, transport mappings, and tests.
- Event Model bounded contexts remain explicit logical modules within the monolith. A context may
  contain multiple slices, but slices in other contexts MUST use its published commands, queries,
  or events rather than importing its internal handlers, domain objects, or persistence code.
- Contexts MUST access persistence through their own ports and adapters. A context MUST NOT reach
  directly into another context's tables or repositories. Shared read models and cross-context
  workflows use explicit projections, translations, or application composition.
- Shared code is limited to proven platform or cross-cutting primitives. Domain models, policies,
  and repositories are not placed in a global shared layer merely to make imports convenient.
- The frontend and backend remain in the same repository and deployment unit for fast slice delivery,
  but the frontend communicates through the generated API contract. It must not depend directly on
  backend internals or persistence structures.
- API, MCP, worker, scheduler, and projection modules will reuse application capabilities through
  direct in-process calls. They will not call one another through internal HTTP during MVP.
- Standard tooling is preferred: npm scripts, TypeScript/`tsc`, Fastify, TypeSpec CLI, Node's test
  runner, ESLint, Prettier, and Docker. Nx, Turborepo, a custom service framework, a message broker,
  and a process supervisor are deferred.
- The topology must not assume that workers are safe to duplicate. Leases, retries, scheduling,
  and idempotency are defined separately in [issue #19](https://github.com/jho/nemeo/issues/19).

## Future extraction seams

The following logical entry points must remain identifiable within the single application:

```text
src/interfaces/http/main.ts
src/interfaces/mcp/main.ts
src/interfaces/worker/main.ts
src/interfaces/web/main.ts
```

They may initially be composed by `src/main.ts`. Domain contexts should have the same kind of
logical seam, for example:

```text
src/contexts/transactions/
src/contexts/budget/
src/contexts/connections/
```

A later deployment may run interface entry points or domain contexts as separate processes from the
same image, separate images, or independently deployed services. Such an extraction requires
explicit operational and data-boundary decisions; it is not implied by this ADR.

## Alternatives considered

### Independently deployed microservices

Rejected for MVP. They add deployment, networking, observability, data ownership, and coordination
cost before Nemeo has the scale or team structure to justify it.

### Multiple processes in one container

Rejected for the default MVP deployment. It complicates signals, logs, health checks, and local
development. The code will preserve entry-point seams without requiring a process supervisor.

### Separate frontend and backend deployments

Rejected for MVP delivery. Keeping them together shortens vertical-slice feedback loops. The API
contract remains the boundary so the deployment choice does not become code-level coupling.

### Custom monorepo/task orchestration

Rejected for MVP. A single package and ordinary npm scripts are sufficient until the repository has
multiple independently released packages.

## Consequences

MVP development and Compose-based integration testing remain simple: one application image, one
application process, and PostgreSQL as the separate stateful service. A feature can move through
TypeSpec, frontend, Fastify, domain behavior, worker behavior, and tests in one focused slice.
Logical context boundaries prevent the monolith from becoming a shared-layer application while
preserving the option to extract a high-value domain later.

The tradeoff is shared failure and resource boundaries. A worker failure can affect the application
process, and web/API/worker workloads cannot scale independently. Those are acceptable MVP costs;
the explicit module and entry-point boundaries preserve a path to extraction when operational
triggers make it worthwhile.
