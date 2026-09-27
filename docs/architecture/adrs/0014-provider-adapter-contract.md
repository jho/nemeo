# ADR 0014: Versioned Provider Adapter Contract

- Status: Accepted
- Date: 2026-09-27
- GitHub issue: [#18](https://github.com/jho/nemeo/issues/18)
- Related product decision: [#10](https://github.com/jho/nemeo/issues/10)
- Related persistence decision: [ADR 0011](0011-domain-persistence-and-event-strategy.md)
- Related topology decision: [ADR 0005](0005-modular-monolith-topology.md)
- Related operations decision: [#19](https://github.com/jho/nemeo/issues/19)

## Context

Nemeo needs to connect SimpleFIN first and preserve the option to add a provider with stronger
coverage or better bundled economics later. Provider APIs differ in authentication, account
discovery, history limits, cursors, identifiers, pending-state behavior, deletion semantics, rate
limits, and refresh capabilities. Those differences must not leak into transaction, budget, pace,
reporting, or MCP capabilities.

The PRD requires provider replacement to preserve budget history and safely handle incomplete
matches. The Event Model places provider translation at the Connections boundary before normalized
records enter Accounts and Transactions. Scheduling and retry policy are intentionally a separate
decision in issue #19.

A quick comparison of likely providers confirms that the boundary must support more than one sync
shape. SimpleFIN exposes a claimed access URL and a `/accounts` snapshot with optional date windows
and pending records. Akoya exposes OAuth-style tokens plus separate account, balance, and
transaction APIs with offset pagination. Plaid exposes a cursor-based change feed with added,
modified, and removed records. These provider differences are evidence for the contract shape, not
dependencies on any one vendor:

- [SimpleFIN Protocol](https://www.simplefin.org/protocol.html)
- [Akoya Transactions API](https://docs.akoya.com/reference/transactions)
- [Akoya APIs Overview](https://docs.akoya.com/guides/api-overview)
- [Plaid Transactions Sync](https://plaid.com/docs/transactions/sync-migration/)
- [Plaid transaction states](https://plaid.com/docs/transactions/transactions-data/)

## Decision

Nemeo will define an application-owned, versioned Provider Adapter Contract. Each provider adapter
implements that contract behind the Connections context; provider SDKs, response types, credentials,
and setup details do not cross the boundary.

The MVP contract is `ProviderAdapter v1`. It is a capability contract rather than a mirror of any
provider SDK. A provider declares which capabilities it supports, and unsupported operations return
a typed `unsupported` result rather than being inferred from provider-specific behavior.

The sync port MUST represent a normalized change set, not require one provider pagination strategy.
Each request/result carries the connection and account scope, an optional opaque provider cursor,
an optional start/end window, page continuation, a completeness flag, a provider watermark or
observed-at timestamp, and arrays for added, modified, and explicitly removed records. The adapter
may implement this with a cursor, offset/page, date window, or full snapshot. The ingestion workflow
must consume every page before committing the corresponding change set and persist the provider
continuation state only after successful application.

### Adapter capabilities

An adapter MUST cover these operations where the provider supports them:

- begin and complete connection setup, without exposing provider credentials to domain code;
- discover provider accounts and return provider-neutral account candidates for user confirmation;
- request initial history with an explicit date/window limit;
- request incremental changes using provider cursors or overlapping time windows;
- return current balances and balance timestamps;
- return new, updated, pending, and removed transaction records when the provider exposes those
  states;
- report refresh, reauthorization, and revocation capabilities and status;
- revoke or disconnect provider access when supported;
- describe provider limits, supported history, refresh behavior, and required user action.

The adapter returns normalized provider-neutral records, including provider identifiers, timestamps,
amounts, currency, account references, descriptions/merchant data, pending state, update/removal
state, related/predecessor provider record identifiers, and provider sync metadata. The adapter may retain redacted provider metadata needed for
reconciliation or troubleshooting, but credentials, access URLs, tokens, and secrets never enter
normalized records, domain events, ordinary responses, logs, or traces.

### Identity and replacement semantics

Provider connections, Nemeo accounts, and Nemeo transactions are separate concepts:

- a connection identifies authorization to one provider;
- an internal account identity survives provider disconnect or replacement when it is safely matched;
- an internal transaction identity is keyed to the provider connection and provider record identity
  for idempotent ingestion, then remains a Nemeo-owned record after normalization.

The ingestion boundary MUST use provider-scoped identifiers and a provider-specific sync cursor or
overlap window to make repeated pages and retries idempotent. A provider update changes the existing
normalized record; an explicit provider removal becomes a removal/tombstone state and MUST NOT
silently erase user history. Absence from a later snapshot MUST NOT be interpreted as removal unless
the provider contract explicitly guarantees complete snapshots for the requested scope. Pending-to-
posted transitions update the same logical record when the provider identity permits it; otherwise a
new provider record MUST carry a related/predecessor identifier so the normalizer can preserve the
relationship without assuming the two records are interchangeable.

Provider replacement is an explicit workflow, not an adapter side effect. It preserves existing
budget, category, transfer, and reporting history; safely matched accounts and transactions may be
linked to existing Nemeo identities; unmatched or ambiguous records remain separate and go to
review. Opening-balance and cutover handling are recorded through the Accounts workflow and do not
rewrite provider-sourced transaction history.

### Sync result and failure model

Every sync result MUST identify the connection, requested scope, provider cursor/window, completion
state, affected accounts, and whether the result is complete, partial, or unsupported. Provider
failures use a small typed set:

- `authentication_required` or `revoked` — user action is required and scheduled work must stop;
- `rate_limited` — include provider retry guidance when available;
- `transient` — safe to retry according to the jobs policy;
- `invalid_request` or `unsupported` — do not retry without a changed request or capability;
- `partial` — identify affected accounts while preserving successful results.

The adapter may provide retry-after, refresh, and reauthorization hints. It MUST NOT own scheduling,
backoff, leases, job persistence, or global retry policy; those belong to issue #19. Adapter calls
are safe to repeat with the same connection and sync scope, and the ingestion application capability
owns concurrency and event/projection behavior.

### Boundary ownership

The adapter translates provider data into the Connections/Accounts/Transactions application
capabilities represented by the Event Model. It does not categorize transactions, match transfers,
calculate budgets, evaluate pace, or decide user permissions. Those behaviors remain in their
respective vertical slices.

The first SimpleFIN adapter is the reference implementation. Its access URL/setup flow, history
window, overlap behavior, and provider-specific limits remain inside the adapter and its connection
workflow. SimpleFIN-specific assumptions MUST NOT appear in budget or reporting contracts.

The setup port MUST support both user handoff and server-side completion. A provider may require a
user to paste or submit a one-time token which the adapter exchanges for a stored access credential,
or may require an OAuth authorization redirect followed by token refresh and consent revocation.
The port therefore returns setup instructions and a provider connection state rather than exposing
a universal credential format. Token refresh, consent expiry, and reauthorization are represented
as connection status/capability outcomes and are actionable by the connection workflow.

Provider notifications are optional hints to start or prioritize a sync; they are never the source
of transaction truth. A missed notification must be recoverable through scheduled or manual sync.

### Contract tests

Nemeo will maintain one provider-neutral contract-test suite. Every adapter MUST pass the applicable
fixture-based cases for:

1. connection setup, discovery, capability declaration, and revocation;
2. initial history and incremental sync, including overlapping-window deduplication;
3. stable account and transaction identifiers, updates, pending transitions, and removals;
4. balance snapshots and reconciliation metadata;
5. partial results, typed failures, rate-limit hints, and reauthorization state;
6. repeat execution and concurrency-safe idempotency expectations.

The shared suite tests the adapter boundary without requiring a live provider. Provider-specific
integration tests may exercise sandboxes or recorded fixtures separately. Contract tests verify
translation behavior; they do not replace domain, projection, or end-to-end tests.

The fixtures MUST include both of the following provider behaviors: a snapshot/window provider that
does not emit removals, and a cursor/change-set provider that emits a pending removal plus a posted
replacement. This prevents the contract tests from accidentally assuming that every provider has
Plaid-like change tracking or SimpleFIN-like snapshots.

### Versioning

The contract has an explicit major version. Additive optional capabilities and fields may be added
compatibly; changes to identity, sync semantics, normalized meanings, or error behavior require a
new major contract version and an adapter migration plan. Provider adapters may support different
capability subsets, but all required product behavior must be expressed through the same normalized
application capabilities.

## Rationale

This keeps provider churn at the translation edge while preserving the stable identities and event
history needed for budget continuity, reconciliation, and future provider migration. Capability
declarations make differences explicit instead of pretending every provider supports the same sync
model. A shared contract suite gives the first SimpleFIN integration a reusable boundary for later
providers without requiring changes to category targets, pace calculations, reports, or MCP schemas.

## Alternatives considered

### Call provider SDKs from ingestion or budget code

Rejected. It would spread provider-specific identifiers, limits, errors, and authentication concerns
through domain and application slices, making provider replacement expensive and difficult to test.

### Define an adapter as a copy of the SimpleFIN API

Rejected. The boundary must represent Nemeo capabilities, not one provider's response shape. A
SimpleFIN-shaped port would make future providers conform to accidental details and would obscure
unsupported capabilities.

### Normalize only into generic database tables

Rejected as the application contract. Tables may support an adapter implementation, but they do not
define setup, capability, sync, failure, identity, or replacement semantics and would leak persistence
concerns into the ingestion workflow.

### Put scheduling and retries in each adapter

Rejected. Providers can supply limits and retry hints, but leases, job state, backoff, cadence, and
connection-scoped scheduling must remain centralized under issue #19.

## Consequences

Provider work has a clear seam: adapter translation, normalized ingestion, domain events, and
projections can be tested independently. SimpleFIN-specific setup and limitations remain isolated,
while provider replacement can preserve Nemeo-owned history and route ambiguity to review.

The tradeoff is that the v1 contract must be intentionally designed and maintained, and some
provider features will be represented as capability gaps rather than forced into a lowest-common-
denominator abstraction. Adding a provider requires adapter implementation plus contract fixtures,
not changes to budget or reporting behavior.
