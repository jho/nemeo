---
title: "Nemeo PRD"
version: "0.5.0"
status: draft
owner: "jho"
stakeholders: []
created: "2026-07-10"
last-updated: "2026-09-26"
jira-epic: ""
---

# Nemeo

## Overview

**Summary:** Nemeo is an AI-friendly, tracking-based budgeting product that stays nearly headless for agent workflows while still giving individuals and families a simple, installable web app for progress and review.

**Problem:** Envelope budgeting asks people to pre-allocate and continuously rebalance money, which creates too much setup and maintenance. Users need a lower-friction way to track spending against a plan and understand whether current spending is sustainable. Most budgeting tools also treat AI as a shallow embedded feature instead of making the product usable by external agents.

**Why now:** AI agents are becoming a primary workflow surface, but budgeting products have not caught up. We want a product architecture that works well with desktop agents and always-on agents through MCP, without forcing the AI experience into a poorly embedded in-app chatbot.

**MVP setup outcome:** A new user should be able to sign up, complete minimal account setup, and
arrive at the start of a budget period with a usable budget managed by Nemeo. Categories, targets,
transaction categorization, transfer treatment, and pace-alert readiness should be prepared by the
system, with the user asked to review only exceptions or decisions that materially affect trust.

## Product thesis

Nemeo should feel like a budget that takes care of itself. The user sets up a reasonable plan once, then receives a clear assessment of whether spending is going well and what—if anything—needs adjustment.

Product principles:

- **Setup once, maintain by exception:** automate syncing, categorization, budget maintenance, and reporting; ask the user to intervene only when confidence is low or a decision matters.
- **Tracking over envelopes:** compare real spending with targets and recommend adjustments without requiring users to assign every dollar to an envelope.
- **Guidance over guilt:** explain whether the household is on track and offer practical next actions instead of treating every variance as failure.
- **Useful AI, not a sales chatbot:** use AI to organize, explain, and recommend; do not use the product primarily to sell credit, investments, insurance, or other financial products.
- **Affordable by design:** keep the subscription close to the underlying financial-data-provider cost and make pricing transparent.

## Competitive positioning

Monarch is the primary benchmark competitor for a polished, bank-connected household finance experience. Nemeo should compete by being easier to set up, requiring less ongoing maintenance, and costing materially less for users who primarily want budgeting and spending guidance.

YNAB is a useful contrast: Nemeo intentionally avoids making envelope allocation the central user workflow. Rocket Money and similar products are also a contrast: Nemeo should not depend on aggressive cross-selling or upselling financial products to support the core budget experience.

## Provider and pricing strategy

Nemeo must not make the long-term product economics or onboarding experience depend on a single financial-data provider. SimpleFIN is the initial integration because its read-only model and observed reliability are attractive, but its Bridge subscription is paid separately by each user. Unless a commercial arrangement permits Nemeo to sponsor or bundle that subscription, SimpleFIN can make users feel like they are paying for two products.

The provider abstraction is therefore an early MVP foundation, not a post-MVP cleanup task. SimpleFIN remains the first adapter, while the provider contract must support adding a provider that Nemeo can pay for and bundle into one transparent subscription. Candidate follow-on providers include Akoya and other OAuth/API aggregators, subject to coverage, reliability, onboarding, commercial terms, and target-bank testing.

## Budget model: tracking-based by default

Nemeo uses tracking-based budgeting as the default workflow:

- a budget is created with spending categories and target amounts or limits for a budget period
- initial setup links accounts, infers useful categories and starting targets from recent transactions and income, and auto-categorizes by default
- the user should see useful tracking results without manually assigning every dollar
- transactions count against the relevant category as they are imported and categorized
- each category shows actual spend, target, remaining amount, and pace status
- pace is calculated from elapsed calendar time in the budget period: expected spend is the category target multiplied by the fraction of the period elapsed
- the first pace model is intentionally simple and leaves room before warning; warning tolerance is modeled per category with system-provided defaults and optional user overrides, while exact default values, variance-aware buffers, and more predictive refinements remain separate decisions or post-MVP refinements
- when actual spending exceeds expected pace plus the category tolerance, MVP presents an in-product warning with dismiss and snooze controls; mobile push and SMS channels are future extensions
- users can adjust targets without moving money between envelopes
- optional envelope-style allocation may be supported later, but it is not the primary MVP workflow

### Categorization and transfer confidence policy

Nemeo should make a best effort to categorize transactions automatically so that users receive a
useful budget without reviewing every imported record. Confidence is an internal and user-visible
explanation signal, not a reason to block the initial budget. The user should be able to correct a
category directly from the transaction or review experience and choose **Remember this change** to
create a reusable payee/category rule for future matching transactions. Applying the same rule to
historical transactions requires an explicit additional action.

- Eligible transactions receive the system's best category by default, including lower-confidence
  assignments when a usable candidate exists.
- A transaction with no usable category remains uncategorized and is surfaced as an exception; it
  does not block setup or budget creation.
- The product labels assignments as AI-categorized, rule-categorized, or user-confirmed and makes
  the confidence/review state available in transaction detail and optional review queues.
- User-confirmed assignments and user-approved rules are never silently overwritten by later AI
  categorization.
- A category correction immediately updates budget actuals and can create a reusable rule without
  requiring the user to navigate a separate rule-management workflow.
- Transfer matching is confirmation-first. Nemeo may suggest, “This looks like a transfer from
  Account X to Account Y,” but a candidate is not treated as a transfer until the user confirms it
  or an explicitly user-approved transfer rule matches.
- Until a transfer candidate is confirmed, the underlying transactions retain their ordinary
  income/spending treatment. This favors a visible false negative over silently hiding spending.
