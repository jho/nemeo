# ADR 0017: Integration-First Test Architecture and Lightweight Tooling

- Status: Accepted
- Date: 2026-10-06
- GitHub issue: [#24](https://github.com/jho/nemeo/issues/24)
- Related workflow: [ADR 0001](0001-pull-request-and-ci-workflow.md), [ADR 0002](0002-spec-driven-development-workflow.md)

## Context

Nemeo needs confidence across vertical slices without creating a large collection of slow or
duplicative test systems. The most valuable boundary is the domain working with real persistence;
isolated tests remain useful for logic that does not require infrastructure.

## Decision

Nemeo will use a lightweight, integration-first test architecture.

### Test layers

- **Pure tests** cover isolated domain logic, value objects, reducers, and algorithms where the
  behavior is deterministic and infrastructure adds no confidence.
- **Integration tests** are the primary confidence layer. They exercise vertical-slice application
  capabilities together with PostgreSQL repositories, event storage, projections, jobs, and
  relevant adapters.
- **Browser E2E tests** use Playwright only for critical user journeys, beginning with onboarding,
  account connection, initial sync, budget setup, and dashboard readiness.
- **Contract tests** remain narrow and verify only the guarantees of provider, API, and MCP
  boundaries. They do not become a second implementation-specific test suite.

Vitest is the common TypeScript test framework for pure, application, and integration tests.
Playwright is the intentional browser-specific exception.

### Local and CI persistence

PostgreSQL integration tests use the repository's Docker Compose service contract. Developers MAY
keep the test Compose stack running while repeatedly executing the same Vitest integration suite.
CI starts a clean Compose-backed database for each integration job so tests do not depend on prior
local or job state.

### Coverage policy

Nemeo uses scenario- and risk-based coverage rather than a blanket percentage target. Every ratified
slice must have tests for its meaningful scenarios and invariants; additional tests should follow
failure impact and complexity.

## Consequences

The test suite validates more behavior at the domain/persistence boundary with fewer duplicated
assertions. Local iteration remains fast when Compose services stay warm, while CI preserves clean
repeatability. The tradeoff is that integration tests require reliable fixtures, database reset
behavior, and clear ownership of test data.

## Alternatives considered

- **Unit-test-first pyramid:** rejected as the primary strategy because isolated mocks can miss
  persistence, projection, transaction, and serialization behavior.
- **A separate framework per layer:** rejected because it increases tool and maintenance overhead.
- **Full E2E coverage:** rejected for MVP because it is slower and more brittle than boundary-level
  integration tests.
- **Blanket coverage target:** rejected because it rewards line counts rather than meaningful
  behavioral confidence.
