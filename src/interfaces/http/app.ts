import Fastify, { type FastifyInstance } from "fastify";
import fastifyStatic from "@fastify/static";
import { existsSync } from "node:fs";
import { join } from "node:path";
import type { Pool } from "pg";
import { databaseReadinessChecks } from "../../observability/metrics.js";

const REDACTED = "[REDACTED]";

const logger = {
  level: process.env.LOG_LEVEL ?? "info",
  redact: {
    paths: [
      "req.headers.authorization",
      "req.headers.cookie",
      "req.headers.set-cookie",
      "req.body",
      "req.query",
      "password",
      "token",
      "accessToken",
      "refreshToken",
      "clientSecret",
      "providerPayload",
      "amount",
      "payee",
      "accountNumber",
    ],
    censor: REDACTED,
  },
};

export function buildApp(database?: Pool): FastifyInstance {
  const app = Fastify({ logger });

  app.get("/health", { config: { otel: false } }, async () => ({ status: "ok" }));

  app.get("/ready", { config: { otel: false } }, async (_request, reply) => {
    if (!database) {
      databaseReadinessChecks.add(1, { outcome: "unavailable" });
      return reply.code(503).send({ status: "not_ready", reason: "database_not_configured" });
    }

    try {
      await database.query("select 1");
      databaseReadinessChecks.add(1, { outcome: "success" });
      return { status: "ready" };
    } catch {
      databaseReadinessChecks.add(1, { outcome: "failure" });
      return reply.code(503).send({ status: "not_ready", reason: "database_unavailable" });
    }
  });

  const webRoot = join(process.cwd(), "dist", "web");
  if (existsSync(webRoot)) {
    app.register(fastifyStatic, {
      root: webRoot,
      prefix: "/",
    });
  }

  return app;
}
