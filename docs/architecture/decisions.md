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
| [#16](https://github.com/jho/nemeo/issues/16) | Application topology | Open / High | #12, #23 |
| [#17](https://github.com/jho/nemeo/issues/17) | Domain persistence and event strategy | Open / High | Event-model slice specs |
| [#18](https://github.com/jho/nemeo/issues/18) | Provider adapter contract | Open / High | Product issue #10 |
| [#19](https://github.com/jho/nemeo/issues/19) | Jobs, scheduling, retries, and idempotency | Open / High | #17, #18 |
| [#20](https://github.com/jho/nemeo/issues/20) | Identity, tenancy, and authorization | Open / High | Product issues #5, #9 |
| [#21](https://github.com/jho/nemeo/issues/21) | MCP boundary and agent permissions | Open / High | Product issue #6, #20 |
| [#22](https://github.com/jho/nemeo/issues/22) | AI decision boundary and model providers | Open / Medium | Product issues #7, #8 |
| [#23](https://github.com/jho/nemeo/issues/23) | Hosting, environments, and operations | Accepted model / Open operations | #12, #17, product issue #9 |
| [#24](https://github.com/jho/nemeo/issues/24) | Testing and architecture quality gates | Open / High | #12, #17, #20 |
| [#25](https://github.com/jho/nemeo/issues/25) | Pull-request and CI workflow | Accepted | #12, #24 |
| [#33](https://github.com/jho/nemeo/issues/33) / [ADR 0004](adrs/0004-typespec-fastify-vertical-slice-backend.md) | MVP backend platform, API-first contracts, and vertical slices | Accepted | #12, #23 |
| [#16](https://github.com/jho/nemeo/issues/16) / [ADR 0005](adrs/0005-modular-monolith-topology.md) | Initial modular-monolith application topology | Accepted; persistence details remain open | #33, #12, #23 |
| [#34](https://github.com/jho/nemeo/issues/34) / [ADR 0006](adrs/0006-application-api-standards.md) | Application API standards and ergonomics | Accepted | #33, #16 |
| [ADR 0007](adrs/0007-search-and-analytics-query-model.md) | Search and analytics query model follow-up | Accepted; depends on API standards | ADR 0006, #17 |

ADRs are created only after the corresponding architecture issue is resolved. The `adrs/`
directory is reserved for accepted decision records.

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
