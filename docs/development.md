# Development

Nemeo uses one Node.js 24 application package with strict ESM TypeScript. The application keeps
HTTP, web, MCP, worker, scheduler, and projection entry points separate while composing them in one
MVP process.

## Prerequisites

- Node.js 24
- npm 11 or newer

Install dependencies with:

```bash
npm install
```

## Common commands

```bash
npm run dev              # Fastify development server
npm run dev:web          # Vite development server
npm run validate         # Typecheck, contracts, lint, formatting, and unit tests
npm run build            # API, web, and TypeSpec/OpenAPI builds
npm run test:integration # PostgreSQL-backed test tier
npm run test:e2e         # Playwright critical-path tier placeholder
npm run db:migrate        # Apply pending migrations
npm run db:migrate:dry-run # Preview pending migration SQL
npm run db:migrate:down   # Roll back the latest migration locally
npm run db:reset          # Reset local database only with explicit confirmation
npm start                # Run the compiled application
```

## Compose

Compose is the local application-plus-PostgreSQL contract:

```bash
cp .env.example .env       # edit with local-only values; never commit .env
docker compose up --build
docker compose exec app npm run db:migrate
```

The application is available at `http://localhost:3000`. `/health` is the liveness endpoint and
`/ready` verifies the PostgreSQL connection. To run the disposable CI-shaped environment:

```bash
docker compose -f compose.yaml -f compose.ci.yaml up --build --abort-on-container-exit
```

Local database reset is deliberately guarded:

```bash
DB_RESET_CONFIRM=local npm run db:reset
```

PostgreSQL credentials are supplied through the untracked `.env` file, the CI environment, or the
deployment environment. They are never stored in `compose.yaml`, the Docker image, or committed
source files.

TypeSpec is the API source of truth. The generated OpenAPI contract is written to
`contracts/generated/openapi.yaml`; do not hand-edit it. `npm run contracts:check` regenerates the
contract and fails when the checked-in artifact drifts from the TypeSpec source.

PostgreSQL migrations use `node-pg-migrate`. Add immutable, ordered migration files under
`db/migrations/`. Use the migration helpers for ordinary schema changes and raw SQL or async
migrations for data backfills. Prefer expand/contract changes: add compatible schema first, deploy
the application transition, backfill data, and remove obsolete structures only in a later migration.
Migrations run in transactions by default; opt out only for PostgreSQL operations that require it.

The web app is built from `web/index.html` and `src/interfaces/web/`. Vite proxies `/api` to the
Fastify development server. The production build is served by Fastify from the same application
image.

Business behavior does not belong in this bootstrap change. Implement domain behavior inside
Event Model-aligned vertical slices after the workspace foundation is complete.
