# Nemeo Constitution

**Version:** 1.1.0
**Ratified:** 2026-09-14
**Last amended:** 2026-09-16

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
  command and query capabilities. Slices may use direct PostgreSQL CQRS or Emmett behind a
  persistence boundary; event sourcing is not implied. See [ADR 0004](../../docs/architecture/adrs/0004-typespec-fastify-vertical-slice-backend.md).
- MCP exposure is a curated capability surface derived from, but not equivalent to, the OpenAPI
  surface. Generated MCP tools MUST NOT bypass authorization, confirmation, or tenancy rules. See
  [ADR 0004](../../docs/architecture/adrs/0004-typespec-fastify-vertical-slice-backend.md) and the
  follow-up MCP decision in issue [#21](https://github.com/jho/nemeo/issues/21).

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
