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
npm run test:integration # PostgreSQL-backed test tier placeholder until Compose lands
npm run test:e2e         # Playwright critical-path tier placeholder
npm start                # Run the compiled application
```

TypeSpec is the API source of truth. The generated OpenAPI contract is written to
`contracts/generated/openapi.yaml`; do not hand-edit it. `npm run contracts:check` regenerates the
contract and fails when the checked-in artifact drifts from the TypeSpec source.

The web app is built from `web/index.html` and `src/interfaces/web/`. Vite proxies `/api` to the
Fastify development server. The production build is served by Fastify from the same application
image.

Business behavior does not belong in this bootstrap change. Implement domain behavior inside
Event Model-aligned vertical slices after the workspace foundation is complete.
