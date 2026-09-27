# ADR 0012: Identity, Tenancy, Authorization, Sessions, and Secrets

- Status: Accepted
- Date: 2026-09-27
- GitHub issue: [#20](https://github.com/jho/nemeo/issues/20)
- Product inputs: [#5](https://github.com/jho/nemeo/issues/5), [#9](https://github.com/jho/nemeo/issues/9), [#50](https://github.com/jho/nemeo/issues/50)
- Related architecture issue: [#21](https://github.com/jho/nemeo/issues/21)

## Context

Nemeo handles financial data for a shared household and exposes the same product capabilities to
the web application, MCP clients, workers, and scheduled jobs. Authentication, household scope,
roles, provider secrets, and audit behavior must therefore be consistent across every entry point.

The product decisions establish Google-first passwordless authentication, one household per user,
a root household manager, a fixed manager/viewer role model, household-owned financial resources,
read-only viewers, and full household deletion when the root manager account is deleted. The
architecture should support Apple as the next identity provider without introducing a password
system or a full fine-grained authorization product.

## Decision

### External identity and product profiles

- Nemeo uses external OpenID Connect identity providers. Google is the MVP provider; Apple is the
  first fast-follow provider.
- Nemeo does not create or manage passwords for MVP.
- An external identity is stored as a provider-and-subject mapping separate from the Nemeo user
  profile. Provider-specific claims are not the product’s durable identity.
- A successful provider identity resolves to one Nemeo user profile. Matching email addresses alone
  MUST NOT silently merge profiles or financial data. Linking another provider requires an explicit,
  authenticated account-linking flow.
- Provider adapters isolate OIDC discovery, claims validation, callback handling, and provider
  revocation behavior from the product profile and household model.

### Household tenancy and ownership

- A user belongs to exactly one household in MVP. Multi-household membership is deferred rather
  than represented as an implicit edge case.
- The household is the authorization boundary for shared financial data. Provider connections,
  accounts, transactions, budgets, categories, targets, rules, reports, and audit records belong to
  the household unless a later product decision explicitly changes ownership.
- The user profile and external identity mappings remain personal records. Household membership links
  the user to the household but does not make the identity the owner of household financial records.
- Each household has one root manager account. The root manager controls household lifecycle. Other
  manager-role users may manage budget state and access within the fixed product role model, but
  deleting the root manager account is a full household deletion workflow.
- Deleting a non-root viewer removes that user’s membership and access without deleting household
  data. Root deletion revokes access and provider credentials and invokes the account-deletion
  behavior defined by product issue [#9](https://github.com/jho/nemeo/issues/9).

### Roles and authorization

- MVP exposes two fixed roles: `manager` and `viewer`.
- A manager may perform the product’s household budget, transaction, connection, transfer,
  invitation, and access-management actions. A viewer may read the dashboard, budgets, transactions,
  pace status, and reports but may not mutate financial data, connections, or household access.
- Authorization is evaluated as `subject + action + resource + household scope` at the application
  boundary. The policy is implemented as a small explicit permission map, not a general-purpose FGA
  engine or user-configurable policy language.
- Every HTTP, MCP, worker, and scheduled entry point MUST resolve an authenticated principal and
  household scope before invoking a slice capability. Callers MUST NOT select or override household
  scope through an unchecked request parameter.
- MCP clients inherit the invoking user’s role and household scope. An agent acting for a viewer is
  read-only; an agent acting for a manager remains subject to the confirmation and audit rules in
  the accepted MCP and AI product policies.

### Sessions and tokens

- Browser sessions use secure, opaque, server-side session records with an `HttpOnly`, `Secure`,
  appropriately `SameSite` cookie. Session records are revocable and are not self-contained claims
  that must remain valid after household or identity changes.
- MCP access uses user-scoped bearer credentials resolved to the same principal model. Raw tokens
  MUST NOT be stored in plaintext; token hashes, expiry, client identity, and revocation state are
  retained. Local and hosted MCP deployment adapters may differ in issuance flow but MUST produce
  the same authorization context.
- Authentication success rotates the session or access credential. Root deletion, membership
  revocation, provider unlinking where required, and security events MUST be able to revoke affected
  sessions and MCP credentials.
- Session storage and token validation are application capabilities behind an infrastructure port so
  the Compose-first deployment can use PostgreSQL while a later hosted deployment can add a managed
  session or identity adapter.

### Provider secrets

- Provider access URLs, tokens, refresh material, and equivalent credentials are encrypted at rest
  using an application encryption boundary. The key source is deployment-specific and may later be
  backed by a cloud KMS without changing provider or domain code.
- Secrets MUST be excluded from ordinary API responses, audit payloads, application logs, error
  messages, analytics, and MCP results.
- Secret access is limited to the provider adapter and the workflows that require it. Authorization
  checks and audit context are established before secret retrieval.

### Domain history, security records, and operational logging

- Financial mutations that belong to the event-sourced Transaction or Budget domains retain their
  immutable domain event history under ADR 0011. That history is the source for explainability and
  replay; this ADR does not create a second generic audit stream for those mutations.
- Security-relevant events receive a small redacted access/security record. Examples include
  authentication success or failure, session creation or revocation, invitation and role changes,
  membership revocation, account deletion initiation, provider credential changes, and denied
  authorization attempts. Each record includes the principal when known, household, entry surface,
  action, resource reference, outcome, timestamp, and correlation reference where available.
- Ordinary reads of budgets, transactions, reports, or dashboard data MUST NOT become durable audit
  events by default. They may produce redacted operational logs, metrics, and traces needed for
  troubleshooting and abuse detection, subject to the observability and retention policy.
- Security records and operational telemetry MUST NOT contain provider secrets or unnecessary
  financial payloads. Failed, denied, and confirmation-rejected actions remain distinguishable from
  successful mutations.
- Access history shown in the household experience is limited to meaningful membership, role, and
  access-control changes. Retention, deletion, export, and legal exceptions follow product issue
  [#9](https://github.com/jho/nemeo/issues/9) rather than being invented by this ADR.

## Alternatives considered

### Full fine-grained authorization / FGA

Deferred for MVP. The internal action/resource/scope vocabulary preserves a future expansion path,
but fixed manager/viewer policy bundles are sufficient for the current product and are easier to
explain, test, and operate.

### Nemeo-managed passwords

Rejected. They increase signup friction and create password-reset and credential-security work that
does not support the product’s Google-first, passwordless onboarding goal.

### Email-based automatic identity merging

Rejected. Email equality is not sufficient proof that two provider identities should share financial
data. Explicit authenticated linking prevents accidental account merges.

### JWT-only sessions

Rejected as the default browser strategy. Revocable opaque sessions keep household membership,
root deletion, and provider changes enforceable without waiting for long-lived claims to expire.

### User-owned provider connections

Rejected for shared household data. Provider connections feed household-owned accounts and must be
managed and deleted with the household lifecycle, subject to the product’s root-account deletion
policy.

## Consequences

Nemeo gets one consistent principal and authorization model across web, API, MCP, workers, and
schedulers without adopting a large identity or policy platform. Household ownership and root
deletion are explicit, provider secrets have a clear boundary, and audit data can support both
security operations and the user-facing access history.

The MVP intentionally cannot represent a user in multiple households or arbitrary custom roles.
Adding either later will require a product decision and changes to membership, authorization, and
session-scope handling. PostgreSQL becomes the default home for revocable sessions, token metadata,
membership, and audit projections, while encryption keys remain a deployment concern.
