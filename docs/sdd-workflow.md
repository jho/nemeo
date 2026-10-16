# Nemeo Event-Modeled SDLC workflow

Nemeo uses the Event Model and the `em` CLI as the domain design and lifecycle workflow. Planning
tools such as Spec Kit may produce implementation plans and tasks, but they consume slice documents
directly. `em-sdd-bridge` is not part of the workflow.

## Ownership

| Artifact | Authority |
|---|---|
| PRD | Product intent, scope, and user-facing acceptance criteria |
| Event Model (`.em`) | Domain behavior and system flow |
| Slice document | One buildable behavior and its scenarios/invariants |
| Feature batch issue | Parent issue grouping the design, slice, and verification work |
| Slice sub-issue | Assignable unit that maps to an Event Model slice or verification concern |
| `plan.md` / `tasks.md` | Optional implementation planning aids derived from the slice document |
| Constitution | Durable engineering and workflow principles |
| ADR | Accepted architecture decision |
| GitHub issue | Backlog item, unresolved decision, and traceability anchor |
| Pull request | Review and delivery unit |

## Phase flow

```text
PRD → Event Model design → slice documents → plan/tasks → stacked slice PRs
→ verification → one stack merge → em lifecycle update → deployment
```

The design PR is the bottom layer of a short-lived stack and is reviewed as part of the complete
batch. It is not merged independently. Each slice PR names its model and slice key; human approval
of that PR is the slice's ratification boundary. After the stack merges, lifecycle bookkeeping such
as `em slice ratify --skip-review`, `em slice mark-implemented`, `em slice index`, and `em conform-scope` records the
result without creating a second merge.

The normal Spec Kit quality gates are clarification, checklist review, cross-artifact analysis, and
post-implementation convergence. The Event Model gates are model validation and slice readiness.

Local integration tests and agentic development use the repository’s Docker Compose service
contract. Cloud-specific deployment configuration is an adapter and must not become a prerequisite
for feature implementation.

Accepted architecture choices are recorded in ADRs and summarized as enforceable constraints in
`.specify/memory/constitution.md`. Plans and tasks must follow the constitution summary; consult the
linked ADR when the rationale, alternatives, or consequences are needed.

For every accepted architecture issue, the ADR, constitution constraint, and decision-index status
are updated together. Repository-level agent guidance in [`AGENTS.md`](../AGENTS.md) treats this as
the acceptance checklist for architecture work.

Feature work MUST start from a reviewed slice document and MUST NOT create a parallel `spec.md`.
A feature batch SHOULD use a GitHub parent issue with sub-issues, and dependent slice PRs SHOULD
target the branch below them. A feature PR MUST link its issue, identify the Event Model and slice
key, identify its parent/target branch when stacked, and include verification evidence.

## Agentic harness integration

The reusable `jho-ai-toolbox` may provide lifecycle-stage agents and the `slices-to-backlog` skill:

```text
analyze → design → plan → implement → verify → release
```

Nemeo's PRD, ADRs, constitution, Event Model, slice documents, and repository guidance remain the
source of truth. `slices-to-backlog` may inspect the current worktree and emit a planning graph, but
an external Codex/Claude-compatible harness owns parallel execution, worktrees, scheduling, CI
watching, and PR orchestration. Nemeo does not require a particular harness product.
