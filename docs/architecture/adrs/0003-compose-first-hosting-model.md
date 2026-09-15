# ADR 0003: Compose-First Hosting Model

- Status: Accepted for MVP hosting model; operational details remain open
- Date: 2026-09-15
- GitHub issue: [#23](https://github.com/jho/nemeo/issues/23)

## Context

Nemeo needs a low-cost deployment model that is easy to run locally, supports integration testing,
and does not force an early commitment to a cloud provider or Kubernetes. The application will have
financial-data persistence, scheduled provider work, and potentially separate web and worker
processes, so the local deployment model must be useful beyond a single-process demo.

## Decision

Docker Compose is the MVP deployment contract. Nemeo must be runnable from a repository-provided
Compose configuration with documented environment variables and persistent service boundaries.
The same Compose setup is the default environment for local integration testing, CI integration
tests, and agentic development workflows that need to exercise real service boundaries.

Nemeo will not depend on a cloud provider, Kubernetes, or a cloud-specific orchestration format for
MVP development or local operation. Cloud deployment is a later adapter concern and must preserve
the container image, configuration contract, health checks, database connection contract, and
worker/job entry points established by Compose.

When cloud hosting is justified, the initial migration targets are:

- AWS: a small EC2 VM running Compose for maximum parity, or ECS/Fargate for managed container
  scheduling when the operational tradeoff is justified.
- Google Cloud: a small Compute Engine VM running Compose for maximum parity, or Cloud Run for the
  web workload and Cloud Run Jobs or another managed scheduler for finite background work.

Azure is not an initial target. Kubernetes is explicitly deferred.

## Consequences

This minimizes MVP hosting cost and keeps development, CI, and self-hosting aligned. Compose also
gives integration tests and agents a repeatable multi-service environment. The tradeoff is that
production operations initially remain the team’s responsibility, including updates, backups,
secrets, monitoring, and scheduling. The exact environment promotion model, operational objectives,
and managed-service choices remain open in issue #23.

Compose files must not encode provider-specific assumptions. Persistent data must use explicit
volumes or external services, and cloud deployment adapters may translate the same service contracts
into provider-specific definitions when needed.
