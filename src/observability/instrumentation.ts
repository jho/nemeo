import { getNodeAutoInstrumentations } from "@opentelemetry/auto-instrumentations-node";
import { FastifyOtelInstrumentation } from "@fastify/otel";
import { NodeSDK } from "@opentelemetry/sdk-node";

const fastifyInstrumentation = new FastifyOtelInstrumentation({
  registerOnInitialization: true,
  ignorePaths: (request) => request.url === "/health" || request.url === "/ready",
  instrumentHooks: false,
});

const sdk = new NodeSDK({
  instrumentations: [
    getNodeAutoInstrumentations({
      "@opentelemetry/instrumentation-http": {
        redactedQueryParams: [
          "amount",
          "payee",
          "accountNumber",
          "accessToken",
          "refreshToken",
          "token",
        ],
        redactedQueryParamsServer: [
          "amount",
          "payee",
          "accountNumber",
          "accessToken",
          "refreshToken",
          "token",
        ],
      },
    }),
    fastifyInstrumentation,
  ],
});

// NodeSDK reads OTEL_* environment variables for exporters, sampling, resource
// identity, and instrumentation enablement. With no exporter configured, local
// and CI runs remain vendor-free while still registering the SDK and instruments.
sdk.start();

export async function shutdownTelemetry(): Promise<void> {
  await sdk.shutdown();
}