- A confirmed transfer removes both sides from income, spending, category actuals, and pace
  calculations while preserving the underlying transactions and match explanation.
- Transfer corrections are reversible and retain their history. Historical retagging requires
  explicit confirmation; model improvements may suggest changes but may not silently rewrite user
  decisions.

## Goals

| Goal | Metric | Baseline | Target |
|------|--------|----------|--------|
| Fast budget setup | Time from first launch to a usable budget | Manual setup often takes 30+ minutes | <= 10 minutes |
| Better optimization | Estimated discretionary savings identified by AI-assisted setup / review | Unclear or inconsistent | >= 5% of monthly discretionary spend |
| Clear budget awareness | Family viewer can correctly tell whether a purchase affects budget health in usability checks | Not available | 4/5 scenarios answered correctly |
| Fast signup | New user can reach authenticated onboarding | No baseline | Google sign-up/login completes in <= 2 minutes |
| Actionable pacing | Users notice and understand an ahead-of-pace warning | Not available | >= 80% of test users correctly identify the affected category and action |
| Low-maintenance use | Users can maintain an accurate budget without daily manual bookkeeping | Not available | >= 80% of pilot users report that the product requires little or no daily maintenance |
| Affordable access | Total recurring price is close to the underlying financial-data-provider cost | Not available | Product price target is SimpleFIN cost plus a small, transparent premium; exact ceiling TBD |

## Users

| User / persona | Need | Pain today | Success state |
|----------------|------|------------|---------------|
| AI power user | Use an AI assistant to set up, optimize, and analyze a budget | Existing tools do not expose a usable agent interface | Can ask an agent to create budgets, build reports, and critique spending habits |
| Family viewer | See progress and understand the budget without doing the heavy lifting | Budgeting tools feel complex and full of controls they do not need | Can check progress and understand whether a purchase affects the budget |
| Individual / household budget owner | Track spending without manually allocating every dollar | Envelope setup and rebalancing are tedious | Can connect accounts and understand category pace with minimal maintenance |

## Scope

### Client strategy

MVP uses a responsive web application designed as an installable Progressive Web App (PWA). It
should support an app icon, standalone launch, responsive touch interactions, and the minimum
notification behavior that the supported browsers provide. A native mobile wrapper, such as
Capacitor, remains an option after the web experience proves the product and native APIs or app
store distribution justify the additional packaging and release work. A separate native mobile
client is not an MVP requirement.

### In scope

- Establish a provider-neutral account-connection and ingestion contract before implementing the first provider adapter
- Link financial accounts through a guided SimpleFIN connection flow with minimal setup steps
- Support SimpleFIN transaction ingestion with the maximum historical backfill the provider makes available
- Schedule SimpleFIN synchronization and AI categorization on provider-compatible cadences
- Implement the first provider adapter against the provider-neutral contract; additional providers must not require changes to the budget domain model
- Ingest and display transactions
- Identify and normalize transfers between linked accounts so they do not double-count against the budget
- Auto-categorize transactions into tracking categories
- Infer and initialize category targets from recent financial activity and income
- Seed budgets from historical spending with conservative behavior when history is sparse
- Support category caps, protected categories, monthly carryover, rebalancing, and clearing/reset tools
- Maintain category ordering and taxonomy over time
- Track actual spending against category targets within a budget period
- Calculate category and overall budget pace, including projected target variance
- Show ahead-of-pace warnings in the product
- Provide a basic current-month dashboard for cashflow, budget progress, and top spending destinations
- Sign up and log in with Google; retain an extensible provider model for future auth providers
- Provide an MCP server so AI agents can inspect budget and transaction data
- Support a simple mobile family-viewer experience through the responsive installable web app
- Support core budget portability / export later, after adoption
- Support household invitations and role-based access for shared budget review
- Keep the core product free of financial-product cross-selling and promotional upsell flows
- Keep provider costs and whether they are bundled or user-paid explicit during onboarding and pricing

### Out of scope

- Push, email, SMS, and highly configurable alerting workflows beyond in-product warnings
- Deep budgeting automation beyond the first setup / read / review loop
- Advanced analytics dashboards beyond the first reporting surface
- Envelope allocation as the default budgeting model
- Additional identity providers beyond Google in the first release
- Paying for, sponsoring, or reselling SimpleFIN Bridge subscriptions without an explicit commercial agreement
- Supporting multiple production financial-data providers in the first release; the abstraction is required, but SimpleFIN is the only required production adapter
- Maintaining a separate native mobile client in the first release

## Domain terms

