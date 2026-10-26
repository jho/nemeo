# ADR 0022: Bounded Context Model and Provider Feed Boundary

- **Status:** Accepted
- **Date:** 2026-10-25
- **Issue:** [#16 — Choose the initial application topology](https://github.com/jho/nemeo/issues/16)

## Context

The Event Model needs boundaries that remain useful as Nemeo adds providers, account types,
categorization behavior, and budgeting capabilities. A single `nemeo` context would make provider
credentials, imported financial records, household access, and budget decisions appear to share one
domain boundary. Conversely, creating an aggregate for every named feature would over-model the MVP.

Provider APIs consistently distinguish a connection or login from the accounts exposed through it.
Provider account identifiers can change when a connection is replaced, while Nemeo must preserve its
canonical account and transaction history.

## Decision

Nemeo will use four bounded contexts:

1. **`iam`** — authentication identity, user profile, household membership, invitations, and access.
2. **`feeds`** — external financial-data connections, consent, provider adapters, synchronization,
   retries, provider observations, and normalization.
3. **`ledger`** — canonical financial accounts and transactions, opening balances, categorization,
   and transfer associations.
4. **`budgeting`** — budgets, categories, targets, budget progress, and pace decisions.

The initial Event Model may present these contexts in one system view, but the source-controlled
model layout MUST support one Event Model per bounded context under a shared `system.yaml`. A context
may contain multiple aggregates; the Event Model MUST NOT invent an aggregate merely from a feature
name.

The initial aggregate lanes are:

- `iam`: `User`, `Household`
- `feeds`: `Connection`, `SyncRun`
- `ledger`: `Account`, `Transaction`, `Rule`
- `budgeting`: `Budget`, `Category`

These lanes represent consistency boundaries, not every noun, screen, projection, automation, or
integration. `Rule` is an internal learned-preference aggregate: category assignment and transfer
linkage are typed rule variants, but MVP does not expose a generic rule-management experience.
`Transfer`, `Categorization`, `Target`, `Pace`, `Progress`, and `Dashboard` are not aggregates.

`feeds` MUST NOT own canonical ledger state. It translates provider-specific observations into
provider-neutral facts or import capabilities consumed by `ledger`. `ledger` owns stable Nemeo
identities for accounts and transactions and retains source mappings such as provider, feed
connection, and external account ID.

`budgeting` consumes published ledger events or views. Dashboard, reporting, API, and MCP are
interfaces or projections, not bounded contexts in their own right.

## Rationale

- The four contexts match distinct business responsibilities and change rates.
- Connection-to-account cardinality is naturally one-to-many and provider-specific.
- Replacing or reconnecting a feed must not replace canonical ledger identities or history.
- Categorization and transfer matching interpret ledger records; they do not require separate MVP
  contexts or aggregates.
- Learned category and transfer behavior has one Ledger-owned `Rule` boundary, while the transaction
  changes it produces remain Transaction facts.
- Budgeting has a distinct user goal, language, and set of derived views, making it the first clear
  domain context to split into its own detailed model.

## Alternatives considered

### One `nemeo` context

Rejected because it couples provider lifecycle, financial records, identity, and budgeting and makes
future ownership and extraction seams ambiguous.

### `financial-data` as one broad context

Rejected because it hides the important boundary between provider synchronization and canonical ledger
state.

### `providers` as the context name

Rejected as the durable boundary name. The context is about external financial feeds and their
synchronization lifecycle, not provider brands. `providers` remains an adapter-level term.

### An aggregate for every budgeting concept

Rejected for MVP. Targets and pace are not independently justified aggregates: targets belong to
budget state, while pace is derived state and should be represented by projections/views.

## Consequences

- Cross-context changes use published commands, queries, events, translations, or composition; code
  MUST NOT import another context's internals or access its persistence directly.
- Feed replacement requires a mapping/reconciliation path rather than destructive account identity
  replacement.
- Provider observations must tolerate updates, removals, pending-to-posted transitions, and
  provider-specific identifiers.
- The current consolidated Event Model will be decomposed into `iam`, `feeds`, `ledger`, and
  `budgeting` model directories as the next structural refactor.
- Aggregate lanes MUST follow the current ownership map: IAM (`User`, `Household`), Feeds
  (`Connection`, `SyncRun`), Ledger (`Account`, `Transaction`, `Rule`), and Budgeting (`Budget`,
  `Category`). New lanes require a distinct consistency boundary and state lifecycle, not merely a
  new feature name.
- Splitting a context later is justified when it develops independent language, invariants,
  lifecycle, ownership, or deployment needs—not merely because it has a named feature.
