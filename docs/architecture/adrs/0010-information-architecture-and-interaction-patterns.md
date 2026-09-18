# ADR 0010: Dashboard-First Information Architecture and Review Interactions

- Status: Accepted
- Date: 2026-09-18
- GitHub issue: [#15](https://github.com/jho/nemeo/issues/15)
- Product inputs: [#2](https://github.com/jho/nemeo/issues/2), [#4](https://github.com/jho/nemeo/issues/4)
- UI platform: [ADR 0008](0008-ui-platform-and-rendering-strategy.md)
- UI foundation: [ADR 0009](0009-ui-component-library-and-design-system.md)

## Context

Nemeo is intended to reduce budgeting work to a short, understandable review. The product
decision in issue #4 makes the current-month dashboard the home surface: the user should quickly
understand overall budget progress, see what is off pace, and drill into details only when useful.
The dashboard prototype in [`dashboard-mockup.html`](../../dashboard-mockup.html) is the visual
reference for this hierarchy.

The Event Model defines capabilities and surfaces but does not decide how users move between them.
This ADR defines the MVP navigation, drill-down, review-queue, multi-item review, and responsive
interaction rules without changing domain behavior or permission policy.

## Decision

Nemeo will use a dashboard-first information architecture with four user-facing capability areas:

1. **Dashboard** — current-month status, progress, pace warnings, and concise supporting context.
2. **Budget** — targets, categories, category detail, and budget-period configuration.
3. **Transactions** — searchable transaction evidence and transaction detail.
4. **Connections** — linked-account status, sync health, and connection management.

Review is a secondary workflow reachable from Dashboard and Transactions. It is not the home
surface and does not become a separate competing dashboard.

## Navigation model

- Desktop uses a persistent application navigation with Dashboard, Budget, Transactions, and
  Connections. Account, help, and settings actions are secondary navigation and do not compete with
  the four primary areas.
- Mobile uses the same destinations and route semantics in a compact navigation treatment. Dashboard,
  Budget, and Transactions are the primary mobile destinations; Connections and secondary actions are
  available from the application menu.
- Routes use normal browser URLs and history. Primary workflows MUST be deep-linkable and MUST NOT
  exist only inside a modal or transient client state.
- A quick preview may use a drawer or dialog, but a full category, transaction, or review workflow
  has a routable destination and preserves a return path to the originating context.
- The responsive client presents the same information hierarchy on desktop and touch devices. It
  may reduce density, collapse navigation, and simplify supporting content, but it MUST NOT create a
  second mobile information architecture.

The initial route vocabulary is intentionally stable and capability-oriented:

```text
/dashboard
/budget
/budget/categories/:categoryId
/transactions
/transactions/:transactionId
/review
/connections
```

Exact route parameters and API operation names remain implementation details, but new routes should
follow the same resource and capability boundaries.

## Dashboard hierarchy

The Dashboard MUST render in this order for the current calendar month:

1. A compact reporting-period selector.
2. Overall budget status: actual spend, target, expected spend for elapsed time, and pace status.
3. Actual-versus-expected progress visualization with an accessible textual summary.
4. Pace warnings, directly beneath progress, ordered by actionable impact.
5. Secondary cashflow context and other review items.

The Dashboard answers “How is my budget doing this month?” before presenting rankings, historical
comparisons, or personalization. When no category is ahead of pace, it communicates that the budget
is on track rather than leaving an empty warning area. Empty, partial, insufficient-history, and
not-connected states explain what is known, what is missing, and what the user can do next.

## Pace-warning drill-down

Pace warnings are the primary exception interaction.

- Selecting a warning opens the affected category context and shows actual spend, target, expected
  spend, projected spend, elapsed period, and the reason for the warning.
- The category context provides explicit paths to filtered current-period transactions and the
  relevant budget/category detail. The originating dashboard context remains recoverable through
  normal back navigation or a visible return action.
- Transaction results opened from a warning retain the category, reporting period, and warning
  context as filters or visible context. Users must not have to reconstruct why they arrived there.
- Dismiss and snooze change warning presentation only; they do not change transaction data, targets,
  or pace calculations.
- Warning copy, status labels, icons, and supporting text MUST make the meaning understandable
  without relying on color or the robot/AI visual language.
- A warning is not an emergency state by default. The UI should communicate useful attention and
  next actions without guilt, alarm, or repeated interruption.

## Review queue

The review queue is a unified, filterable follow-up workflow. Its default ordering is:

1. Ahead-of-pace categories, ordered by actionable projected impact.
2. Low-confidence or uncategorized transactions that could change spending or pace understanding.
3. Transfer, duplicate, or other data-quality exceptions that could distort reporting.

Within the same priority class, newer items appear first unless the user selects another supported
sort. The queue is tenant/household scoped and respects the authorization rules defined separately
in issue [#20](https://github.com/jho/nemeo/issues/20).

The queue MUST show why an item is present, what data it affects, and the available next action.
Items that lack enough history or confidence are labeled as such rather than presented as certain
recommendations.

## Multi-item review behavior

MVP review is sequential, context-preserving, and explicitly user-controlled:

- A user opens one review item and can resolve, correct, dismiss, snooze, or skip it according to
  the item type and available permissions.
- After an action, the UI offers the next eligible item and preserves the active queue filters and
  ordering. It does not silently jump to an unrelated queue.
- The user can move to the previous or next item without losing the current review context.
- Actions that change categorization, transfer treatment, targets, or other durable data state show
  the resulting change and provide confirmation where the operation is ambiguous or consequential.
- Bulk mutation is out of MVP. The list may support bulk selection later, but the first workflow
  does not invent bulk semantics that would make financial changes harder to understand.

## Accessibility and responsive interaction

- All primary destinations, warnings, queue items, dialogs, drawers, and actions are keyboard
  reachable with visible focus and meaningful accessible names.
- Status and pace meaning is communicated through text, structure, and icons in addition to color.
- Dynamic review results and drill-down selections use appropriate polite announcements and move focus
  predictably when a dialog, drawer, or route changes the user’s task.
- Touch targets and gesture-free alternatives support the responsive PWA. No essential action is
  available only through hover, pointer precision, or a narrow-screen gesture.
- Charts and progress visuals have an accessible textual equivalent. Partial and insufficient data
  states are explicit and never imply a complete-month conclusion.
- The family-viewer experience uses the same Dashboard progress hierarchy with the capabilities
  allowed by the eventual household role policy; it does not introduce a separate budget model.

## Alternatives considered

### Review queue as the home surface

Rejected. It emphasizes maintenance work before answering the user’s primary question about current
budget progress and would make a low-maintenance product feel like a bookkeeping inbox.

### Dashboard-only experience with no review workflow

Rejected. Pace warnings, categorization confidence, and transfer exceptions need a coherent path to
resolution. Review remains subordinate, but it is still a first-class follow-up capability.

### Separate mobile information architecture

Rejected for MVP. It would duplicate product behavior and make desktop/mobile parity harder to
maintain. Responsive navigation and density changes are sufficient for the first client.

### Modal-only drill-downs

Rejected for full workflows. Quick previews are useful, but routable destinations are required for
deep links, browser history, accessibility, and reliable return paths.

## Consequences

Users get a short path from the dashboard answer to the specific evidence or action that explains
it. The hierarchy keeps pace warnings visible without turning normal budget variance into an alarm,
and it gives the family-viewer experience a clear foundation.

The tradeoff is a deliberately constrained MVP: no bulk review mutations, no separate mobile
information architecture, and no broad analytics workspace in the primary navigation. Those can be
added later without changing the core Dashboard → warning → detail flow.