| Term | Definition | Notes / avoid |
|------|------------|---------------|
| Provider | An external financial-data service used to connect accounts and import records | SimpleFIN is the first adapter; provider-specific details stay behind the provider contract |
| Provider adapter | The implementation that translates one provider’s authentication, account, transaction, balance, history, and sync behavior into Nemeo’s provider-neutral contract | Do not let provider SDKs or response shapes leak into budget logic |
| Provider connection | A user-authorized link between Nemeo and one provider account or connection | A user may have multiple connections and providers |
| Account | A linked bank account, credit card, or similar financial source | Avoid “posting” or “entry” |
| Transaction | A synced financial record from an account | Use this as the default record term |
| Merchant | The payee or counterparty associated with a transaction when available | Avoid swapping with “vendor” unless needed |
| Payee | The normalized recipient or source displayed for a transaction, including native transfer payees | Keep transfer payees distinct from merchants |
| Category | A named spending group used to organize transactions and compare actual spending with a target | This replaces “envelope” in the default workflow |
| Target | The planned amount or spending limit for a category in a budget period | Do not imply that money has been physically allocated |
| Category cap | A maximum target or spending limit that automation must not exceed without explicit permission | Caps protect against over-allocation from inferred or automated budgets |
| Protected category | A category whose target or balance automation cannot change without explicit permission | Use for essentials, obligations, or user-selected categories |
| Budget | The parent plan that owns categories and targets for a budget period | Avoid overloading it to mean the app itself |
| Budget period | The time window used for planning, tracking, and reporting | Keep it flexible; do not lock it to month |
| Actual spend | Categorized spending recorded during a budget period | Excludes transfers and other non-spending transactions |
| Pace status | A category’s relationship between current actual spend, elapsed period time, and target | Use “on pace,” “ahead of pace,” or “behind pace” consistently |
| Projected spend | Estimated spend at the end of the budget period if the current pace continues | Clearly label this as a projection |
| Envelope | An optional allocation bucket supported only if/when envelope budgeting is added | Do not use as the default category term |
| Report | A generated or saved presentation of financial data | Prefer this over “view” for user-facing analytics |
| Reporting period | The time range used by a dashboard or report | The current month is the default MVP period |
| Comparison baseline | A prior period or historical average used to contextualize current results | MVP baselines include last month and average |
| Sync run | One scheduled or manually requested provider synchronization attempt | Track status and errors independently for each run |
| Categorization confidence | The system’s confidence that a category assignment is correct | Low-confidence assignments require review or clear labeling |
| Household member | A person granted access to a shared budget with a defined role | Never assume all members have the same permissions |
| MCP server | The integration layer external AI agents use to read and act on budget data | Keep this term consistent |
| Transfer | A movement of funds between linked accounts that must not be counted as income or spending | Represent both sides with canonical source-account, destination-account, and direction mappings |
| Transfer rule | A reusable rule that identifies or labels recurring transfers based on account, direction, payee, amount, or other transaction signals | Rules must be reviewable and reversible |
| Opening balance | The starting balance established for a connected account before imported transaction history begins | It may be created or corrected when historical data is incomplete |

## Requirements

### Setup automation

**Story:** As an AI power user, I want to link my accounts and get an initial budget automatically so that I can use the product without manual setup work.

**Acceptance criteria:**
- [ ] A new user can link supported financial accounts with minimal setup steps
- [ ] The system can infer starting categories and targets from recent transactions and income
- [ ] The system can auto-categorize transactions by default during setup
- [ ] A usable initial budget exists after linking and sync completes
- [ ] Setup completes without requiring envelope creation, dollar assignment, or manual entry of every historical transaction
- [ ] The user can review inferred categories, targets, and transfer classifications before relying on them
- [ ] The system identifies only the setup exceptions that require user attention

### Low-maintenance budget operation

**Story:** As a budget owner, I want the budget to stay accurate and useful automatically so that I can spend a few minutes reviewing exceptions instead of maintaining every transaction by hand.

**Acceptance criteria:**
- [ ] Routine sync, categorization, transfer matching, pace calculation, and dashboard refresh happen without daily manual actions
- [ ] The product surfaces a prioritized review queue for low-confidence categorization, unmatched transfers, balance discrepancies, and material budget changes
- [ ] The user can review and resolve multiple related items in a single workflow
- [ ] The product gives a clear overall assessment such as on track, needs attention, or insufficient data
- [ ] The product explains the highest-impact adjustments available to the user
- [ ] No core MVP workflow requires envelope allocation or daily transaction entry
- [ ] A user can pause or disable automated recommendations without disabling account synchronization

### Account onboarding

**Story:** As an AI power user, I want to create an account and connect my financial sources so that the product can ingest my transactions.

**Acceptance criteria:**
- [ ] A new user can create an account successfully
- [ ] A new user can sign up and log in with Google
- [ ] Provider identity is stored separately from the product profile so additional auth providers can be added later
- [ ] Authentication failures and account-linking conflicts show a recoverable next step
- [ ] A new user can link SimpleFIN natively from the product without a separate manual import workflow
- [ ] A linked SimpleFIN account can ingest transactions and balances
- [ ] The user can see imported transactions after the sync completes
- [ ] A user can disconnect and reconnect a provider connection without deleting the associated budget history
- [ ] Provider credentials or access URLs are handled according to provider requirements and are not exposed in normal transaction views
- [ ] The user can select which discovered accounts to include in the budget

### SimpleFIN ingestion

**Story:** As a budget owner, I want SimpleFIN accounts and history imported reliably so that my tracking budget starts with an accurate picture of my finances.

**Acceptance criteria:**
- [ ] The initial SimpleFIN sync requests and imports the maximum historical transaction data the provider makes available, which may currently be limited to approximately six months
- [ ] Sync requests use overlapping date windows so boundary transactions are not missed between requests
- [ ] The system deduplicates records returned by overlapping windows without creating duplicate transactions
- [ ] The system discovers all eligible accounts exposed by the connected SimpleFIN connection and shows them for confirmation
- [ ] Imported account balances are reconciled against the provider’s current balances and discrepancies are surfaced
- [ ] The system creates or calculates an opening balance when imported history does not explain the account’s starting balance
- [ ] A user can review and correct an opening balance without editing imported transactions
- [ ] Correcting an opening balance reconciles the account’s displayed balance without rewriting provider-sourced transactions
- [ ] A subsequent sync preserves previously imported records and only adds or updates provider records safely
- [ ] Provider-specific sync state and identifiers are retained for reliable incremental synchronization
- [ ] Each imported transaction and account retains a stable provider identifier for idempotent updates and reconciliation
- [ ] A partial provider failure identifies affected accounts while preserving successfully imported data
- [ ] Provider-reported pending, updated, and removed records are handled without duplicating or silently losing transaction history

