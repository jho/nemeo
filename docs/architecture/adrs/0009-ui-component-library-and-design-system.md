# ADR 0009: Owned UI Components and Semantic Design System

- Status: Accepted
- Date: 2026-09-17
- GitHub issue: [#14](https://github.com/jho/nemeo/issues/14)
- Product dependency: [#11](https://github.com/jho/nemeo/issues/11)
- Platform dependency: [ADR 0008](0008-ui-platform-and-rendering-strategy.md)

## Context

Nemeo needs consistent interaction and visual patterns across dashboards, charts, review queues,
forms, pace warnings, partial-data states, and the responsive family view. The product also needs
to express a distinctive robot/AI identity without coupling domain behavior to a third-party
component library.

The MVP is a React/Vite application built by a small team. We want accessible behavior for complex
controls, but we also need ownership of the visual layer so the product does not inherit a generic
material or vendor-specific look. Product issue #11 will decide the final Nemeo brand direction;
this ADR establishes the implementation foundation and semantic vocabulary that direction must use.

## Decision

Nemeo will use Tailwind CSS with CSS custom properties for design tokens and an owned set of
shadcn/ui-style components built on Radix UI primitives.

- Components are copied into and maintained in the Nemeo repository under the web interface. They
  are product source code, not an opaque runtime theme or remote registry dependency.
- Radix primitives provide behavior for complex controls such as dialogs, menus, popovers, tabs,
  tooltips, and keyboard/focus management. Nemeo owns the surrounding markup, styling, labels,
  composition, and product-specific variants.
- Tailwind utilities are an implementation tool, not the design system itself. Components MUST use
  semantic CSS variables/tokens rather than scattering raw brand colors or domain-specific hex
  values through feature code.
- The initial token groups are color, typography, spacing, sizing, radius, elevation, motion,
  responsive breakpoints, and focus indication. Brand values remain changeable until product issue
  #11 is resolved.
- Semantic status tokens MUST include at least `on-track`, `ahead-of-pace`, `needs-review`,
  `insufficient-history`, `error`, and `info`. Pace and review states MUST communicate through more
  than color alone, using text, icons, labels, or other accessible cues.
- Domain and API code MUST NOT import UI-library primitives. Feature slices map domain/view-model
  states to UI components through presentation code, keeping the design system replaceable.
- Robot/AI styling belongs in an identity layer of icons, illustrations, motion, copy, and empty
  states. It may decorate or explain a state, but it MUST NOT be the only carrier of an important
  warning, error, permission, or financial meaning.

## Candidate evaluation

| Candidate | Accessibility | Customization | Licensing/platform fit | Outcome |
|---|---|---|---|---|
| MUI | Mature component behavior and ecosystem | Themeable, but strongly associated with Material conventions | React, MIT core | Rejected for MVP because its visual defaults create unnecessary brand gravity |
| Mantine | Broad React component set | Good cohesive styling and theming | React, MIT | Rejected because adopting a large styled system reduces ownership of the visual layer |
| React Aria Components | Strong accessibility primitives | High styling control | React, MIT | Viable alternative, but requires more component assembly for the MVP surface |
| Radix + owned shadcn-style components | Strong WAI-ARIA, keyboard, and focus primitives | Maximum ownership of markup and styling | React/Vite, MIT-compatible open-source stack | Selected |

The selected approach follows the shadcn/ui ownership model while explicitly choosing Radix as the
MVP primitive layer. The underlying primitive choice can be revisited only if accessibility,
maintenance, or browser support evidence warrants it; feature code must continue to depend on
Nemeo-owned components.

## Required foundation

The first shared UI package must cover these primitives and states before feature slices invent
local equivalents:

- Primitives: button, link, icon button, text input, textarea, select, combobox, checkbox, radio,
  switch, form field, label, separator, card, badge, avatar, and icon wrapper.
- Interaction: dialog, alert dialog, sheet, popover, tooltip, dropdown menu, tabs, toast, command
  menu, confirmation flow, and responsive navigation shell.
- Data presentation: table/data table, sortable and paginated list, chart container, metric card,
  pace status indicator, review-queue row, filter controls, and detail panel.
- Resilient states: loading/skeleton, empty, partial data, recoverable error, permission denied,
  no connection, and insufficient history. Each state needs a clear message, an appropriate action
  or next step where possible, and accessible announcement/focus behavior.

Complex product components such as the spending dashboard, pace chart, and review queue are
composed in feature slices from these primitives. They are not added to the generic UI layer merely
because they appear in one screen.

## Consequences

Nemeo gets a consistent, accessible interaction foundation while retaining full control over the
visual identity. The robot/AI language can be warm and distinctive without changing the meaning of
financial status or making accessibility dependent on illustration.

The tradeoff is that Nemeo owns component maintenance and must keep the copied primitives current.
That cost is intentional: it avoids premature styling lock-in and keeps future design changes local
to the owned UI layer. The component source should remain small, composable, and limited to patterns
used by the product.
