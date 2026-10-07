# ADR 0001: Pull-Request and CI Workflow

- Status: Accepted
- Date: 2026-09-09
- GitHub issue: [#25](https://github.com/jho/nemeo/issues/25)

## Context

Nemeo currently contains a PRD, Event Model, and decision backlogs but no application code. The
repository needs a lightweight review path now without pretending that code, database, or runtime
quality gates already exist.

## Decision

All changes are delivered through focused pull requests from branches based on `main`. Product
issues are linked with GitHub closing keywords and, when resolved, update the PRD. Architecture
issues are resolved before accepted ADRs are written. Event Model changes are validated in CI.

The initial CI workflow runs:

- pre-commit Markdown hygiene and linting;
- Event Model validation for `budgeting.em`;
- Git whitespace checks.

The pull-request template requires the author to identify product, Event Model, architecture,
verification, and documentation impact.

## Consequences

This gives the documentation-first repository a reviewable workflow with low setup cost. It does
not yet provide type-checking, application tests, migration checks, provider contract tests,
security scanning, or end-to-end tests; those become required as implementation is introduced.

The workflow currently uses pinned action and hook revisions where practical. Application test and
CI execution tiers are defined by the follow-up [ADR 0019](0019-ci-quality-gates-and-execution-tiers.md).

## Rejected alternatives

- Direct commits to `main`: rejected because product and architecture decisions need review.
- Full application CI now: rejected because there is no application runtime or database yet.
- Creating ADRs for unresolved questions: rejected because ADRs record accepted decisions.