### Scheduled synchronization and categorization

**Story:** As a budget owner, I want account sync and transaction categorization to happen automatically on a provider-compatible schedule so that my budget stays current without manual refreshes.

**Acceptance criteria:**
- [ ] The system schedules recurring SimpleFIN syncs using a cadence compatible with provider terms, limits, and operational guidance
- [ ] The scheduler respects provider rate limits and does not issue requests more frequently than allowed
- [ ] Sync jobs use retries, backoff, and failure handling appropriate to transient provider errors
- [ ] A successful sync triggers AI auto-categorization for new or changed transactions, subject to configured provider and system limits
- [ ] Categorization jobs are idempotent and do not overwrite user-confirmed categories without explicit permission
- [ ] The system records sync and categorization status, timestamps, failures, and the next scheduled attempt
- [ ] Users can see when data was last updated and manually request a refresh when permitted by provider limits
- [ ] A failed sync or categorization job does not block later scheduled attempts or corrupt existing account, transaction, or budget data
- [ ] The scheduling boundary supports future providers with different sync capabilities, rate limits, and cadence requirements
- [ ] Scheduled jobs are scoped to the correct user and account connection and do not run after a connection is revoked

### Provider extensibility

**Story:** As the product team, we want a provider-neutral ingestion boundary so that additional financial-data providers can be added after MVP without rewriting budgeting logic.

**Acceptance criteria:**
- [ ] Imported accounts, transactions, balances, and sync results use provider-neutral product models
- [ ] A versioned provider contract defines connection setup, account discovery, history limits, incremental sync, balances, pending/updated/removed records, errors, rate limits, and refresh capabilities
- [ ] The first SimpleFIN adapter is implemented behind that contract rather than called directly from budget or reporting code
- [ ] Provider-specific identifiers and raw metadata can be retained for reconciliation and troubleshooting
- [ ] Provider-specific credentials, tokens, setup flows, and subscription/payment assumptions are isolated from the product profile and budget domain
- [ ] Adding a future provider does not require changes to category targets, pace calculations, or reporting contracts
- [ ] SimpleFIN remains the only required financial-data provider for the first release

### Provider economics and migration

**Story:** As a product owner, I want to change or add financial-data providers without changing the user’s budget so that Nemeo can preserve affordability and connection reliability.

**Acceptance criteria:**
- [ ] Provider selection is represented separately from budgets, accounts, and transactions
- [ ] A user’s imported history, categories, transfer mappings, targets, and reports remain intact if a provider connection is disconnected or replaced
- [ ] The product can distinguish provider cost paid by Nemeo from provider cost paid directly by the user
- [ ] SimpleFIN’s user-paid subscription requirement, if applicable, is disclosed before the user begins linking accounts
- [ ] Provider replacement and migration preserve stable internal accounts and transaction identities where a safe match exists, and surface records requiring review
- [ ] Provider evaluation captures target-bank coverage, history availability, refresh behavior, reauthorization frequency, data quality, rate limits, setup fees, minimums, and per-connection costs

### Budget setup

**Story:** As a budget owner, I want to create a tracking budget and define category targets so that I can understand spending without allocating every dollar.

**Acceptance criteria:**
- [ ] A user can create a budget
- [ ] A user can create one or more categories within that budget
- [ ] Each category has a name and a target amount or limit
- [ ] A budget has explicit start and end dates and a timezone used consistently for periods, schedules, and reports
- [ ] Budget setup does not require the user to assign available cash to categories
- [ ] A usable budget can be inferred from recent activity and reviewed before activation

### Budget automation

**Story:** As a budget owner, I want the system to seed and maintain my budget conservatively so that it stays useful without requiring constant manual upkeep.

**Acceptance criteria:**
- [ ] The system can seed category targets from historical spending, using available history and clearly showing the basis for each suggested target
- [ ] When history is sparse or unreliable, the system uses conservative defaults, marks uncertainty, and avoids presenting guesses as established spending patterns
- [ ] A user can set category caps that automated seeding and rebalancing cannot exceed without confirmation
- [ ] A user can protect categories from automated target changes or clearing/reset actions
- [ ] The system can carry category target variances into the next monthly budget period according to the configured carryover policy
- [ ] A user can preview and approve automated budget rebalancing before targets change, except where the user has explicitly enabled automatic rebalancing
- [ ] Rebalancing respects category caps and protected categories and explains each proposed change
- [ ] A user can clear or reset the current budget, selected categories, or automation suggestions without deleting imported transactions
- [ ] Clear and reset actions require explicit confirmation and state exactly what will and will not change
- [ ] Clearing or resetting a budget preserves an auditable history of prior targets and user decisions
- [ ] A user can reorder categories for display without changing transaction categorization or calculations
- [ ] A user can maintain the category taxonomy by renaming, merging, splitting, archiving, and restoring categories with an appropriate transaction-history policy
- [ ] Taxonomy changes do not silently change historical spending totals or pace results
- [ ] Automation records the prior and new target, the reason for the change, and whether the user approved it

### Basic reporting and dashboarding

**Story:** As a budget owner, I want a simple current-month dashboard so that I can quickly understand whether my budget is on pace and what needs my attention.

**Product decision:** The dashboard is Nemeo’s primary home surface. It answers one question first:
“How is my budget doing this month?” The current month’s overall progress and categories that are
off pace are immediately visible. Users drill down to category, transaction, or review details
only when they need more explanation or want to take action. The review queue is a follow-up
workflow, not the primary home surface.

