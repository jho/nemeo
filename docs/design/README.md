# Nemeo UI design artifacts

This directory contains visual design artifacts that support feature and Event Model slice work.
The PRD, ADRs, Event Model, and slice documents remain authoritative for product behavior and
domain contracts; these artifacts explain how that behavior is presented and used.

## Artifact locations

- `wireframes/<slice-key>.svg` or `.html` — a screen or interaction flow for one slice.
- `prototypes/<feature>.html` — an interactive prototype covering multiple screens or a broader
  information-architecture flow.
- `assets/` — shared visual assets used by wireframes and prototypes.

The current dashboard prototype remains at [`../../dashboard-mockup.html`](../../dashboard-mockup.html)
because it is referenced by ADR 0010. It is the central reference for MVP information architecture
and visual direction, not the detailed specification for every screen.

## Slice design contract

When a slice has a user-facing UI, its slice document should link to the relevant wireframe or
prototype and briefly state:

- the route or entry point;
- the information the user must see;
- the action and next slice or destination;
- loading, empty, error, and permission states that matter;
- the design-system components or tokens used.

Headless/API-only slices do not need a wireframe. Their slice documents should describe the caller
and interaction contract instead.

Visual artifacts are reviewed and changed in the same branch as the slice or feature they support.
Use the existing design system and information architecture; a new reusable component or
interaction pattern requires an explicit design-system update or human decision.
