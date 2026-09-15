# Nemeo agent guidance

## Architecture decision changes

When working on an architecture decision issue:

1. Read the issue, relevant product decisions, the Event Model, and existing ADRs first.
2. Do not create an ADR for an unresolved or merely proposed decision.
3. When the decision is accepted, update the ADR with the decision, rationale, alternatives, and
   consequences.
4. In the same change, update `.specify/memory/constitution.md` with the concise normative constraint
   that Spec Kit must enforce during planning and task generation.
5. In the same change, update `docs/architecture/decisions.md` so the issue and ADR status are
   discoverable.
6. Link the ADR from the constitution and link the issue from the ADR.
7. Run the SDD and repository validation checks before opening the PR.

The ADR is the record of what and why. The constitution is the enforcement-facing record of how
future work must comply. Do not copy the full ADR into the constitution, and do not silently resolve
an open product decision as an architecture constraint.

## Feature implementation

Start implementation from a ratified Event Model slice. Use `em-sdd-bridge` to connect the slice
document to Spec Kit rather than creating a parallel hand-written `spec.md`. Follow
[`docs/sdd-workflow.md`](docs/sdd-workflow.md) for artifact ownership and phase gates.
