# ADR 0022: Module-Path Logging Namespaces

- Status: Accepted
- Date: 2026-10-24
- Related implementation issue: [#64](https://github.com/jho/nemeo/issues/64)
- Related decisions: [ADR 0005](0005-modular-monolith-topology.md), [ADR 0021](0021-mvp-observability-and-incident-response.md)

## Context

Nemeo needs targeted operational logging as the modular monolith grows. A single process-wide
`LOG_LEVEL` is useful as a default but becomes too coarse when one provider adapter, worker, or
vertical capability needs more or less detail. Logger names must be stable, discoverable, and
consistent with the repository topology rather than becoming an arbitrary second taxonomy.

## Decision

Structured loggers use the normalized repository-relative TypeScript module path as the `module`
field and logging namespace. The path is derived from `import.meta.url`; `src/` and compiled
`dist/src/` prefixes are removed, file extensions are removed, `index` is omitted, and path
separators become dots.

Examples:

```text
src/interfaces/http/app.ts          -> interfaces.http.app
src/observability/instrumentation.ts -> observability.instrumentation
src/contexts/budget/pace/commands.ts -> contexts.budget.pace.commands
```

The namespace follows the actual module layout. Event Model slices may be organized under their
bounded context; the convention does not introduce a `src/slices` directory or require every
module to be event modeled.

Module-specific thresholds use the normalized namespace as an environment-variable suffix, with
most-specific configuration taking precedence:

```text
LOG_LEVEL_CONTEXTS_BUDGET_PACE_COMMANDS=trace
LOG_LEVEL_CONTEXTS_BUDGET_PACE=debug
LOG_LEVEL_CONTEXTS=info
LOG_LEVEL=warn
```

Only standard Pino levels are valid: `silent`, `fatal`, `error`, `warn`, `info`, `debug`, and
`trace`. Invalid values fall through to the next broader setting and ultimately `info`.

Module loggers MUST use the shared helper or equivalent child-logger construction. Child loggers
MUST retain request IDs, OpenTelemetry trace correlation, redaction, and bounded-cardinality
constraints. Module names and configuration keys MUST NOT contain user IDs, provider account IDs,
transaction IDs, or other runtime data.

## Rationale

The module path is the closest Node.js equivalent to a Java package/logger name: it is visible in
the code, naturally follows refactors, and does not require developers to invent a parallel label.
Using a normalized path keeps source and compiled execution consistent while allowing supporting
modules, interfaces, workers, and domain contexts to use the same convention.

## Alternatives considered

- **One global `LOG_LEVEL`:** retained as the fallback, but rejected as the only control because it
  cannot isolate noisy or failing subsystems.
- **Arbitrary component names:** rejected because names drift from the module topology and create a
  second taxonomy agents must maintain.
- **Java-style class names:** rejected as the primary identity because TypeScript behavior is often
  organized in modules and functions rather than classes.
- **Raw absolute or compiled file paths:** rejected because they leak machine/build layout and would
  differ between development and production.

## Consequences

- Log records gain a stable `module` field suitable for filtering and targeted verbosity.
- A module can be tuned without turning on verbose logs for the entire process.
- Moving a module changes its logging namespace and may require moving its environment override;
  this is intentional and reviewable.
- The helper adds a small amount of shared observability infrastructure and should remain outside
  domain behavior.
