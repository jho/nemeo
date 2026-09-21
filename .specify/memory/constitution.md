# Nemeo Constitution

<!--
Sync Impact Report
- Version change: 1.8.0 -> 1.9.0
- Modified principles: Accepted architecture constraints expanded with ADR 0011 persistence rules
- Added sections: selective event sourcing and aggregate repository boundary
- Removed sections: none
- Templates requiring updates: none; existing Constitution Check workflow remains applicable
- Follow-up: detailed retention and deletion behavior remains governed by product issue #9
-->

**Version:** 1.9.0
**Ratified:** 2026-09-14
**Last amended:** 2026-09-21

## Principles

### 1. Product intent remains explicit

The PRD is authoritative for user value, scope, product behavior, and acceptance criteria.
Implementation artifacts MUST NOT silently change product intent. Product changes are recorded in
the PRD through reviewed pull requests.

### 2. Domain behavior is modeled before implementation

The Event Model is authoritative for domain behavior, events, commands, views, translations,
automations, and invariants. Work MUST begin from a ratified Event Model slice when the behavior is
represented there.

### 3. One slice is one implementation unit

Each ratified slice produces one Spec Kit feature, one implementation branch, and one pull request.
The slice document is the feature specification; generated or linked `spec.md` files MUST NOT
become a second source of truth.

### 4. Decisions are separated from delivery artifacts

GitHub issues track unresolved product and architecture decisions. ADRs record accepted architecture
decisions only. `plan.md` records feature-level technical design, and `tasks.md` records executable
implementation work.

### 5. Evidence gates progression

An artifact moves to the next phase only after its required review and validation checks pass.
Automation MUST validate Event Model syntax and slice readiness before allocating implementation
work.

## Accepted architecture constraints

This section is the enforcement-facing summary of accepted architecture decisions. The ADRs contain
the decision context, alternatives, rationale, and consequences; plans and tasks MUST comply with
these constraints.

- Event Model slices are the implementation boundary, and each ratified slice maps to one Spec Kit
  feature, branch, and pull request. See [ADR 0002](../../docs/architecture/adrs/0002-spec-driven-development-workflow.md).
- All changes are delivered through focused pull requests with Markdown, Event Model validation,
  and whitespace checks as the current CI gates. See [ADR 0001](../../docs/architecture/adrs/0001-pull-request-and-ci-workflow.md).
- MVP deployment and integration testing use Docker Compose as the cloud-agnostic service contract;
  cloud-specific deployment adapters are deferred. See [ADR 0003](../../docs/architecture/adrs/0003-compose-first-hosting-model.md).
- MVP backend work uses Node.js 24 LTS with strict TypeScript and Fastify. API
  contracts originate in TypeSpec and emit versioned OpenAPI artifacts; generated API artifacts do
  not own business logic. See [ADR 0004](../../docs/architecture/adrs/0004-typespec-fastify-vertical-slice-backend.md).
- Backend implementation is organized by Event Model-aligned vertical feature slices with distinct
  command and query capabilities. Application command handlers MUST depend on slice-owned,
  aggregate-specific repository ports rather than Emmett, generic event-store APIs, projection
  checkpoints, or database serialization. See [ADR 0004](../../docs/architecture/adrs/0004-typespec-fastify-vertical-slice-backend.md)
  and [ADR 0011](../../docs/architecture/adrs/0011-domain-persistence-and-event-strategy.md).
- Transaction and Budget domain history MUST be immutable, versioned, auditable, and replayable.
  Their current state and query models MUST be derived through idempotent, rebuildable projections.
  Identity, provider operations, sync workflows, household access, and reporting infrastructure
  remain relational unless a later ADR changes that boundary. Emmett MAY implement the event-store
  and projection capabilities behind the aggregate-specific repository boundary, but its command
  handler and types MUST NOT leak into domain or application contracts. See [ADR 0011](../../docs/architecture/adrs/0011-domain-persistence-and-event-strategy.md).
