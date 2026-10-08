# ADR 0020: MVP Environment Topology and Promotion Flow

- Status: Accepted
- Date: 2026-10-08
- GitHub issue: [#30](https://github.com/jho/nemeo/issues/30)
- Related hosting decision: [ADR 0003](0003-compose-first-hosting-model.md)
- Related application topology: [ADR 0005](0005-modular-monolith-topology.md)
- Related quality gates: [ADR 0017](0017-test-architecture-and-tooling.md), [ADR 0019](0019-ci-quality-gates-and-execution-tiers.md)

## Context

ADR 0003 establishes Docker Compose as Nemeo's cloud-agnostic deployment contract, but leaves the
MVP environment and promotion model open. Nemeo needs repeatable local development and CI without
creating a costly or operationally heavy staging system before there is a team or production scale
to justify it.

## Decision

Nemeo will use four logical environment modes with one deliberate omission:

| Environment | Purpose | Data and deployment policy |
|---|---|---|
| Local | Development and agentic integration work | Developer-owned Compose project with isolated volumes and non-production configuration. |
| CI | Pull-request validation | Clean Compose-backed services and disposable data for each relevant job. |
| Preview | On-demand review of `main` | Optional shared preview using the same image and Compose service contract; it is not created for every PR and is not a production-data environment. |
| Production | MVP user service | One small Compose-capable host running the immutable `nemeo` image and PostgreSQL service contract. |

A dedicated staging environment is deferred for MVP. A validated artifact from `main` may be
promoted directly to production. Cloud-vendor-specific deployment definitions remain a later
adapter concern; this ADR does not select a provider.

### Isolation and configuration

Each environment MUST have separate:

- Compose project/service identity and persistent volumes;
- database and application credentials;
- external provider credentials and callback configuration;
- environment-specific secrets and configuration;
- logs, metrics, and operational access.

Production data and credentials MUST NOT be used by local, CI, or preview environments. Configuration
is injected at runtime and MUST NOT be baked into the application image. The image and service
health-check contract remain the same across environments; only configuration, scale, and data
lifecycles differ.

### Promotion and rollback

CI MUST validate the candidate image and relevant Compose-backed checks before it can be promoted.
Promotion uses an immutable image tag or digest; production is not rebuilt from an unpinned source
checkout.

Database migrations MUST be forward-compatible with the application transition in which they are
introduced. A failed deployment first rolls back to the last known-good application image when the
database schema remains compatible. Irreversible schema or data failures use the documented backup
and restore procedure from the follow-up operations decision, rather than pretending that an image
rollback can undo database changes.

Production deployment MUST verify service health and basic readiness before traffic is considered
healthy. The exact host, backup system, alerting system, and recovery objectives are separate
operational decisions.

## Consequences

Local development, CI, preview, and production share one container and service contract, reducing
environment drift and keeping the Compose-first hosting model useful. Direct promotion from `main`
keeps the MVP inexpensive and understandable for a solo maintainer.

The tradeoff is that production initially has a shared host and no independent staging safety net.
Preview environments are intentionally limited and may need manual provisioning. Dedicated staging,
multi-host deployment, provider-specific infrastructure, and automated progressive delivery remain
available later without changing application boundaries.

## Alternatives considered

- **Dedicated staging environment:** deferred for MVP because it adds cost and maintenance without a
  second developer or a release volume that needs it.
- **Ephemeral preview per pull request:** deferred because the solo-developer workflow does not
  justify the infrastructure and data lifecycle overhead; previews remain on-demand.
- **Separate production frontend/backend deployments:** rejected for MVP; the single image and same
  origin preserve the established modular-monolith delivery path.
- **Provider-specific deployment now:** rejected because it would couple the Compose contract to a
  cloud before there is a hosting requirement that warrants it.
