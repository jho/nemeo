# Nemeo Constitution

<!--
Sync Impact Report
- Version change: 2.1.0 -> 2.1.1
- Modified sections: condensed accepted architecture constraints into an ADR enforcement index
- Added sections: none
- Removed sections: duplicated ADR rationale and implementation detail
- Templates requiring updates: none; existing Constitution Check workflow remains applicable
- Follow-up: detailed retention, deletion, export, and legal exceptions remain governed by product issue #9
-->

**Version:** 2.1.1
**Ratified:** 2026-09-14
**Last amended:** 2026-11-02

## Principles

### 1. Product intent remains explicit

The PRD is authoritative for user value, scope, product behavior, and acceptance criteria.
Implementation artifacts MUST NOT silently change product intent. Product changes are recorded in
the PRD through reviewed pull requests.

### 2. Domain behavior is modeled before implementation

The Event Model is authoritative for domain behavior, events, commands, views, translations,
automations, and invariants. Work MUST begin from a ratified Event Model slice when the behavior is
represented there.

### 3. One slice is one implementation boundary

Each Event Model slice has one implementation boundary and one slice PR. A feature batch MAY contain
multiple dependent slices represented by a parent issue, sub-issues, and a short-lived stacked PR
chain. The Event Model and linked slice document are authoritative; generated planning artifacts MUST
NOT become a second source of truth.

### 4. Decisions are separated from delivery artifacts

GitHub issues track unresolved product and architecture decisions. ADRs record accepted architecture
decisions only. Slice documents record implementation-ready design, and issue/PR checklists record
executable delivery work.

### 5. Evidence gates progression

An artifact moves to the next phase only after its required review and validation checks pass.
Automation MUST validate Event Model syntax and slice readiness before allocating implementation
work. For this project, exporting documented MVP slices into the implementation backlog is the
ratification boundary; the backlog handoff MUST record `ratifiedBy` and `ratifiedOn`. Slice PRs
then implement already-ratified slices, and merge MUST NOT be a second ratification gate.

## Accepted architecture constraints

The ADRs are the source of detail. This section lists only the constraints agents must enforce.

- Follow the Event Model and linked slice documents; use `em` for lifecycle, validation, rendering,
  and contracts. See [ADR 0002](../architecture/adrs/0002-event-modeling-delivery-workflow.md).
- Deliver focused PRs and short-lived slice stacks; ratify slices at backlog export. See
  [ADR 0001](../architecture/adrs/0001-pull-request-and-ci-workflow.md) and [ADR 0002](../architecture/adrs/0002-event-modeling-delivery-workflow.md).
- Use Docker Compose as the MVP deployment and integration-test contract. See
  [ADR 0003](../architecture/adrs/0003-compose-first-hosting-model.md) and [ADR 0020](../architecture/adrs/0020-mvp-environment-topology-and-promotion.md).
- Use provider-neutral OpenTelemetry auto-instrumentation, structured redacted telemetry, bounded
  cardinality, and actionable operational alerts. See [ADR 0021](../architecture/adrs/0021-mvp-observability-and-incident-response.md).
- Use Node.js 24 LTS, strict TypeScript, Fastify, TypeSpec, and `em api generate`; generated
  contracts are never hand-edited. See [ADR 0004](../architecture/adrs/0004-typespec-fastify-vertical-slice-backend.md) and [ADR 0006](../architecture/adrs/0006-application-api-standards.md).
- Keep event-sourced transaction/budget history immutable and replayable; keep other domains
  relational unless an ADR changes the boundary. See [ADR 0011](../architecture/adrs/0011-domain-persistence-and-event-strategy.md).
- Generate MCP only from opted-in TypeSpec metadata; reuse API capabilities and enforce the same
  authorization, confirmation, and tenancy rules. See [ADR 0013](../architecture/adrs/0013-contract-driven-mcp-exposure.md).
- Keep Nemeo AI bounded, provider-abstracted, schema-validated, authorized, and free of avoidable
  PII. See [ADR 0016](../architecture/adrs/0016-ai-decision-boundary-and-provider-abstraction.md).
- Keep provider-specific behavior behind the Provider Adapter Contract. See
  [ADR 0014](../architecture/adrs/0014-provider-adapter-contract.md).
- Model automations as coarse, idempotent jobs over projection-backed work views with replaceable
  scheduler, queue, event-publisher, and clock ports. See [ADR 0015](../architecture/adrs/0015-postgres-automation-jobs-and-scheduling.md).
- Use one modular monolith with future extraction seams. Keep business capabilities under
  `src/features/<aggregate-or-context>/<slice>/`; transport belongs under `src/interfaces/`,
  adapters under `src/infrastructure/`, and cross-feature access uses explicit public capabilities.
  See [ADR 0005](../architecture/adrs/0005-modular-monolith-topology.md).
- Keep `iam`, `feeds`, `ledger`, and `budgeting` as explicit Event Model boundaries; cross-context
  code uses published capabilities, not internals. See [ADR 0022](../architecture/adrs/0022-bounded-context-model-and-provider-feed-boundary.md).
- Keep checked-in context and slice SVGs generated by `scripts/render-event-models.sh`; CI checks
  diagram drift. See [ADR 0001](../architecture/adrs/0001-pull-request-and-ci-workflow.md).
- Keep search and analytics as separate, household-scoped read capabilities with no mutation path.
  See [ADR 0007](../architecture/adrs/0007-search-and-analytics-query-model.md).
- Follow [ADR 0006](../architecture/adrs/0006-application-api-standards.md) for API standards.
  Application TypeSpec is authoritative; generated OpenAPI/MCP artifacts are not hand-edited.
- Use a responsive React/Vite SPA, shared accessible UI primitives, semantic design tokens, and the
  generated API contract; preserve the dashboard-first information architecture. See [ADR 0008](../architecture/adrs/0008-ui-platform-and-rendering-strategy.md), [ADR 0009](../architecture/adrs/0009-ui-component-library-and-design-system.md), and [ADR 0010](../architecture/adrs/0010-information-architecture-and-interaction-patterns.md).
- Use integration-first Vitest/PostgreSQL testing, targeted Playwright journeys, and separate PR
  quality, integration, and critical-path E2E gates. See [ADR 0017](../architecture/adrs/0017-test-architecture-and-tooling.md), [ADR 0018](../architecture/adrs/0018-domain-correctness-and-replay-verification.md), and [ADR 0019](../architecture/adrs/0019-ci-quality-gates-and-execution-tiers.md).
- Use Google-first external OIDC, one household per user in MVP, fixed `manager`/`viewer` roles,
  household scoping, secure revocable sessions, and encrypted provider credentials. See [ADR 0012](../architecture/adrs/0012-identity-tenancy-authorization-and-secrets.md).

When a new architecture decision is accepted, its ADR MUST be linked here with the concise rule
that planning and implementation agents need to enforce. When an accepted decision is amended, the
existing ADR MUST be updated in place and this section and the ADR index MUST be updated in the same
reviewed change; use Git history for prior versions rather than creating superseded ADR copies.

## Governance

Amendments require a reviewed pull request linked to the relevant GitHub issue. The PRD, Event
Model, constitution, and ADRs MUST be updated together when an amendment changes their ownership
or constraints. Version changes follow semantic versioning: MAJOR for incompatible governance
changes, MINOR for new principles, and PATCH for clarifications.

The constitution governs Event Model design and delivery artifacts but does not replace product or
legal review. When `em` cannot represent a decision cleanly, the decision remains explicit in the
appropriate source artifact and the workflow is amended through a PR.
