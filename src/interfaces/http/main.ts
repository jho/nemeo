import { shutdownTelemetry } from "../../observability/instrumentation.js";
import { buildApp } from "./app.js";
import { Pool } from "pg";

const port = Number(process.env.PORT ?? 3000);
const host = process.env.HOST ?? "0.0.0.0";
const database = new Pool({
  host: process.env.PGHOST,
  port: Number(process.env.PGPORT ?? 5432),
  database: process.env.PGDATABASE,
  user: process.env.PGUSER,
  password: process.env.PGPASSWORD,
  connectionTimeoutMillis: 2_000,
});
const app = buildApp(database);

try {
  await app.listen({ host, port });
} catch (error) {
  app.log.error(error);
  process.exitCode = 1;
}

const shutdown = async () => {
  await app.close();
  await database.end();
  await shutdownTelemetry();
};

process.once("SIGINT", shutdown);
process.once("SIGTERM", shutdown);
