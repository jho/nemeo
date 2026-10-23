import { describe, expect, it } from "vitest";
import { buildApp } from "../../src/interfaces/http/app.js";

describe("health endpoint", () => {
  it("reports that the application is running", async () => {
    const app = buildApp();
    const response = await app.inject({ method: "GET", url: "/health" });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({ status: "ok" });

    await app.close();
  });

  it("reports not ready when no database is configured", async () => {
    const app = buildApp();
    const response = await app.inject({ method: "GET", url: "/ready" });

    expect(response.statusCode).toBe(503);
    expect(response.json()).toEqual({ status: "not_ready", reason: "database_not_configured" });

    await app.close();
  });
});
