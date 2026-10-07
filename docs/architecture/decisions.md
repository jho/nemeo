# Nemeo Architecture Decision Backlog

This document separates decisions that belong in product discovery from decisions that belong in
architecture and implementation. ADRs record the latter without silently deciding the former.

## Decision status

- **Open** — requires a decision before dependent work starts.
- **Proposed** — a recommendation exists, but has not been accepted.
- **Accepted** — the team has chosen an option.
- **Superseded** — retained for historical context only.

## Product decisions — do not hide these in ADRs

These need product/design answers first. They are tracked as GitHub issues, not ADRs:

- [#1](https://github.com/jho/nemeo/issues/1) — primary first-run journey from account linking to a useful budget
- [#2](https://github.com/jho/nemeo/issues/2) — pace semantics and ahead-of-pace warnings
- [#3](https://github.com/jho/nemeo/issues/3) — MVP client and mobile scope — resolved: responsive installable PWA first; native wrapper remains optional
- [#4](https://github.com/jho/nemeo/issues/4) — dashboard and review-queue experience
- [#5](https://github.com/jho/nemeo/issues/5) — household roles and permissions
- [#6](https://github.com/jho/nemeo/issues/6) — MCP deployment and agent action policy
- [#7](https://github.com/jho/nemeo/issues/7) — categorization and transfer confidence policy
- [#8](https://github.com/jho/nemeo/issues/8) — AI assistance and autonomy boundaries
- [#9](https://github.com/jho/nemeo/issues/9) — retention, deletion, export, and disconnect behavior
- [#10](https://github.com/jho/nemeo/issues/10) — provider economics and migration policy
- [#11](https://github.com/jho/nemeo/issues/11) — Nemeo visual identity and robot interaction language

## Architecture and implementation decisions

| ADR | Decision | Status | Depends on |
|---|---|---|---|
| [#12](https://github.com/jho/nemeo/issues/12) | SDD workflow and artifact ownership | Accepted | — |
| [#13](https://github.com/jho/nemeo/issues/13) / [ADR 0008](adrs/0008-ui-platform-and-rendering-strategy.md) | UI platform and rendering strategy | Accepted | Product issue #3 |
| [#14](https://github.com/jho/nemeo/issues/14) / [ADR 0009](adrs/0009-ui-component-library-and-design-system.md) | UI component library and design system | Accepted foundation; brand values follow product issue #11 | #13, product issue #11 |
| [#15](https://github.com/jho/nemeo/issues/15) / [ADR 0010](adrs/0010-information-architecture-and-interaction-patterns.md) | Information architecture and interaction model | Accepted | Product issues #2, #4; ADRs 0008, 0009 |
| [#16](https://github.com/jho/nemeo/issues/16) / [ADR 0005](adrs/0005-modular-monolith-topology.md) | Initial modular-monolith application topology | Accepted | #33, #12, #23 |
| [#17](https://github.com/jho/nemeo/issues/17) / [ADR 0011](adrs/0011-domain-persistence-and-event-strategy.md) | Domain persistence and event strategy | Accepted | Event-model slice specs |
| [#18](https://github.com/jho/nemeo/issues/18) / [ADR 0014](adrs/0014-provider-adapter-contract.md) | Provider adapter contract | Accepted | Product issue #10, ADR 0011 |
| [#19](https://github.com/jho/nemeo/issues/19) / [ADR 0015](adrs/0015-postgres-automation-jobs-and-scheduling.md) | PostgreSQL automation jobs, scheduling, retries, and idempotency | Accepted | #17, #18 |
| [#20](https://github.com/jho/nemeo/issues/20) / [ADR 0012](adrs/0012-identity-tenancy-authorization-and-secrets.md) | Identity, tenancy, authorization, sessions, and secrets | Accepted | Product issues #5, #9, #50 |
| [#21](https://github.com/jho/nemeo/issues/21) / [ADR 0013](adrs/0013-contract-driven-mcp-exposure.md) | Contract-driven MCP boundary and agent permissions | Accepted | Product issue #6, #20 |
| [#22](https://github.com/jho/nemeo/issues/22) / [ADR 0016](adrs/0016-ai-decision-boundary-and-provider-abstraction.md) | AI decision boundary and model providers | Accepted | Product issues #7, #8; ADRs 0011, 0013, 0015 |
| [#23](https://github.com/jho/nemeo/issues/23) | Hosting, environments, and operations | Accepted model / Open operations | #12, #17, product issue #9 |
| [#24](https://github.com/jho/nemeo/issues/24) / [ADR 0017](adrs/0017-test-architecture-and-tooling.md) | Test architecture and lightweight tooling | Accepted | #12, #17, #20 |
| [#24](https://github.com/jho/nemeo/issues/24) / [ADR 0018](adrs/0018-domain-correctness-and-replay-verification.md) | Domain correctness and replay verification | Accepted | ADRs 0011, 0015, 0017 |
| [#24](https://github.com/jho/nemeo/issues/24) / [ADR 0019](adrs/0019-ci-quality-gates-and-execution-tiers.md) | CI quality gates and execution tiers | Accepted | ADRs 0001, 0017, 0018 |
| [#25](https://github.com/jho/nemeo/issues/25) | Pull-request and CI workflow | Accepted | #12, #24 |
| [#33](https://github.com/jho/nemeo/issues/33) / [ADR 0004](adrs/0004-typespec-fastify-vertical-slice-backend.md) | MVP backend platform, API-first contracts, and vertical slices | Accepted | #12, #23 |
| [#34](https://github.com/jho/nemeo/issues/34) / [ADR 0006](adrs/0006-application-api-standards.md) | Application API standards and ergonomics | Accepted | #33, #16 |
| [ADR 0007](adrs/0007-search-and-analytics-query-model.md) | Search and analytics query model follow-up | Accepted; depends on API standards | ADR 0006, #17 |

Issue #24 is the umbrella backlog item for these three testing decisions; each focused ADR is
accepted together in the same reviewed change. ADRs are created only after the corresponding
architecture decision is resolved. The `adrs/` directory is reserved for accepted decision records.

## Recommended decision order

1. Product constraints: first-run journey, pace semantics, mobile scope, and data-lifecycle promises.
2. SDD artifact ownership and event-model slicing workflow.
3. Hosting constraints: deployment model, regions, managed services, environments, security, and operational budget.
4. Backend platform and vertical-slice organization.
5. Application topology and module/process boundaries.
6. API contract and rules.
7. UI platform and rendering strategy.
8. Persistence/event strategy and provider contract.
9. Jobs, synchronization, identity, and authorization.
10. UI design system and interaction details.
11. MCP and AI boundaries.
12. Testing and quality gates.

Hosting is intentionally early at the constraints level. Concrete vendor selection should follow
the topology and persistence decisions rather than being deferred until the end.

An ADR may remain Proposed while implementation spikes gather evidence. It becomes Accepted only
after the decision owner approves it and dependent plans reference it.
