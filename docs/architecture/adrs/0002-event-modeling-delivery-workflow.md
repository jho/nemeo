# ADR 0002: Pure Event Modeling SDLC and Stacked Batch Delivery

- Status: Accepted
- Date: 2026-10-15
- GitHub issue: [#61](https://github.com/jho/nemeo/issues/61)
- Updated in place from: [#12](https://github.com/jho/nemeo/issues/12)

## Context

Nemeo needs a short, repeatable path from product intent to implemented behavior. The Event Model
is the domain design, and `em` already provides the validation, slicing, review, and lifecycle
commands needed to keep that design usable by both humans and agents. A second bridge-owned
specification layer added ceremony and created another place where requirements could drift.

The delivery unit is also larger than one isolated slice in many cases. A feature may require an
Event Model change, several dependent slices, and verification changes that should be reviewed and
delivered as one coherent batch. The workflow must support that without creating a long-lived
feature branch or requiring two merges for every slice.

## Decision

Nemeo uses a pure Event Modeling workflow. The authoritative path is:

```text
product intent → Event Model design → slice documents → implementation plan
→ stacked slice PRs → verification → one stack merge → lifecycle bookkeeping → deployment
```

### Source artifacts

- The PRD and product issues define user value, scope, and acceptance criteria.
- The `.em` model and linked `slices/*.md` documents define domain behavior, scenarios, invariants,
  and slice boundaries.
- `em` is the only required Event Modeling tool. Its validation, export, slice, review, ratify,
  mark-implemented, and conformance commands are the lifecycle interface.
- GitHub parent issues and sub-issues represent a feature batch and its parallelizable slices.
- Backlog items, implementation checklists, and verification tasks are implementation aids. They
  must consume the slice document directly and must not become a second domain specification.
- ADRs and the constitution govern accepted architecture; they do not replace the Event Model or
  PRD.

### Batch and branch workflow

1. A product or architecture decision is resolved in its source artifact.
2. The design work updates the Event Model and slice documents on the bottom branch of a short-
   lived feature batch. The design PR is reviewed as part of the batch; it is not merged alone.
3. The parent issue tracks the batch. Sub-issues identify independently assignable slices or
   verification work and may be planned in parallel.
4. Each implementation PR names its Event Model and slice key, targets the branch below it when
   dependent, and contains the code, tests, and documentation for that slice. A dependent series
   forms a stacked PR chain; independent slices may be sibling PRs in the same batch.
5. Human review and approval of a slice PR is the ratification decision for that slice. There is no
   separate ratification PR or second merge. The complete short-lived stack is merged once the
   design, implementation, and verification layers are acceptable together.
6. After merge, automation or the release operator records the result with `em` lifecycle commands
   such as `em slice ratify --skip-review`, `em slice mark-implemented`, `em slice index`, and
   `em conform-scope`. This bookkeeping is a state update, not a second design review or delivery
   gate.

Stacks must remain small enough to review and merge promptly. If a batch becomes blocked, grows
independent release needs, or requires a long-lived branch, split it into smaller batches and
ratify the resulting Event Model changes through their own short-lived stack.

### Gates and agent responsibilities

- Before planning, run `em validate` and the slice-readiness checks for the candidate slices. Resolve
  model errors, missing scenarios, and open design questions before implementation is allocated.
- Planning agents derive plans and tasks from the Event Model slice documents and linked ADRs; they
  must not invent a parallel domain specification.
- Implementation agents work only from a reviewed slice in the current batch and must preserve the
  slice's command, event, view, translation, automation, invariant, and scenario boundaries.
- CI validates the model and changed slice documents on every relevant PR and runs cumulative tests
  for the stack. Post-merge lifecycle updates are serialized and must not rewrite domain history.
- Verification is part of the batch: tests map to slice scenarios and invariants, with integration
  tests carrying the broadest confidence and critical-path browser checks used selectively.

## Alternatives considered

- **Add a second specification bridge:** rejected because it would add another generated/linked
  specification layer and make the bridge a required dependency for a workflow `em` already supports.
- **Merge a design PR, then merge implementation PRs:** rejected because it creates two review and
  merge events for the same feature and leaves a partially delivered design on `main`.
- **One independent branch and PR per slice from `main`:** retained for genuinely independent work,
  but insufficient for dependent feature batches.
- **One long-lived feature branch:** rejected. Stacks are short-lived and continuously validated;
  a batch must be split when it cannot move promptly.
- **Manual lifecycle updates only:** rejected because mechanical post-merge bookkeeping is safer and
  more consistent when driven by `em`.

## Consequences

The Event Model remains the single domain design surface, and Git history provides prior versions
without maintaining superseded ADR copies. Agents have a direct, inspectable path from a slice to
plans, code, tests, and a PR. Feature batches can be planned in parallel while dependent work keeps
its ordering through stacked branches.

The workflow requires disciplined PR metadata, branch ordering, and post-merge lifecycle updates.
Reviewers must evaluate a stack cumulatively, and CI must distinguish a candidate slice from a
merged implementation. GitHub's parent/sub-issue and stacked-PR capabilities are conventions of
this workflow rather than new application infrastructure.
