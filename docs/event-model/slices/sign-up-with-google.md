---
schemaVersion: 1
pattern: state-change
swimlane: User → UserProfile
status: draft
version: 1
---
# Slice: Sign Up with Google

![Diagram](./sign-up-with-google.svg)

## Intent

Create a Nemeo profile for a first-time Google identity without creating or managing a Nemeo
password. A successful signup returns an authenticated browser session and continues directly to
household setup; the user does not repeat authentication.

Returning users take the alternative `Authenticate with Google` slice.

## Trigger and actor

The user selects **Continue with Google** and completes Google's OIDC flow. Nemeo receives a
validated provider result through the Google identity adapter.

## Domain behavior

### Command

`Sign Up with Google` accepts a normalized, validated Google identity result. Provider tokens,
authorization codes, client secrets, and raw provider payloads remain in the identity adapter and
must not cross into the domain command or event payload.

The command creates a profile only when the stable `(provider, providerSubject)` pair is not already
linked. Session issuance is an application result after the event is durably recorded.

### Event

`User Account Created` records the new personal profile and its external identity mapping. It does
not create a household or grant household access.

## Command fields

| Field | Rule |
| --- | --- |
| `provider` | `google` for MVP; explicit for future providers |
| `providerSubject` | Required stable Google subject; never inferred from email |
| `verifiedEmail` | Verified provider email, when supplied; not an identity-linking key |
| `displayName` | Optional provider display name for initial profile presentation |
| `authenticationRequestId` | Required correlation/idempotency identifier |

## Event facts

`User Account Created` contains a new `userId`, provider and stable subject mapping, initial
verified email when supplied, and creation timestamp. It contains no password, provider token,
authorization code, raw provider payload, or session secret.

## Scenarios

### First-time Google identity creates a profile

Given a valid verified Google identity whose `(provider, providerSubject)` pair is not linked
When the user selects **Continue with Google**
Then Nemeo creates one profile and records `User Account Created`
And Nemeo establishes a revocable secure browser session
And the user proceeds directly to household setup

### Existing identity is not signed up twice

Given a Google provider subject already linked to a Nemeo profile
When the user attempts signup
Then Nemeo does not create another profile
And the user is directed through the existing authentication path

### Matching email does not merge identities

Given an unlinked Google subject whose email matches an existing profile
When the user attempts signup
Then Nemeo does not create a profile or merge financial data
And the user is directed to authenticate with the already-linked Google identity

### Invalid, cancelled, or failed provider flow

Given Google cannot complete or validate the OIDC flow
When the signup callback is handled
Then no profile or session is created
And the user receives a recoverable error

### Replayed signup callback is idempotent

Given the same valid signup request is delivered more than once
When Nemeo processes the replay
Then provider-subject uniqueness prevents a duplicate profile
And at most one `User Account Created` event is recorded

## Invariants

- **SIGNUP-001:** A `(provider, providerSubject)` pair maps to at most one Nemeo profile.
- **SIGNUP-002:** A profile is created only from a valid, verified provider result with a stable subject.
- **SIGNUP-003:** Matching email addresses are not sufficient evidence for identity linking or financial-data merging.
- **SIGNUP-004:** Failed, cancelled, invalid, or rejected signup emits no event and establishes no session.
- **SIGNUP-005:** No Nemeo-managed password, provider credential, raw provider payload, or session secret enters the event stream.
- **SIGNUP-006:** A successful signup session is scoped to the new user; household authorization begins only after household creation.

## Alternate and error flows

- Provider-subject uniqueness conflict: do not overwrite or merge; direct the user to the existing sign-in path.
- Database/event write failure: do not issue a browser session; retry only through an idempotent request path.
- Session issuance failure after profile creation: surface a recoverable error and allow safe retry without creating another profile.

## Read models and downstream effects

`User Account Created` feeds `Household Setup Status`, which makes the initial household setup path
available. The profile alone does not create a household.

## Open questions

None for MVP.

## Verification notes

- Use provider contract fixtures; never use real Google credentials in automated tests.
- Cover first-time signup, duplicate subject, email collision, invalid/cancelled callbacks, replay,
  event-write failure, and session-issuance failure.
- PostgreSQL-backed integration tests should verify uniqueness, idempotency, and absence of secrets
  in the event payload.
- A critical-path browser test should verify that signup proceeds directly to household setup.
