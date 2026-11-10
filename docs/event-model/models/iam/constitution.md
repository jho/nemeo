---
schemaVersion: 1
ratifiedBy: jho
ratifiedOn: 2026-11-09
---

IAM implementation constitution
================================

This model follows the repository constitution in `docs/event-model/constitution.md` and the
architecture decisions it indexes. These rules are the implementation defaults for IAM slices.

Stack and architecture
----------------------

- Use strict TypeScript on Node.js with Fastify, TypeSpec, PostgreSQL, and the repository's
  event-storage and projection ports.
- Implement each slice under `src/features/iam/<slice>/`. Keep HTTP registration in
  `src/interfaces/` and replaceable adapters in `src/infrastructure/`.
- Preserve the Event Model pattern and slice boundary in code. Do not introduce a broader context
  hierarchy or infrastructure dependency without an accepted ADR.
- Follow the API standards ADR for plural resource routes, UUID identifiers, explicit enums,
  standard REST semantics, and documented command endpoints only where a resource operation cannot
  be represented as a resource change.
- Treat generated Event Model contracts and generated OpenAPI outputs as read-only. Change the
  model or TypeSpec source and regenerate.

Slice routing
-------------

| Pattern | Implementation default |
| --- | --- |
| State Change | Command handler, domain decision, event persistence, and projection update |
| State View | Read handler over a projection; no domain mutation |
| Automation | Application event or scheduler trigger dispatching a coarse-grained job |
| Translation | External provider input translated into domain commands or events at the boundary |

Code and testing
----------------

- Keep business rules in the feature; transport and provider details stay behind ports.
- Use the repository formatter, linter, and type checks. Do not hand-edit generated artifacts.
- Prefer integration tests for feature behavior across handlers, persistence, and projections;
  use unit tests for focused domain rules and algorithms. Reserve end-to-end tests for critical
  user paths.
- Test names and comments should cite the invariant or scenario identifier from the slice doc.
- **Test command:** `npm run test:unit && npm run test:integration`

Security and operations
-----------------------

- Authenticate at the interface boundary and enforce household access before executing a slice.
- Do not log provider tokens, secrets, or unnecessary personal or financial data.
- Use structured logs with the repository logging component convention and propagate trace context.

Review and merge
----------------

- A slice PR implements the reviewed, ratified slice and is the lifecycle boundary for that slice.
- Failing validation, contract drift, missing invariant coverage, or an unresolved model question
  blocks merge.
- At merge, record implementation with `em slice mark-implemented <model>.em <slice-key> <pr-url>`.
- **Agent models:** implementer=sonnet, validator=sonnet, reviewer=sonnet, critic=opus
