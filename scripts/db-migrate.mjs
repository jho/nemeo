import "dotenv/config";
import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import pg from "pg";

const { Pool } = pg;
const root = dirname(dirname(fileURLToPath(import.meta.url)));
const pool = new Pool({
  host: process.env.PGHOST ?? "127.0.0.1",
  port: Number(process.env.PGPORT ?? 5432),
  database: process.env.PGDATABASE ?? process.env.POSTGRES_DB,
  user: process.env.PGUSER ?? process.env.POSTGRES_USER,
  password: process.env.PGPASSWORD ?? process.env.POSTGRES_PASSWORD,
});

try {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version TEXT PRIMARY KEY,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);

  const migration = await readFile(join(root, "db/migrations/0001_bootstrap.sql"), "utf8");
  await pool.query("BEGIN");
  await pool.query(migration);
  await pool.query(
    "INSERT INTO schema_migrations (version) VALUES ($1) ON CONFLICT (version) DO NOTHING",
    ["0001_bootstrap"],
  );
  await pool.query("COMMIT");
  console.log("Database migrations are up to date.");
} catch (error) {
  await pool.query("ROLLBACK").catch(() => undefined);
  console.error(error);
  process.exitCode = 1;
} finally {
  await pool.end();
}
