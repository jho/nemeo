# ADR 0016: Bounded Native AI Automation with an External-Agent Intelligence Boundary

- Status: Accepted
- Date: 2026-10-02
- GitHub issue: [#22](https://github.com/jho/nemeo/issues/22)
- Product decisions: [#7](https://github.com/jho/nemeo/issues/7), [#8](https://github.com/jho/nemeo/issues/8)
- Related architecture: [ADR 0011](0011-domain-persistence-and-event-strategy.md), [ADR 0013](0013-contract-driven-mcp-exposure.md), [ADR 0015](0015-postgres-automation-jobs-and-scheduling.md)

## Context

Nemeo needs AI-assisted automation for its low-maintenance budgeting promise, but it is not
building a general-purpose conversational assistant. The product owns bounded background work such
as transaction categorization, transfer suggestions, and initial budget setup. Deep questioning,
financial introspection, explanations, and broader user-directed interactions belong to external
AI agents using the MCP surface.

The architecture must keep the inexpensive, server-side automation path replaceable while ensuring
that AI output cannot bypass domain commands, authorization, user confirmation, or event-sourced
history.

## Decision

Nemeo will use two explicit AI planes.

### 1. Nemeo-managed automation plane

MVP uses one Nemeo-selected, server-side, low-cost model provider behind a Nemeo-owned adapter.
OpenRouter's free tier is a candidate for development and controlled alpha use while Nemeo tests
quality, cost, availability, and data handling. A free or cheap provider MAY become the production
provider only after explicit testing and review of its model terms, commercial-use rights, privacy
behavior, retention, limits, and operational suitability. This provider choice MUST NOT become part
of the domain contract.
The adapter is limited to bounded task capabilities:

- transaction categorization;
- transfer-match suggestions;
- initial category and target inference during budget setup; and
- budget or pace recommendations only when invoked by an explicitly defined product workflow.

The provider is configured by Nemeo operations. MVP does not require users to supply model API keys,
and Nemeo does not expose a general chat or open-ended completion capability to product code.

The implementation MUST use a maintained multi-provider SDK or wrapper behind the Nemeo-owned
adapter, rather than calling OpenRouter's protocol directly from feature code. A library such as
Vercel AI SDK may be evaluated for this role, but the exact library remains an implementation
choice. The provider SDK, request types, response types, and model-specific behavior MUST remain
inside the infrastructure adapter. Application code depends on task-specific Nemeo-owned ports and
structured proposal types, not a generic chat-completion API. For example:

```text
automation job or application workflow
  → task-specific AI provider port
  → provider adapter
  → validated proposal
  → domain command
  → event / projection update
```

The adapter proposes. It MUST NOT mutate domain state, append domain events, update projections, or
decide whether a user is authorized to apply a result.

### 2. External-agent intelligence plane

ChatGPT, Claude, and other external agents supply their own model and conversational experience
through MCP. Nemeo exposes authorized API/MCP capabilities for reading data, explaining results,
asking questions, and executing permitted commands. Nemeo does not store or select the external
agent's model credentials as part of this decision.

The external-agent plane MUST use the same application capabilities, authorization, confirmation,
tenancy, and domain invariants as the web client. MCP is not a bypass around the automation plane or
the domain model.

## Proposal and validation contract

Each native AI operation has an operation-specific input and output schema. Provider responses MUST
be validated at the adapter boundary before they become application proposals. Invalid, incomplete,
or policy-incompatible output becomes a failed or reviewable automation result; it is never applied
implicitly.

Every proposal MUST retain enough provenance to explain and reproduce the decision, including:

- operation and schema versions;
- provider and model identifiers;
- prompt or instruction template version;
- confidence and policy/review state;
- timestamp, actor/source, and correlation identifiers; and
- the affected aggregate or transaction identifiers.

Applying a proposal always goes through a normal domain command. The command rechecks authorization,
invariants, concurrency, and user-confirmation requirements.

## Confidence and review behavior

The product policy remains authoritative for user-visible confidence behavior:

- categorization may apply the best usable candidate, including lower-confidence assignments, while
  preserving its AI/rule/user-confirmed provenance;
- no usable categorization remains an exception for review;
- user-confirmed categories and user-approved rules MUST NOT be silently overwritten;
- transfer matching is confirmation-first and an AI suggestion is never itself a transfer;
- budget setup suggestions are reviewable and respect category caps and protected categories; and
- model improvements create new suggestions or decisions and do not silently rewrite historical
  facts or user decisions.

## Privacy, cost, and operations

- The automation adapter MUST send only the minimum non-PII context required for its bounded task.
  The default transaction classification payload is limited to a normalized payee/merchant value,
  amount, currency, and the non-sensitive category or policy context required for the operation.
- AI requests MUST exclude names, email addresses, household identifiers, account numbers, provider
  identifiers, credentials, raw provider payloads, free-form transaction descriptions when they may
  contain PII, and unrelated transaction history. Payee values MUST be normalized or redacted when
  they appear to contain personal information.
- Production provider/model selection MUST use an explicit allowlist. Nemeo MUST NOT use a dynamic
  free-model router in production when it cannot identify and verify the selected model and provider
  terms for each request.
- Provider credentials and SDK details remain in configuration/adapter infrastructure and never enter
  domain events or API contracts.
- Provider selection MUST be configuration-driven so the initial OpenRouter candidate can be
  replaced by a direct OpenAI, Anthropic, Google, local, or other supported provider without
  changing domain or application contracts.
- The production review MUST verify the selected model's commercial-use/license terms, upstream
  provider data practices, retention/training behavior, rate limits, and failure/availability
  characteristics. Free-tier availability alone is not a production suitability signal.
- Automation runs through the existing job and scheduler boundaries, with bounded cost/rate limits,
  retries, and observable failures.
- A provider outage or invalid response must not corrupt imported data, current domain state, or
  previously confirmed decisions.
- The adapter boundary permits replacing the initial low-cost provider or adding a deterministic
  implementation without changing domain behavior.

## Alternatives considered

### One general Nemeo AI/chat abstraction

Rejected. A generic completion port would encourage product code to depend on provider-shaped
concepts and blur the boundary between bounded automation and external-agent conversation.

### User-supplied model keys for Nemeo automation

Deferred. It adds onboarding, secret storage, provider selection, cost, and support complexity to
MVP. External agents already let users choose their own model through MCP.

### Deterministic-only MVP

Rejected as the primary path. Rules remain valid adapters and safety fallbacks, but bounded AI
automation is part of Nemeo's low-maintenance product promise.

### In-product conversational assistant

Deferred. If product metrics justify it later, it should be a thin MCP-backed interface rather than
a separate conversational architecture.

## Consequences

Nemeo can use an inexpensive model for repetitive classification while reserving deep reasoning and
conversation for the user's existing AI agent. Domain behavior remains deterministic, authorized,
auditable, and testable regardless of provider output.

The tradeoff is maintaining operation-specific schemas, provenance, provider evaluation, and review
handling. The first implementation should keep the port narrow and add a new AI operation only when
its product workflow, proposal schema, failure behavior, and domain command are explicit.