The primary drill-down loop is **Dashboard → Budget/category → Transactions**. The Dashboard
establishes the current pace, the Budget view explains the affected target or category, and the
Transactions view provides the evidence to correct a categorization or understand why spending is
different than expected. Connections, setup, household access, and agent workflows support this
loop without competing with it as the main daily navigation.

**Reference prototype:** [`dashboard-mockup.html`](../../dashboard-mockup.html) illustrates the
intended MVP hierarchy and interaction shape. It is a review aid, not a second source of product
behavior; the PRD, Event Model, and API contracts remain authoritative.

The prototype’s visual direction is quietly intelligent rather than futuristic: a soft
indigo/graphite foundation, mint for healthy/on-pace states, and warm amber for ahead-of-pace
warnings. The final Nemeo brand and robot language remain subject to product issue #11.

**Acceptance criteria:**
- [ ] The dashboard defaults to the current calendar month and clearly shows the reporting period
- [ ] The dashboard leads with a concise overall budget status, including actual spend, target, expected spend for elapsed time, and current pace status
- [ ] The dashboard header stays compact, showing the selected reporting period without a greeting or other content competing with the budget status
- [ ] The dashboard shows a compact cashflow summary with cash inflows, cash outflows, and net cashflow for the current month
- [ ] Transfers and credit-card payments are excluded from cashflow income and spending totals, while remaining available in transaction detail when relevant
- [ ] Budget progress is shown as a line graph over the selected period with actual spending and target/expected pace
- [ ] The dashboard prominently identifies categories that are ahead of pace, ordered by actionable impact, and links to the relevant budget or transactions
- [ ] Specific pace warnings appear directly beneath the overall budget progress and before secondary cashflow detail
- [ ] When no categories are ahead of pace, the dashboard clearly communicates that the budget is currently on track
- [ ] The dashboard provides a path from each pace warning to the affected category, relevant transactions, and any applicable review action
- [ ] Other review items are available from the dashboard without displacing the overall budget status or pace exceptions, prioritized by impact and confidence/attention required
- [ ] Category and merchant rankings use the same transfer, refund, and non-spending treatment as budget calculations
- [ ] Empty, partial, or insufficient-history states are explained without presenting misleading comparisons
- [ ] Dashboard values link to the underlying transactions or category details for review
- [ ] The current month’s partial-period data is labeled as partial and is not presented as a complete-month comparison
- [ ] Cashflow, rankings, and graphs use the same account inclusion, transfer, refund, and date/timezone rules

**Deferred dashboard enhancements:**

Comparisons with last month or a historical average, top-category and top-merchant rankings, and
additional dashboard personalization may be added after the MVP glanceable current-month status
and drill-down workflow are working well. If rankings are included in the first implementation,
they remain secondary content below the overall status and pace exceptions.

### Transaction review

**Story:** As an AI power user, I want to browse and review transactions so that I can understand spending patterns.

**Acceptance criteria:**
- [ ] The transaction list loads successfully for linked accounts
- [ ] Imported transactions are visible with core fields such as date, amount, merchant, and category when available
- [ ] The user can view transaction history without needing the MCP server
- [ ] The user can filter or search transactions by account, date, payee, category, transfer status, and review status
- [ ] The user can see whether a transaction was imported, categorized automatically, categorized by a user, or marked as a transfer

### Transaction cleanup automation

**Story:** As an AI power user, I want the system to clean up transaction data automatically so that I do not have to do manual bookkeeping.

**Acceptance criteria:**
- [ ] The system can detect likely duplicate transactions and surface them as a cleanup task or auto-resolve them when confidence is high
- [ ] The system can identify likely transfers and keep them from distorting spending analysis
- [ ] The system can split or adjust transactions when needed for accurate categorization
- [ ] Cleanup actions are driven by automation or AI rather than manual data-entry workflows

### Transfer correctness

**Story:** As a budget owner, I want transfers between my accounts identified correctly so that moving money does not double-penalize my budget or appear as income.

**Acceptance criteria:**
- [ ] The system represents a transfer with canonical source-account, destination-account, and direction mappings
- [ ] Matching transaction pairs across linked accounts are identified as one transfer rather than two spending or income events
- [ ] The system provides native transfer payees for common transfer relationships, including credit-card payments
- [ ] Users and authorized agents can create, review, disable, and update transfer rules
- [ ] Transfer rules can use account pair, transaction direction, normalized payee, amount, timing, and other supported signals
- [ ] Historical transactions can be retagged as transfers when a new match or rule is confirmed
- [ ] Transfer candidates are presented as suggestions with the matched source and destination accounts and require user confirmation unless an explicitly user-approved transfer rule matches
- [ ] Unconfirmed transfer candidates retain ordinary income/spending treatment until confirmed
- [ ] The system detects duplicate transfer records, preserves the canonical transfer, and provides a cleanup path for duplicates
- [ ] Transfers are excluded from income totals, spending totals, category actuals, and budget pace calculations
- [ ] Credit-card payments are not treated as income, spending, or new budget activity on either side of the payment
- [ ] Users can inspect why a transaction was identified as a transfer and correct a false positive without losing the underlying transaction

### Categorization and tracking

**Story:** As a budget owner, I want transactions categorized and reflected against tracking targets so that the budget stays accurate with minimal maintenance.

