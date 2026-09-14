# Nemeo Constitution

**Version:** 1.0.0  
**Ratified:** 2026-09-14  
**Last amended:** 2026-09-14

## Principles

### 1. Product intent remains explicit

The PRD is authoritative for user value, scope, product behavior, and acceptance criteria.
Implementation artifacts MUST NOT silently change product intent. Product changes are recorded in
the PRD through reviewed pull requests.

### 2. Domain behavior is modeled before implementation

The Event Model is authoritative for domain behavior, events, commands, views, translations,
automations, and invariants. Work MUST begin from a ratified Event Model slice when the behavior is
represented there.

### 3. One slice is one implementation unit

Each ratified slice produces one Spec Kit feature, one implementation branch, and one pull request.
The slice document is the feature specification; generated or linked `spec.md` files MUST NOT
become a second source of truth.

### 4. Decisions are separated from delivery artifacts

GitHub issues track unresolved product and architecture decisions. ADRs record accepted architecture
decisions only. `plan.md` records feature-level technical design, and `tasks.md` records executable
implementation work.

### 5. Evidence gates progression

An artifact moves to the next phase only after its required review and validation checks pass.
Automation MUST validate Event Model syntax and slice readiness before allocating implementation
work.

## Governance

Amendments require a reviewed pull request linked to the relevant GitHub issue. The PRD, Event
Model, constitution, and ADRs MUST be updated together when an amendment changes their ownership
or constraints. Version changes follow semantic versioning: MAJOR for incompatible governance
changes, MINOR for new principles, and PATCH for clarifications.

The constitution governs SDD artifacts but does not replace product or legal review. When tooling
cannot represent a decision cleanly, the decision remains explicit in the appropriate source
artifact and the workflow is amended through a PR.
