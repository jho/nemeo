import "dotenv/config";
import pg from "pg";

if (process.env.NODE_ENV === "production" || process.env.DB_RESET_CONFIRM !== "local") {
  throw new Error("Refusing database reset. Set NODE_ENV=development and DB_RESET_CONFIRM=local.");
}

const { Pool } = pg;
const pool = new Pool({
  host: process.env.PGHOST ?? "127.0.0.1",
  port: Number(process.env.PGPORT ?? 5432),
  database: process.env.PGDATABASE ?? process.env.POSTGRES_DB,
  user: process.env.PGUSER ?? process.env.POSTGRES_USER,
  password: process.env.PGPASSWORD ?? process.env.POSTGRES_PASSWORD,
});

try {
  await pool.query("DROP SCHEMA public CASCADE");
  await pool.query("CREATE SCHEMA public");
  console.log("Local database reset.");
} finally {
  await pool.end();
}