**Acceptance criteria:**
- [ ] A transaction can be assigned to a category
- [ ] A transaction can be reassigned to a different category
- [ ] A categorized transaction is reflected against the correct category’s actual spend
- [ ] Uncategorized transactions remain visible until they are assigned
- [ ] Category actuals and remaining target update when categorized transactions are applied
- [ ] Transfers and other non-spending transactions are excluded from spending actuals
- [ ] AI assignments include a confidence or review state that is visible to the user
- [ ] A user-confirmed category is not overwritten by scheduled AI categorization without explicit permission
- [ ] A user can correct an AI assignment directly from transaction or review context and choose to remember the change as a reusable payee or category rule
- [ ] Low-confidence assignments remain usable in the budget and are available in an optional prioritized review queue; transactions with no usable category remain visible as exceptions
- [ ] A remembered category rule applies to future matching transactions by default and requires explicit action before retagging historical transactions

### Budget pace alerts

**Story:** As a budget owner, I want a warning when spending is ahead of pace so that I can adjust before exceeding a category target.

**Acceptance criteria:**
- [ ] The system calculates pace status for each tracked category with a target
- [ ] A category is marked ahead of pace when actual spend and elapsed-period timing indicate likely target overrun
- [ ] The user can see actual spend, target, elapsed period, projected spend, and the reason for the warning
- [ ] An in-product warning identifies the affected category and links to relevant transactions or a review action
- [ ] The system avoids repeated duplicate warnings for the same category and budget period
- [ ] Users can dismiss or snooze a warning without changing transaction data
- [ ] The system does not issue an ahead-of-pace warning when the category lacks a target or has insufficient period data

### MCP access

**Story:** As an AI power user, I want an MCP server that exposes transaction data so that Claude or another agent can inspect my finances.

**MVP deployment and agent policy:**

- Nemeo supports both a local MCP connection for self-hosted or desktop-agent workflows and a hosted MCP endpoint for a future managed deployment. Both modes expose the same product capabilities and safety policy.
- Every MCP request is bound to one authenticated Nemeo user and, where applicable, one household. A local connection is not a bypass around identity, household membership, or resource authorization.
- Read and explain operations are available without per-request confirmation. They may include transactions, budgets, categories, targets, pace status, dashboard reports, review items, and connection/sync status within the caller’s authorized scope.
- Suggestions are non-mutating by default. An agent may propose a categorization, transfer match, budget change, or rule and explain the evidence, but the proposal does not change user data until accepted.
- Mutations require explicit user confirmation by default. This includes changing categories, confirming transfers, changing targets or rules, bulk or historical retagging, changing connections, and deleting data.
- A user may explicitly authorize a narrowly scoped reusable rule or automation after reviewing its scope. The authorization must be visible, revocable, and unable to override user-confirmed assignments, transfer safeguards, household permissions, or deletion protections.
- Every agent action is attributable and auditable. The audit record identifies the user/household, agent or MCP client, capability used, affected resource, requested change, confirmation state, outcome, and time. Users can inspect this history and failed or rejected actions do not appear as successful mutations.
- Rate limits and dependency failures are presented as actionable status to the user or agent. Reads may be retried safely; mutations use idempotency and never report success when the outcome is unknown. Provider or authorization failures fail closed and do not partially apply an unconfirmed action.

**Acceptance criteria:**
- [ ] The MCP server supports both local and hosted deployment modes with the same user-facing safety policy
- [ ] An external agent can read transaction data through the MCP surface
- [ ] An external agent can read budgets, categories, targets, pace status, and dashboard report data through the MCP surface
- [ ] Every request is limited to the connected user’s authorized household and resources
- [ ] Read and explain operations do not require per-request confirmation
- [ ] Suggestions do not mutate state until accepted
- [ ] Mutations are explicitly confirmed by default, including category changes, transfer confirmation, budget/rule changes, connection changes, bulk retagging, and deletion
- [ ] User-approved reusable rules are scoped, visible, revocable, and cannot bypass domain safeguards
- [ ] Agent actions record actor, capability, target, confirmation state, outcome, and timestamp
- [ ] Users and agents receive clear rate-limit, authorization, dependency, and unknown-outcome failures

### Family progress

**Story:** As a family viewer, I want to check budget progress so that I can understand whether spending is on track.

**Acceptance criteria:**
- [ ] A viewer can open a simplified progress screen on mobile
- [ ] The screen shows budget-period progress and recent transaction impact
- [ ] The screen is understandable without requiring budget setup actions
- [ ] A viewer cannot change transactions, categories, budgets, connections, or household access

### Household edits

**Story:** As a household budget manager, I want to edit transaction categorization so that the shared budget stays accurate.

**Acceptance criteria:**
- [ ] A household budget manager can change a transaction category
- [ ] The change updates the associated category actuals and pace status
- [ ] The update is visible to other household members

### Household access

**Story:** As a budget owner, I want to share a budget with household members using clear roles so that collaboration does not expose more financial control than intended.

**MVP role model:**

- Nemeo has two product roles: **household budget manager** and **viewer**.
- The manager is responsible for maintaining the household budget and can manage budgets, targets, transactions, categories, rules, connections, transfer confirmations, invitations, and access.
- A viewer can read the dashboard, budgets, transactions, pace status, and reports, but cannot change financial data, connections, or household access.
- The common household shape is one manager with one or more viewers. Additional managers use the same manager role; MVP does not introduce a separate co-manager role.
- Roles are fixed bundles in MVP. Users cannot create custom roles or configure per-resource or per-field permissions.

**Acceptance criteria:**
- [ ] A household budget manager can invite a household member and revoke the invitation or access
- [ ] Each household member has exactly one explicit MVP role: household budget manager or viewer
- [ ] Viewers can read permitted progress, budgets, transactions, pace status, and reports without changing state
- [ ] Household budget managers can perform the MVP budget, transaction, connection, transfer, invitation, and access-management actions
- [ ] Invitations have explicit pending, accepted, expired, and revoked states
- [ ] Permission changes take effect for subsequent requests and are recorded in an access history
- [ ] MVP does not expose custom roles, arbitrary policy configuration, or field-level sharing controls

