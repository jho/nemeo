---
schemaVersion: 1
pattern: state-view
swimlane: User → Household
status: ready-to-implement
ratifiedBy: jho (backlog export)
ratifiedOn: 2026-10-23
version: 1
---
# Slice: Start Household Setup

![Diagram](./start-household-setup.svg)

## Intent

Show an authenticated user the initial household setup state and provide the entry point for
creating their first household. Signup and returning authentication both lead here without a
second authentication step.

## UI / interaction design

- Entry: immediately after Google signup or authentication.
- Wireframe: [Start household setup](../../design/wireframes/start-household-setup.html)
- The screen shows the authenticated state, asks for a household name, and continues to `Create
  Initial Household`.
- The prototype covers validation, loading, and successful continuation states. Authorization and
  projection failures remain behavioral requirements below.

## Trigger and actor

The authenticated user completes Google signup or authentication. The application resolves the
user's current household setup status and presents the appropriate setup screen.

## Read model

`Household Setup Status` is projected from `User Account Created` and `User Authenticated`.

It must identify the authenticated user, whether an initial household exists, and whether setup can
continue. It must not expose another user's household data.

## Scenarios

### Newly authenticated user can begin setup

Given a user has just completed Google signup or authentication
And the user does not yet belong to a household
When the application reads `Household Setup Status`
Then the user sees the household setup screen
And the user can continue to `Create Initial Household`

### Existing household skips initial setup

Given an authenticated user already belongs to a household
When the application reads `Household Setup Status`
Then the user is directed to the existing household experience
And the initial household creation action is not offered

### Unauthenticated access is rejected

Given no valid authenticated session is present
When the household setup screen is requested
Then no household setup status is revealed
And the user is directed to Google authentication

### Refresh does not create state

Given the user is viewing initial household setup
When the user refreshes or revisits the screen
Then the same setup status is returned
And no household or other domain event is recorded

## Invariants

- **SETUP-001:** Household setup status is scoped to the authenticated user.
- **SETUP-002:** A user without a household may create an initial household; a user with an existing household may not create a second one through this path.
- **SETUP-003:** Reading setup status does not mutate domain state or record an event.
- **SETUP-004:** An unauthenticated request cannot reveal household membership or setup details.

## Alternate and error flows

- A missing or expired session redirects to Google authentication without disclosing setup state.
- If the setup projection is temporarily unavailable, show a recoverable error and do not offer a
  create action based on stale or incomplete data.
- If household membership changed between the read and the create command, `Create Initial
  Household` remains authoritative and rejects duplicate creation.

## Read models and downstream effects

This slice reads `Household Setup Status`. It does not emit an event. The next state-changing slice
is `Create Initial Household`.

## Open questions

None for MVP.

## Verification notes

- Cover newly authenticated users, existing household members, unauthenticated requests, refreshes,
  projection errors, and stale concurrent setup attempts.
- Use PostgreSQL-backed integration tests to verify user scoping and that reads do not append events.
- A critical-path browser test should verify Google completion → household setup without a second
  authentication screen.
