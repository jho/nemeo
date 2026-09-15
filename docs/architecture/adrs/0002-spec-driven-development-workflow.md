# ADR 0002: Spec-Driven Development Workflow

- Status: Accepted
- Date: 2026-09-14
- GitHub issue: [#12](https://github.com/jho/nemeo/issues/12)

## Context

Nemeo has a PRD and a validated Event Model, but implementation work needs a consistent path from
domain behavior to reviewed code. The workflow must preserve the Event Model as the domain source
of truth without requiring a second manually maintained feature specification.

## Decision

Nemeo adopts GitHub Spec Kit as its primary SDD workflow and uses `em-sdd-bridge@0.5.0` to connect
Event Model slices to Spec Kit features.

One ratified slice produces one Spec Kit feature, one branch, and one pull request. The slice
document is the feature specification. The bridge may render `spec.md` or link it to the slice;
`spec.md` is never independently edited. Spec Kit owns `plan.md`, `tasks.md`, and its quality gates.

The project constitution defines durable workflow and engineering principles. GitHub issues remain
the backlog and decision-tracking mechanism. ADRs record accepted architecture decisions. The PRD
remains authoritative for product intent and acceptance criteria.

Before allocation, the bridge must pass Event Model validation, slice readiness, design-completeness,
and events-first checks. The bridge version is pinned in repository documentation and invoked with
`npx`, avoiding an application dependency before application code exists.

## Consequences

This creates a direct, traceable path from PRD to Event Model slice to implementation PR and avoids
specification drift between slice documents and Spec Kit specs. It adds the operational requirement
that slices be fully documented and ratified before implementation begins. The initial repository
does not yet contain application event types, so the bridge's events-first gate will become active
when the first implementation slice is prepared.

OpenSpec is not adopted initially. It can be reconsidered if Spec Kit or the bridge no longer fits
the repository workflow.