### AI-assisted analysis

**Story:** As an AI power user, I want the system to help me analyze and optimize my budget so that I can improve my savings without doing the work manually.

**AI assistance and autonomy policy:**

- Nemeo’s native AI/automation scope is intentionally narrow for MVP: transaction classification, transfer matching, and budget setup or target automation. The product does not need to ship a general-purpose conversational AI, chat assistant, or model-provider experience.
- At the MCP boundary, **explain**, **suggest**, **classify**, and **execute** describe capability types that external agents can compose. They do not imply that Nemeo itself owns the conversational model or must implement every capability as an in-product AI feature.
- **Explain** capabilities provide authorized facts, calculations, evidence, and structured context, such as why a category is ahead of pace, which transactions contributed, or how a report was calculated. An external agent may turn that context into a natural-language explanation; the underlying operation is read-only and does not require confirmation.
- **Suggest** capabilities expose data and supported proposals for a change, intervention, target, report, or next step. A suggestion may be represented as a read-only insight, classification or transfer candidate, or hypothetical preview; it is not a generic mutable “suggestion” resource. Proposals show expected impact and supporting evidence, remain non-mutating until accepted, and can be dismissed, snoozed, or regenerated by the consuming experience.
- **Classify** means organize imported data using Nemeo’s native automation. Transaction categorization follows the automatic, confidence-aware policy in this PRD; transfer matches remain confirmation-first. User-confirmed assignments and remembered rules are protected from silent replacement.
- **Execute** means invoke a Nemeo command through an authorized client, including an external agent using MCP. Execution requires explicit confirmation by default, with the action, scope, affected records, and expected impact shown before it is applied. Bulk changes, historical retagging, connection changes, budget changes, and deletion require explicit action even when an agent has a reusable rule.
- A user may authorize a narrowly scoped reusable rule or automation after reviewing what it can change. The authorization is visible and revocable, applies only to matching future operations, and cannot bypass permissions, transfer safeguards, user-confirmed assignments, or deletion protections.
- Classification confidence is an explanation and review signal, not a claim of certainty. Nemeo and consuming agents use clear language such as “suggested,” “likely,” and “needs a second look,” and show the evidence or basis available without implying a calibrated probability when one is not available.
- Nemeo and its external-agent integrations do not provide financial advice or independently open accounts, move money, apply for financial products, or make commitments outside Nemeo. Product language must distinguish observed facts, estimates, suggestions, and committed changes.
- The same authorization, confirmation, audit, and domain-invariant rules apply whether a command is initiated by the web app, a local agent, or a hosted MCP client.

**Acceptance criteria:**
- [ ] MCP capabilities are categorized as explain, suggest, classify, or execute without requiring Nemeo to ship a general-purpose conversational AI
- [ ] Explain operations are read-only and identify the relevant data or period
- [ ] Suggestions show expected impact and supporting evidence and can be dismissed, snoozed, or regenerated without mutating state
- [ ] Suggestions are exposed as read-only insights, candidates, previews, or external-agent proposals rather than a generic mutable suggestion resource
- [ ] Accepting a suggestion uses the relevant explicit domain command and does not create a parallel suggestion-specific mutation model
- [ ] Nemeo’s native AI/automation scope is limited to classification, transfer matching, and budget setup or target automation for MVP
- [ ] External agents can use authorized MCP data to identify patterns, propose category target changes or spending interventions, and generate or improve reports
- [ ] Categorization and transfer behavior follows the accepted confidence and confirmation policies
- [ ] State-changing commands initiated by an external agent require explicit confirmation by default and clearly identify scope and impact
- [ ] Reusable automation rules are scoped, visible, revocable, and unable to bypass permissions or domain safeguards
- [ ] Native classification and MCP read capabilities expose available evidence and uncertainty without overstating confidence
- [ ] Suggestions and commands are reversible or dismissible where appropriate and never silently overwrite protected user decisions
- [ ] Product language does not imply financial advice or autonomous financial-product actions
- [ ] The analysis surface can be used by an external AI agent through MCP

### Security and data lifecycle

**Story:** As a user of a financial-data product, I want my data and access to be protected so that connecting accounts does not create unnecessary exposure.

**Lifecycle direction (MVP):** Nemeo supports account deletion and provider disconnection without
committing to product-specific retention durations yet. Account deletion revokes access and
provider credentials and removes the user’s personal, financial, and derived data from active
systems. Disconnecting a provider immediately revokes its credentials and prevents future
scheduled synchronization while preserving already imported history and budget decisions.

Exact retention periods, deletion schedules, backup handling, export formats, legal exceptions, and
policy overrides are deferred until required by launch policy or legal review. Until then, any
necessary exceptions are handled manually and access to retained data remains restricted.

**Acceptance criteria:**
- [ ] A user can access only their own accounts, transactions, budgets, reports, and provider connection details unless explicitly shared
- [ ] Household and MCP access checks are enforced server-side for every read and write operation
- [ ] Provider credentials, tokens, and connection secrets are encrypted and excluded from logs and ordinary API responses
- [ ] Disconnecting a provider prevents future scheduled syncs while preserving already imported data according to the product’s retention policy
- [ ] Account deletion revokes access and provider credentials and removes the user’s personal, financial, and derived data from active systems
- [ ] A disconnected provider’s imported history and budget decisions remain available until the account is deleted or a later retention policy applies
- [ ] Sensitive access and mutation events are recorded for audit and troubleshooting

