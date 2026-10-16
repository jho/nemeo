# Nemeo MVP Event Model

## Development

See [`docs/development.md`](docs/development.md) for the Node.js workspace layout, local commands,
TypeSpec/OpenAPI workflow, and test tiers.

This event model describes the PRD’s MVP happy path from account creation and SimpleFIN linking
through provider-neutral ingestion, categorization, transfer handling, tracking-budget setup,
pace reporting, household collaboration, and authorized MCP access. Post-MVP capabilities remain
outside the spine and are recorded in the PRD.

## Live view

```bash
em watch docs/event-model/budgeting.em -o docs/event-model/budgeting.svg
```

Static render:

```bash
em render docs/event-model/budgeting.em -o docs/event-model/budgeting.svg
```

## Patterns legend

- State Change — UI → Command → Event
- State View — Event(s) → Read Model → UI
- Automation — Read Model → Processor → Command → Event
- Translation — Boundary → Translation → Command → Event

## Artifacts

- [`budgeting.em`](docs/event-model/budgeting.em): model source
- [`budgeting.svg`](docs/event-model/budgeting.svg): rendered diagram
- [`.event-modeling.md`](docs/event-model/.event-modeling.md): resumable modeling state and open questions
- [`docs/prds/nemeo.md`](docs/prds/nemeo.md): source PRD
- [`docs/architecture/decisions.md`](docs/architecture/decisions.md): architecture decision backlog
- [`docs/architecture/adrs/`](docs/architecture/adrs/): accepted architecture decision records
