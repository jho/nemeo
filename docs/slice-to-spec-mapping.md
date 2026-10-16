# Event Model slice to implementation mapping

Nemeo treats the Event Model and linked slice documents as the domain specification. The `em` CLI
is the required tool for validating and managing that specification. There is no bridge-generated
or separately maintained `spec.md`.

## Source of truth

The `.em` model owns the flow and structure. A linked `slices/<slice-key>.md` owns the slice's
intent, command/event/view details, invariants, scenarios, alternate flows, and open questions.
Plans and tasks are derived implementation notes; they must not redefine domain behavior.

## Mapping

| Event Model content | Implementation use |
|---|---|
| Intent and actor | Feature value and capability boundary |
| Command and input fields | Application command contract |
| Event and immutable facts | Domain result and persistence contract |
| View/read model | Query and projection responsibility |
| Invariants | Domain correctness checks |
| Scenarios and alternate flows | Acceptance and integration tests |
| Translation or automation | Adapter, scheduling, and job behavior |
| Open questions | Planning clarification gate |

## Workflow

1. Update the `.em` model and linked slice documents on the design branch.
2. Run the model and readiness checks before allocating implementation:

   ```bash
   em validate budgeting.em
   em validate budgeting.em --slice-ready <slice-key> --json
   ```

3. Create a parent issue for the feature batch and sub-issues for slices or verification work.
4. Derive a plan and tasks directly from each slice document. Spec Kit may be used for this step,
   but it must not create a competing domain specification.
5. Build dependent slices as a short-lived stacked PR chain. Each PR identifies the model and slice
   key and includes the implementation and tests for that slice.
6. Review and approve each slice PR as its ratification decision. Merge the complete stack once the
   design, implementation, and verification layers are coherent together.
7. Record the merged lifecycle state with `em`:

   ```bash
   em slice ratify --skip-review budgeting.em <slice-key>
   em slice mark-implemented budgeting.em <slice-key> <pr-url>
   em slice index budgeting.em
   em conform-scope budgeting.em --repo .
   ```

These post-merge commands are bookkeeping, not a second ratification PR. Use the installed `em
contract` output and `em <command> --help` when a lifecycle command's options vary by version.

## Pull request metadata

Every slice PR should include:

```text
Event Model: budgeting.em
Slice: <slice-key>
Batch: #<parent-issue>
Depends on: <base branch or PR, if stacked>
Verification: <tests and checks>
```
