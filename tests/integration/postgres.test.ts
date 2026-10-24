import { Pool } from "pg";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { buildApp } from "../../src/interfaces/http/app.js";

const databaseConfigured = Boolean(
  process.env.PGHOST || process.env.DATABASE_URL || process.env.RUN_INTEGRATION_TESTS,
);

describe.skipIf(!databaseConfigured)("PostgreSQL integration", () => {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    host: process.env.DATABASE_URL ? undefined : (process.env.PGHOST ?? "127.0.0.1"),
    port: process.env.DATABASE_URL ? undefined : Number(process.env.PGPORT ?? 5432),
    database: process.env.DATABASE_URL ? undefined : (process.env.PGDATABASE ?? "nemeo"),
    user: process.env.DATABASE_URL ? undefined : (process.env.PGUSER ?? "nemeo"),
    password: process.env.DATABASE_URL ? undefined : process.env.PGPASSWORD,
  });

  beforeAll(async () => {
    await pool.query("select 1");
  });

  afterAll(async () => {
    await pool.end();
  });

  it("serves readiness from a live PostgreSQL connection", async () => {
    const app = buildApp(pool);
    const response = await app.inject({ method: "GET", url: "/ready" });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({ status: "ready" });

    await app.close();
  });

  it("supports the baseline migration table", async () => {
    const result = await pool.query(
      "select to_regclass('public.app_metadata') as table_name",
    );

    expect(result.rows[0]?.table_name).toBe("app_metadata");
  });
});
