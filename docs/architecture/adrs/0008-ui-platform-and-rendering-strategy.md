# ADR 0008: React/Vite UI Platform and PWA Rendering Strategy

- Status: Accepted
- Date: 2026-09-17
- GitHub issue: [#13](https://github.com/jho/nemeo/issues/13)
- Product decision: [#3](https://github.com/jho/nemeo/issues/3)
- Related topology decision: [ADR 0005](0005-modular-monolith-topology.md)
- Follow-up decisions: [#14](https://github.com/jho/nemeo/issues/14), [#15](https://github.com/jho/nemeo/issues/15)

## Context

Product issue #3 establishes a responsive installable Progressive Web App as the MVP client. A
separate native mobile client is not required, while the application still needs to work well on
desktop, touch devices, and the simplified family-viewer surface.

Nemeo is a small, API-driven budgeting application. Its authenticated dashboard does not need
search-engine rendering, and MVP delivery favors ordinary Node.js tooling, short vertical-slice
feedback loops, and one deployable unit. The UI must therefore fit the conventional modular
monolith in [ADR 0005](0005-modular-monolith-topology.md) without making the browser depend on
backend internals.

## Decision

Nemeo will use a React and TypeScript client built with Vite.

- The UI is a client-rendered single-page application (SPA). Server-side rendering is not an MVP
  requirement.
- Browser navigation uses normal URL routes and browser history through React Router. Routes
  represent user-facing capabilities and may be organized by vertical slice; the route layer must
  not become a second domain or API layer.
- Production builds emit static assets through the standard Vite build. Fastify serves those assets
  and the API from the same origin and the same `nemeo` image. The production container does not
  run a second frontend server or a process supervisor.
- Local development may run the conventional Vite development server with a proxy to Fastify. That
  development convenience does not change the single-image production topology.
- The frontend consumes the generated TypeSpec/OpenAPI client contract and public API
  representations only. It MUST NOT import backend modules, domain objects, repositories, or
  persistence structures.
- The responsive layout is the single MVP client surface for desktop, mobile, and family viewing.
  Touch interaction, keyboard navigation, semantic HTML, visible focus, and an accessible contrast
  baseline are implementation requirements; the component library and visual language are decided
  separately in issues #14 and #15.
- The application will include a web app manifest, platform-appropriate icons, and standalone
  display metadata so supported browsers can install it and launch it in an app-like window.
- Offline data access, offline mutation queues, background synchronization, and push notification
  delivery are explicitly out of MVP. A user may install the app, but authenticated data operations
  require a live connection. In-product pace warnings remain the MVP notification surface.
- Agent workflows use the API and curated MCP surface. MVP does not add a separate agent-specific
  UI client.
- A native wrapper such as Capacitor may be evaluated after the responsive PWA proves the product
  or native APIs/app-store distribution create a clear benefit. It is not an MVP dependency.

## Alternatives considered

### Separate native mobile client

Rejected for MVP. It duplicates the responsive client, increases release and testing work, and is
not required by the product decision. A wrapper remains a future option if native capabilities
justify it.

### Next.js or another full-stack React framework

Rejected for MVP. SSR and framework-managed server routes do not add enough value for the
authenticated API-driven application and would blur the existing Fastify boundary.

### SvelteKit or another alternative UI framework

Rejected as the default choice. It could produce a good client, but React plus Vite has the broader
conventional TypeScript component and testing ecosystem needed for a single-developer project.
This choice does not pre-approve a component library; that remains issue #14.

### Separate frontend deployment

Rejected for MVP. It adds deployment and origin complexity without improving the initial user
journey. The API contract preserves the seam needed to split the deployment later.

## Consequences

The first UI slices can ship through the same repository, API contract, image, and PR as their
backend capabilities. The browser gets an app-like install and launch experience without native
code, while desktop and touch layouts remain one surface to maintain.

The tradeoff is that MVP users need connectivity and do not receive native-only capabilities or
store distribution. SSR and an independent frontend deployment remain available later, but either
would be a deliberate architecture change rather than an accidental consequence of the initial
implementation.
