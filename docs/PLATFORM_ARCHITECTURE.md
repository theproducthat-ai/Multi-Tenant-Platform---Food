# Platform Architecture

Status: **directional for everything except the data model** — describes the intended shape of
the system. As of Module 1 (1A design, 1B implementation, 1C scenario validation), the global
multi-tenancy/organisation/operating-structure schema described in `docs/ORGANISATION_MODEL.md` is
implemented, live on the DEV/STAGING Supabase project, and validated against 8 distinct global
industry scenarios (food service, global enterprise, conglomerate, property/realtor, mall,
hospital, education, manufacturing) with no schema forks or client-specific columns. The Platform
API, auth/membership, configuration engine, and every product module remain directional. See
`docs/BUILD_STATUS.md` for what actually exists today.

## High-level flow

```
Experience Channels
        ↓
Platform API
        ↓
Shared Capabilities
        ↓
Configuration + Policy
        ↓
Remote Supabase DEV/STAGING — PostgreSQL / Auth / Realtime / Storage
```

There is no local/Docker Supabase in this repo's workflow (Docker is not permitted in this
development environment). Local applications talk to the Platform API, which is the only thing
that talks to a **remote** Supabase project directly — currently a dedicated DEV/STAGING
project, kept fully separate from the production project that will exist later. See
`docs/SECURITY_MODEL.md` for environment isolation rules and `docs/DEVELOPMENT_SETUP.md` for
the remote workflow.

- **Experience Channels** — Consumer app/PWA, Admin Portal, POS, SOK, KDS, Handheld POS,
  Native Mobile, External APIs, and future device-based interfaces. These are presentation
  layers only: they render UI for a persona/device and call the Platform API. They must not
  contain business rules.
- **Platform API** — a single NestJS (Fastify) service that all channels call. It is the only
  thing that talks to Supabase directly on the server side.
- **Shared Capabilities** — business domain logic (future: tenants, sites/outlets, ordering,
  entitlements, etc.), organized as modules inside the Platform API rather than as separate
  services. This is where cross-channel rules live.
- **Configuration + Policy** — the layer that lets one codebase behave differently per tenant,
  site, outlet, channel, persona, and device without branching application code. See
  `docs/CONFIGURATION_MODEL.md` for the inheritance model (not yet implemented).
- **Supabase** — PostgreSQL, Auth, Row Level Security, Realtime, and Storage. Schema is
  migration-based (`supabase/migrations/`).

## Modular monolith decision

The backend is built as a **modular monolith**: one deployable NestJS application containing
well-separated domain modules, not a set of microservices. Rationale:

- The platform is pre-product-market-fit for most of its future channels; splitting into
  services now would add operational overhead (deployment, networking, observability) before
  there's a scaling or team-boundary reason to pay for it.
- A modular monolith still gives clean module boundaries in code (via NestJS modules), which is
  the part that actually prevents duplicated business logic between channels.
- Splitting into microservices later remains possible if a specific module needs independent
  scaling or an independent team — but that requires an explicit architecture decision recorded
  in `docs/DECISION_LOG.md`, not an ad-hoc split.

## Repository shape

```
platform/
├── apps/
│   ├── consumer/   Next.js — consumer channel
│   ├── admin/      Next.js — admin channel
│   ├── pos/        Next.js — POS channel
│   └── api/        NestJS + Fastify — the Platform API
├── packages/
│   ├── ui/                 shared, presentation-only React components
│   ├── schemas/             shared Zod schemas (API contracts, config shapes)
│   ├── config/              shared env/config loading
│   ├── api-client/          typed client for calling the Platform API
│   ├── database-types/      generated Supabase types (real schema as of Module 1B — tenants,
│   │                        organisations, sites, and the rest of the organisation model)
│   ├── supabase-client/      browser/server Supabase client factories (infra only)
│   ├── eslint-config/        shared ESLint flat config
│   └── typescript-config/    shared strict tsconfig bases
├── supabase/                migrations, config, seed
├── scripts/                  dev-only utility scripts (e.g. Supabase connectivity check)
└── docs/                     this documentation set
```

## Why these channels are separate apps but one API

Each channel has a genuinely different UI/UX and device context (a POS terminal is not a
consumer's phone), which justifies separate Next.js apps. But the business logic behind
"what can this user do, what does this order cost, what's in stock" must be identical no
matter which channel asks — hence a single Platform API and shared capability layer.