- MCP exposure is a curated capability surface derived from, but not equivalent to, the OpenAPI
  surface. Generated MCP tools MUST NOT bypass authorization, confirmation, or tenancy rules. See
  [ADR 0004](../../docs/architecture/adrs/0004-typespec-fastify-vertical-slice-backend.md) and the
  follow-up MCP decision in issue [#21](https://github.com/jho/nemeo/issues/21).
- MVP uses a conventional modular monolith: one application package, one `nemeo` image, and one
  application process composing web, API, MCP, worker, scheduler, and projection interfaces.
  Modules and entry points MUST preserve future extraction seams, while internal integration uses
  direct application capabilities rather than internal HTTP. See [ADR 0005](../../docs/architecture/adrs/0005-modular-monolith-topology.md).
- Frontend and backend MAY ship in the same repository and deployment unit for slice velocity, but
  the frontend MUST communicate through the generated API contract and MUST NOT depend on backend
  internals or persistence structures. See [ADR 0005](../../docs/architecture/adrs/0005-modular-monolith-topology.md).
- MVP build and test workflows MUST prefer standard Node.js tooling and npm scripts over custom
  orchestration. See [ADR 0005](../../docs/architecture/adrs/0005-modular-monolith-topology.md).
- Event Model bounded contexts MUST remain explicit logical modules even within the MVP monolith.
  Cross-context code MUST use published commands, queries, events, translations, or composition;
  it MUST NOT import another context's internals or access its persistence directly. See
  [ADR 0005](../../docs/architecture/adrs/0005-modular-monolith-topology.md).
- Search and analytics MUST remain separate read capabilities. Search uses allowlisted,
  resource-specific filters or query grammar and MUST NOT expose raw SQL. Analytics uses named
  metrics over Reporting projections with explicit dimensions, units, and time semantics. Both MUST
  be tenant/household scoped and permission checked, and neither may create an alternate command
  path. See [ADR 0007](../../docs/architecture/adrs/0007-search-and-analytics-query-model.md).
- The application API MUST be TypeSpec-first and emit versioned OpenAPI 3.1 artifacts. It MUST use
  predictable resource URLs alongside explicit business command actions, JSON representations,
  Problem Details errors, cursor pagination, bounded filters, explicit idempotency, and path-based
  major versioning. API operations MUST map to slice capabilities and MUST NOT expose persistence
  internals. See [ADR 0006](../../docs/architecture/adrs/0006-application-api-standards.md).
- The MVP client MUST be a responsive React/TypeScript SPA built with Vite and served as static
  assets by the same Fastify application and `nemeo` image. It MUST consume the generated API
  contract rather than backend internals. The client MUST provide installable PWA metadata with
  standalone launch, while offline data access, mutation queues, background sync, push delivery,
  and a separate native client remain out of MVP. See
  [ADR 0008](../../docs/architecture/adrs/0008-ui-platform-and-rendering-strategy.md).
- Shared UI MUST use Nemeo-owned React components built on accessible Radix primitives and styled
  through semantic CSS custom-property tokens with Tailwind CSS. Feature code MUST use the shared
  components and semantic status variants rather than raw colors or third-party primitives. Pace,
  review, error, and insufficient-history states MUST remain understandable without color alone;
  final brand values and robot/AI styling follow product issue [#11](https://github.com/jho/nemeo/issues/11).
  See [ADR 0009](../../docs/architecture/adrs/0009-ui-component-library-and-design-system.md).
- The MVP information architecture MUST be dashboard-first: Dashboard, Budget, Transactions, and
  Connections are the primary capability areas; Review is a secondary, routable workflow. The
  current-month budget status MUST precede pace warnings, and pace warnings MUST lead to contextual
  category and transaction drill-downs. Responsive clients MUST preserve this hierarchy, status
  meaning MUST not depend on color alone, and MVP review MUST remain sequential rather than inventing
  bulk financial mutations. See
  [ADR 0010](../../docs/architecture/adrs/0010-information-architecture-and-interaction-patterns.md).

When a new architecture decision is accepted, its ADR MUST be linked here with the concise rule
that Spec Kit needs to enforce. When an architecture decision is superseded, this section and the
ADR index MUST be updated in the same reviewed change.

## Governance

Amendments require a reviewed pull request linked to the relevant GitHub issue. The PRD, Event
Model, constitution, and ADRs MUST be updated together when an amendment changes their ownership
or constraints. Version changes follow semantic versioning: MAJOR for incompatible governance
changes, MINOR for new principles, and PATCH for clarifications.

The constitution governs SDD artifacts but does not replace product or legal review. When tooling
cannot represent a decision cleanly, the decision remains explicit in the appropriate source
artifact and the workflow is amended through a PR.
