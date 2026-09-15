# Event Model slice to Spec Kit mapping

Nemeo uses `em-sdd-bridge@0.5.0` to make a ratified Event Model slice available to Spec Kit. The
bridge is invoked with an explicitly pinned version:

```bash
npx em-sdd-bridge@0.5.0 <slice-key>
```

The bridge owns allocation and rendering. It MUST NOT be run with a slice that has not passed
`em validate --slice-ready`.

## Source of truth

The slice document is the feature specification. In the default bridge mode, `spec.md` is a
rendered projection of that document. In `--symlink` mode, `spec.md` points directly to the slice
document. Neither mode makes `spec.md` independently editable.

Slice documents live at `slices/<slice-key>.md` beside the Event Model and are bound to the model
slice through the model's note path. A slice key is the slug used by the Event Model and bridge.

## Artifact mapping

| Event Model slice section | Spec Kit use |
|---|---|
| Intent | Feature goal and user value |
| Command / Event / Read Model tables | Observable behavior and domain boundary |
| Invariants | Required correctness constraints |
| Scenarios | Acceptance scenarios |
| Alternate & Error Flows | Edge cases and failure behavior |
| Non-Functional Requirements | Quality, security, and operational constraints |
| Open Questions | Clarification gate before planning |

## Workflow

1. Refine the Event Model slice and its document.
2. Run `em validate <model> --slice-ready <slice-key>` and resolve every failure.
3. Run `npx em-sdd-bridge@0.5.0 <slice-key>` to allocate the numbered Spec Kit feature.
4. Review the generated or linked `spec.md`; do not duplicate or rewrite slice requirements.
5. Run the Spec Kit plan, tasks, analysis, and implementation phases.
6. Review the implementation against the slice document, plan, and tasks in the PR.
7. After the PR is merged, run `npx -p em-sdd-bridge@0.5.0 em-sdd-mark-implemented <slice-key> <pr-url>`.

The bridge's design-completeness, events-first, and slice-readiness gates are prerequisites for
implementation. This repository currently declares `contractSource: none` because application
source and generated contracts do not exist yet; that setting skips only TypeSpec checks and does
not bypass the other bridge gates.
