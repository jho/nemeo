# Nemeo Spec-Driven Development workflow

Nemeo uses GitHub Spec Kit as the primary SDD workflow, integrated with the Event Model through
`em-sdd-bridge`. Spec Kit provides the phase commands and implementation artifacts; the Event Model
provides the domain behavior and slice boundary.

## Ownership

| Artifact | Authority |
|---|---|
| PRD | Product intent, scope, and user-facing acceptance criteria |
| Event Model (`.em`) | Domain behavior and system flow |
| Slice document | One buildable behavior and its scenarios/invariants |
| `spec.md` | Bridge projection of the slice document; not independently authoritative |
| `plan.md` | Feature-level technical design and implementation approach |
| `tasks.md` | Ordered, verifiable implementation work |
| Constitution | Durable engineering and workflow principles |
| ADR | Accepted architecture decision |
| GitHub issue | Backlog item, unresolved decision, and traceability anchor |
| Pull request | Review and delivery unit |

## Phase flow

```text
PRD → Event Model → ratified slice → bridge → spec.md → plan.md → tasks.md → implementation → PR
```

The normal Spec Kit quality gates are clarification, checklist review, cross-artifact analysis, and
post-implementation convergence. The Event Model gates are model validation and slice readiness.

Accepted architecture choices are recorded in ADRs and summarized as enforceable constraints in
`.specify/memory/constitution.md`. Plans and tasks must follow the constitution summary; consult the
linked ADR when the rationale, alternatives, or consequences are needed.

For every accepted architecture issue, the ADR, constitution constraint, and decision-index status
are updated together. Repository-level agent guidance in [`AGENTS.md`](../AGENTS.md) treats this as
the acceptance checklist for architecture work.

Feature work MUST use the bridge rather than manually creating a parallel `spec.md`. A feature PR
MUST link its GitHub issue, identify affected artifacts, and include verification evidence.
