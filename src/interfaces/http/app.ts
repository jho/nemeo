import Fastify, { type FastifyInstance } from "fastify";
import fastifyStatic from "@fastify/static";
import { existsSync } from "node:fs";
import { join } from "node:path";
import type { Pool } from "pg";

export function buildApp(database?: Pool): FastifyInstance {
  const app = Fastify({ logger: false });

  app.get("/health", async () => ({ status: "ok" }));

  app.get("/ready", async (_request, reply) => {
    if (!database) {
      return reply.code(503).send({ status: "not_ready", reason: "database_not_configured" });
    }

    try {
      await database.query("select 1");
      return { status: "ready" };
    } catch {
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
