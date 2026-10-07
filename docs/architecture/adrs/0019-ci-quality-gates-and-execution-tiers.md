# ADR 0019: CI Quality Gates and Execution Tiers

- Status: Accepted
- Date: 2026-10-06
- GitHub issue: [#24](https://github.com/jho/nemeo/issues/24)
- Related workflow: [ADR 0001](0001-pull-request-and-ci-workflow.md)
- Related testing: [ADR 0017](0017-test-architecture-and-tooling.md), [ADR 0018](0018-domain-correctness-and-replay-verification.md)

## Context

Nemeo's current CI validates documentation and the Event Model. As implementation begins, the
workflow needs gates that protect the vertical-slice architecture without making every pull request
depend on live financial providers or an unnecessarily large end-to-end suite.

## Decision

CI will use three understandable jobs and two execution tiers. CI uses the repository's supported
Node.js 24 runtime.

### Every pull request

The required PR gates are:

1. **Quality** — pre-commit checks, Markdown lint, Event Model validation, deterministic Event Model
   render verification, TypeScript typecheck/build, and pure tests.
2. **Integration** — a clean Docker Compose PostgreSQL service, migrations, slice-relevant Vitest
   integration tests, projection/replay checks, and narrow provider/API/MCP contract tests.
3. **E2E** — the critical-path Playwright journeys when the affected application surfaces require
   them, beginning with onboarding, connection, sync, budget setup, and dashboard readiness.

No normal PR gate requires live provider credentials or a live financial-data service.

### Main and scheduled execution

Main or scheduled CI runs the broader repository-wide replay/rebuild suite, expanded critical-path
E2E coverage, optional live provider checks when credentials and provider terms permit, and
dependency/security checks. These checks report failures clearly and are not replaced by broad
mocking in the PR suite.

### Local parity

The local commands used by CI MUST be runnable through repository scripts. Developers MAY keep the
Compose test database running for rapid test iteration, while CI always provisions clean state.

## Consequences

The PR path remains fast enough for a solo developer while catching domain/persistence regressions
before merge. Main and scheduled checks provide room for expensive replay, browser, provider, and
security verification. The repository must maintain reliable Compose startup, migration reset, and
test-data isolation commands.

## Alternatives considered

- **One monolithic CI job:** rejected because failures become harder to diagnose and unrelated
  changes wait behind the slowest check.
- **Live provider tests on every PR:** rejected because credentials, availability, rate limits, and
  external data would make the gate nondeterministic.
- **Run every expensive suite on every PR:** rejected for MVP velocity; relevant integration tests
  remain mandatory while broad suites run on main or on a schedule.

