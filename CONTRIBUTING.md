# Contributing to Nemeo

Nemeo changes are delivered through pull requests. Product decisions, architecture decisions,
event-model changes, documentation, and implementation changes should be reviewable and linked to
the issue they resolve.

## Workflow

1. Start from or create a focused GitHub issue.
2. Create a branch from `main` using a descriptive name such as `issue-25-pr-ci-workflow`.
3. Make the smallest coherent change that resolves the issue.
4. Run the local checks before opening a pull request:

   ```bash
   pre-commit run --all-files
   git diff --check
   ```

5. Open a pull request using the repository template.
6. Include `Fixes #N` when the pull request fully resolves an issue. GitHub closes the issue when
   the pull request is merged.

Pull requests must pass CI before merging. When another contributor is available, changes should
receive at least one independent approval. Until then, the author must perform the review checklist
in the pull-request template and record unresolved risks or follow-up issues.

## Artifact ownership

- The PRD is the source of truth for accepted product behavior and product decisions.
- The Event Model and slice documents describe domain behavior, commands, events, views, and
  invariants.
- Architecture issues hold unresolved technical questions.
- Accepted ADRs record technical decisions after the corresponding architecture issue is resolved.
- Plans and tasks describe the implementation of accepted behavior and decisions.

## Current CI gates

The repository currently has documentation-oriented CI because application code does not exist yet:

- Markdown hygiene and linting through pre-commit.
- Event Model validation through pre-commit.
- Event Model rendering and generated-SVG freshness.
- Git whitespace checks.

As implementation begins, add type-checking, tests, database migration checks, provider contract
tests, security checks, and end-to-end checks through separate focused changes.
