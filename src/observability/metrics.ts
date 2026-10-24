import { metrics, type Attributes } from "@opentelemetry/api";

const meter = metrics.getMeter("nemeo");

export const databaseReadinessChecks = meter.createCounter("nemeo.database.readiness.checks", {
  description: "Database readiness checks by bounded outcome.",
});

export const jobRuns = meter.createCounter("nemeo.jobs.runs", {
  description: "Application job executions by bounded outcome.",
});

export const providerSyncs = meter.createCounter("nemeo.provider.syncs", {
  description: "Provider synchronization attempts by bounded outcome.",
});

export const projectionUpdates = meter.createCounter("nemeo.projections.updates", {
  description: "Projection update attempts by bounded outcome.",
});

export const projectionLag = meter.createHistogram("nemeo.projections.lag", {
  description: "Projection lag in milliseconds.",
  unit: "ms",
});

export type OutcomeAttributes = Attributes & { outcome: "success" | "failure" | "unavailable" };
