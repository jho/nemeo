# ADR 0021: MVP Observability and Incident Response Baseline

- Status: Accepted
- Date: 2026-10-08
- GitHub issue: [#32](https://github.com/jho/nemeo/issues/32)
- Related automation: [ADR 0015](0015-postgres-automation-jobs-and-scheduling.md)
- Related testing: [ADR 0019](0019-ci-quality-gates-and-execution-tiers.md)
- Related environment topology: [ADR 0020](0020-mvp-environment-topology-and-promotion.md)

## Context

Nemeo needs enough operational visibility to detect failed provider synchronization, stuck
automations, unavailable services, and application regressions. It is a Compose-first product with a
single application process and a solo maintainer, so MVP observability must be broadly instrumented
without requiring a hosted observability platform or a complex operations team.

## Decision

Nemeo will use OpenTelemetry auto-instrumentation as the default Node.js observability foundation,
with provider-neutral export configuration.

### Instrumentation foundation

The application will initialize observability before loading Fastify, PostgreSQL, or other
instrumented modules using:

- `@opentelemetry/sdk-node` for SDK lifecycle and runtime configuration;
- `@opentelemetry/auto-instrumentations-node` for supported Node.js, HTTP, PostgreSQL, Undici,
  Pino, and runtime instrumentation; and
- `@fastify/otel` for Fastify request and lifecycle instrumentation.

Instrumentation configuration MUST be centralized and tunable through runtime configuration. It
MUST support enabling/disabling exporters and individual instrumentations, setting the service name
and environment, selecting sampling, and configuring an OTLP endpoint without application code
changes. Local development MAY use console output. MVP MUST NOT require a telemetry vendor or an
external collector to run.

Application code MAY add manual spans and metrics around provider syncs, automation runs,
projection rebuilds, event replay, categorization, and pace evaluation when automatic
instrumentation cannot express the business operation. Domain events and operational telemetry are
separate: a pace warning remains a financial/product event, not an infrastructure alert.

### Logs and sensitive-data handling

Application and worker logs MUST be structured and include enough correlation metadata to connect an
HTTP request, MCP call, job, automation, provider operation, and resulting error. Logs SHOULD include
opaque request, trace, span, job, connection, and household identifiers where relevant.

Logs, spans, and metric attributes MUST NOT contain credentials, tokens, raw provider payloads,
request/response bodies, payee or merchant text, transaction amounts, account numbers, or other
avoidable financial or personal data. Header and query capture uses an explicit allowlist. Redaction
is applied at the instrumentation boundary and remains effective regardless of exporter choice.

### Health and readiness

The application MUST expose separate liveness and readiness signals:

- liveness answers whether the process is running and able to serve a health request;
- readiness verifies that the application is initialized and required PostgreSQL connectivity and
  migration state are usable; and
- worker readiness reports whether the scheduler/worker loop is initialized and able to claim work.

Health endpoints MUST be cheap, unauthenticated where required by the host, and excluded from noisy
request tracing. A failed readiness signal MUST prevent or remove traffic/work assignment without
being treated as a domain failure.

### Minimum operational signals

MVP dashboards or equivalent host views SHOULD expose:

- request rate, error rate, and latency by interface/route class;
- process health, runtime resource pressure, and PostgreSQL connectivity/pool errors;
- automation and job run counts, duration, queue depth, lease expiry, and terminal failures;
- provider sync success/failure, duration, rate-limit/authentication failures, and last-success age;
- projection progress or lag where asynchronous processing is used; and
- application startup, shutdown, and readiness transitions.

Metric names and attributes MUST remain provider-neutral. Cardinality MUST be bounded; household,
transaction, payee, provider payload, and other unbounded user data MUST NOT become metric labels.

### Alerts and incident response

MVP alerts are limited to actionable operational conditions:

- application or PostgreSQL readiness failure;
- sustained elevated API/worker error rate;
- provider sync failures or stale last-success time beyond the configured threshold;
- growing job backlog, repeated lease expiry, or terminal automation failures; and
- projection lag that violates the affected slice's consistency expectation.

User-facing pace warnings are not operational alerts. Alert routing is configuration-driven and
owned by the maintainer until a production hosting/observability provider is selected.

The MVP incident loop is: acknowledge, assess scope, contain or disable the failing automation,
restore service, verify data and projection health, and record a short incident note with follow-up
actions. A post-incident review is required for data integrity incidents, repeated provider or job
failures, and incidents that expose sensitive data; routine transient failures only require the
operational record needed for follow-up.

## Consequences

Nemeo gets broad request, database, runtime, Fastify, and worker visibility with a small amount of
application-specific instrumentation. OTLP and environment-driven configuration preserve the option
to adopt a hosted provider or collector later without changing domain or slice code.

The tradeoff is another startup dependency and a need to maintain redaction and sampling defaults.
Automatic instrumentation also cannot understand every business operation, so important domain and
automation boundaries still require deliberate manual spans and metrics.

## Alternatives considered

- **Provider-specific SDK first:** rejected because it couples application instrumentation to a
  vendor before production hosting and observability needs are known.
- **Manual metrics and logs only:** rejected because it gives up broad HTTP, PostgreSQL, runtime, and
  dependency visibility that auto-instrumentation provides cheaply.
- **Full observability platform and collector for MVP:** deferred because it adds cost and
  operational work before there is a production signal volume to justify it.
- **Instrument every lifecycle hook and business field:** rejected because it creates noise,
  cardinality, performance cost, and sensitive-data exposure.