## Release phases

### MVP

The MVP should get a household from account linking to a usable budget with minimal manual work.

Includes:
- Setup automation
- Low-maintenance budget operation
- Account onboarding
- SimpleFIN ingestion
- Provider extensibility boundary
- Provider-neutral account-connection contract and first adapter boundary
- Transfer correctness
- Budget setup
- Budget automation
- Scheduled synchronization and categorization
- Basic reporting and dashboarding
- Transaction review
- Categorization and tracking
- Budget pace alerts
- Google authentication
- MCP access
- Family progress
- Household access
- Household edits

### Post-MVP

These capabilities should be designed for, but can ship after the first usable product:

- Transaction cleanup automation
- AI-assisted analysis
- Core budget portability / export
- Advanced reporting depth
- Local-first/offline-first architecture
- Additional authentication providers
- Optional envelope-style allocation

## Assumptions and constraints

| Type | Item | Impact if wrong |
|------|------|-----------------|
| Assumption | The best first value is agent-friendly tracking, not a full consumer finance suite | If wrong, the product scope may need to expand significantly |
| Assumption | Users are willing to connect bank or card accounts through a supported data provider | If wrong, transaction ingestion becomes a blocking problem |
| Constraint | The product must work well with desktop, always-on, and mobile agents | If wrong, the core differentiation weakens |
| Constraint | Privacy and security expectations are high because the product touches financial data | If wrong, trust and adoption suffer |
| Constraint | Budget pace warnings must be understandable and conservative enough to avoid alert fatigue | If wrong, users may ignore the product |
| Constraint | Transfer classification must be conservative and explainable because false positives can hide real spending | If wrong, budget totals and user trust suffer |
| Constraint | Budget automation must be reversible and must not overwrite transactions or silently change protected categories | If wrong, users lose control of their financial history |
| Constraint | Pricing must remain close to the SimpleFIN cost and must not require revenue from financial-product referrals | If wrong, the product may become unaffordable or lose user trust |

## Dependencies and risks

| Dependency / risk | Type | Owner | Notes |
|-------------------|------|-------|------|
| Provider-neutral connection and ingestion contract | Dependency | TBD | Must be designed and implemented before the SimpleFIN adapter so future providers can be added without changing budgeting or reporting logic |
| SimpleFIN integration | Dependency | TBD | First adapter for guided account linking, provider-available historical backfill, sync, and balance reconciliation; user-paid subscription economics remain an open commercial constraint |
| Follow-on provider evaluation | Dependency | TBD | Needed to determine whether Nemeo can bundle connectivity into one affordable subscription; evaluate Akoya and other OAuth/API providers against target-bank coverage and economics |
| MCP server hosting | Dependency | TBD | Needed to expose data to agents reliably |
| Authentication and authorization | Dependency | TBD | Must isolate each user’s financial data |
| Google identity integration | Dependency | TBD | Needed for low-friction MVP signup/login; should leave room for additional providers |
| Transfer matching and normalization | Dependency | TBD | Needed to map account directions, transfer payees, rules, historical retagging, and duplicate cleanup |
| Budget automation engine | Dependency | TBD | Needed for historical seeding, caps, protected categories, carryover, rebalancing, reset tools, and taxonomy maintenance |
| Job scheduler and provider policy handling | Dependency | TBD | Needed for provider-compatible SimpleFIN sync, retries, rate limits, and scheduled AI categorization |
| Privacy and security review | Risk | TBD | Financial data raises the bar for storage, transport, and access control |
| Mobile app surface | Dependency | TBD | Needed for the family viewer experience |

## Open questions

| # | Question | Owner | Due |
|---|----------|-------|-----|
| Q1 | What SimpleFIN connection flow and credential-handling approach should the MVP use? | jho | Before implementation |
| Q3 | What level of read access should the family viewer have in v1? | jho | TBD |
| Q5 | Which mobile platform should we prioritize first? | jho | TBD |
| Q6 | What should the final product name be, and should the repository/docs be renamed with it? | jho | Before implementation |
| Q7 | Should pace use only elapsed calendar time, or account for income timing and known recurring bills? | jho | Before alert implementation |
| Q8 | Which in-product alert controls are required for MVP: dismiss, snooze, thresholds, or all three? | jho | Before alert implementation |
| Q9 | Do existing envelope concepts/data need to be migrated, or can the product make a clean model transition? | jho | Before implementation |
| Q11 | Does monthly carryover apply to unused target, overspend variance, or both, and should it be opt-in per category? | jho | Before implementation |
| Q12 | Which categories should be protected by default, if any? | jho | Before implementation |
| Q13 | What default sync cadence should we use within the limits and guidance of SimpleFIN, and should users be able to customize it? | jho | Before implementation |
| Q14 | What historical window should define the average comparison baseline? | jho | Before dashboard implementation |
| Q15 | What confidence threshold should send an AI categorization to review instead of applying it automatically? | jho | Before categorization implementation |
| Q16 | What is the retention and deletion policy for disconnected provider data, audit history, and user accounts? | jho | Before implementation |
| Q18 | What exact monthly price ceiling keeps the product only marginally more expensive than connectivity and AI costs while covering hosting and operations? | jho | Before pricing implementation |
| Q19 | Can SimpleFIN offer sponsored, bundled, reseller, or developer pricing that avoids requiring each Nemeo user to maintain a separate Bridge subscription? | jho | Before committing to SimpleFIN as the only customer-facing connection path |
| Q20 | Which provider should be the first bundled-cost alternative to SimpleFIN, and what minimum target-bank coverage is required? | jho | Before production pricing and launch |
