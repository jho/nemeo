# ADR 0012: Identity, Tenancy, Authorization, Sessions, and Secrets

- Status: Accepted
- Date: 2026-09-27
- GitHub issue: [#20](https://github.com/jho/nemeo/issues/20)
- Product inputs: [#5](https://github.com/jho/nemeo/issues/5), [#9](https://github.com/jho/nemeo/issues/9), [#50](https://github.com/jho/nemeo/issues/50)
- Related architecture issue: [#21](https://github.com/jho/nemeo/issues/21)

## Context

Nemeo needs one identity and authorization boundary for the web app, API, MCP, workers, and
schedulers. The MVP product decisions are Google-first passwordless signup, one household per user,
a root household manager, fixed manager/viewer roles, and household-owned financial data.

## Decision

### Identity

- Use external OIDC identity providers. Google is MVP; Apple is the first fast follow.
- Nemeo does not manage passwords.
- Store `(provider, subject)` mappings separately from the Nemeo profile. Matching email addresses
  MUST NOT silently merge profiles or financial data; additional providers require explicit linking.

### Household and ownership

- A user belongs to exactly one household in MVP.
- The household owns provider connections, accounts, transactions, budgets, rules, reports, and
  household access. User profiles and external identity mappings remain personal.
- Each household has one root manager lifecycle. Deleting the root manager invokes full household
  deletion; deleting a viewer removes membership and access without deleting household data.

### Authorization

- MVP has two fixed roles: `manager` and `viewer`.
- Managers can perform household budget, transaction, connection, transfer, invitation, and access
  actions. Viewers can read the dashboard, budgets, transactions, pace, and reports only.
- Enforce authorization at the application boundary using
  `subject + action + resource + household scope` checks.
- HTTP, MCP, worker, and scheduled entry points MUST resolve the same principal and household scope.
  MCP agents inherit the invoking user’s role. MVP does not introduce an FGA engine or custom policy
  language.

### Sessions and secrets

- Browser authentication uses revocable opaque server-side sessions in secure `HttpOnly`, `Secure`,
  appropriately `SameSite` cookies.
- MCP credentials are user- and household-scoped, expiring, revocable, and stored only as hashes or
  equivalent non-secret metadata. They resolve to the same application principal.
- Provider access URLs, tokens, and equivalent credentials are encrypted at rest and are excluded
  from ordinary responses, logs, traces, errors, and MCP results.

### Mutation history and observability

- Financial mutation history remains in the immutable domain event streams defined by ADR 0011.
- Security-relevant events—such as authentication failures, session revocation, membership changes,
  denied authorization, and credential changes—are redacted structured logs/traces for operational
  visibility. They are **not persisted as a separate security-audit database** by this ADR.
- Ordinary reads are not durable audit events. Logging and tracing MUST avoid secrets and unnecessary
  financial payloads.

## Alternatives considered

### Nemeo-managed passwords

Rejected because they add signup friction and password-reset/security work to a passwordless product.

### Full FGA or custom user policies

Deferred. Fixed manager/viewer bundles and application-level scope checks are sufficient for MVP.

### Automatic email-based identity merging

Rejected because matching email addresses are not sufficient proof that financial data should merge.

### JWT-only browser sessions

Rejected as the default because revocable opaque sessions make membership and root deletion changes
take effect immediately.

## Consequences

The MVP gets one small authorization model across all entry points, household ownership is explicit,
and provider secrets have a clear boundary. Financial history remains in the domain event model;
operational security visibility remains logging/tracing rather than a new persistence subsystem.

Multi-household membership, custom roles, and richer user-facing access history require future product
and architecture decisions.
