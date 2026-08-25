# Decision Log

Records architecturally significant decisions. Newest first.

## 2026-08-24 — Module 0A: Remote Supabase Development Environment

- **Remote Supabase Development/Staging project selected as the supported workflow, because
  Docker/local Supabase is not permitted in the current corporate development environment.**
  This does not change the intended production architecture — production will still be
  Supabase (PostgreSQL/Auth/RLS/Realtime/Storage), migrations-first, RLS-protected. Only the
  *local developer's* path to a Postgres instance changes: instead of `supabase start`
  spinning up local Docker containers, developers point at a dedicated remote DEV/STAGING
  project. Docker documentation isn't deleted, just no longer a project prerequisite.
- **`tjquptsksqjmvztvfgfp` ("Multi Tenant Platform -Food", region `ap-southeast-2`) confirmed
  by the project owner as the dedicated DEV/STAGING project** for this repository (2026-08-24).
  This was an explicit confirmation, not an assumption — the project's name alone didn't
  indicate its tier, so this was asked rather than inferred, per the module's safety rule that
  a linked project is never assumed safe just because it's linked.
- **Removed `supabase:start` / `supabase:stop` / `supabase:reset` root scripts.** They were
  Docker-only (start/stop) or genuinely destructive against whatever's linked (reset). Replaced
  with `supabase:login`, `supabase:link`, `supabase:migrations` (read-only), `supabase:push`
  (schema-changing, explicitly labeled), `supabase:types`, and `supabase:verify`
  (non-destructive connectivity check). No script hardcodes a project ref or a destructive
  remote reset.
- **New key naming: `sb_publishable_...` / `sb_secret_...`**, Supabase's current key format,
  used in `.env.example` and docs going forward, with the legacy `anon`/`service_role` JWT
  names documented as a fallback mapping (this project happens to have both formats issued).
- **New package `packages/supabase-client`** (`createBrowserSupabaseClient`,
  `createServerSupabaseClient`) — pure infrastructure, no business logic, added because the
  browser-vs-server Supabase client split needed one canonical place to live rather than being
  reinvented per app. Depends on `@supabase/supabase-js` (justification: it's the official
  Supabase client SDK — no alternative under consideration) and `@platform/database-types`
  (for a typed client). The browser factory rejects a key that looks like a secret key; the
  server factory refuses to run in a `window` context — both are cheap defensive checks against
  the exact mistake the security model warns about (service key reaching a browser bundle).
- **`packages/database-types` now holds a real (generated, tableless) schema** instead of a
  hand-written placeholder, produced via `supabase gen types typescript --linked`. It gained a
  proper CJS build step (`packages/typescript-config/library.json`, same pattern as
  `schemas`/`config`) because the generated file exports a real runtime value (`Constants`), not
  only types — the placeholder file didn't need this, but real generated output does.
- **`scripts/verify-supabase-connection.mjs`** added as the non-destructive connectivity check:
  one read-only request to the linked project's Supabase Auth (GoTrue) health endpoint.
  Originally targeted PostgREST's root endpoint (`/rest/v1/`), but that now returns
  `401 Secret API key required` on this project — schema introspection is gated behind the
  secret key, so it isn't reachable with the browser-safe publishable/anon key this script is
  meant to run with. The Auth health endpoint is public-by-design and proves reachability
  without needing a privileged key. Verified working end-to-end against the live project.
  Deliberately does not use `@supabase/supabase-js` (avoids pulling that dependency into a
  one-off root script) and never logs the key it used, only its type.
- **Security note:** running `npx supabase projects api-keys` without `--reveal` printed the
  full legacy `anon` and `service_role` JWTs in this session's tool output (only the new
  `sb_secret_...`-format key was masked). No key was written to any file. Recorded here so a
  future reader understands why the docs warn about this command specifically.

## 2026-08-24 — Git remote and Supabase project linked (user-provided)

- **Git remote `origin`** added, pointing at
  `https://github.com/theproducthat-ai/Multi-Tenant-Platform---Food.git`. Nothing has been
  pushed — the user asked for the remote to be added only, for review before any push.
- **Supabase CLI linked** to the user's pre-provisioned cloud project (`tjquptsksqjmvztvfgfp`,
  "Multi Tenant Platform -Food", region `ap-southeast-2`) via `supabase link --project-ref`, at
  the user's explicit request. This only points the local CLI at that project for future
  `db push` / `gen types` — it does not push schema, does not touch env files, and no keys were
  written to any tracked file (the link reference is in the gitignored `supabase/.temp/`). No
  schema exists yet to push. Local `supabase start` (Docker-based) remains separate and still
  blocked on Docker Desktop's engine not running.

## 2026-08-24 — Module 0 tooling and structure decisions

- **Package manager: npm (workspaces), not pnpm/yarn/bun.** Reduces tooling surface area and
  matches the stack requirement; npm workspaces are sufficient for this repo's size.
- **Turborepo for task orchestration/caching** across `apps/*` and `packages/*`, rather than
  hand-rolled scripts, so `build`/`lint`/`typecheck`/`test` scale with more apps/packages
  without a root script rewrite each time.
- **TypeScript, strict mode, shared base config** (`packages/typescript-config`) extended by
  every app/package, so type-safety rules are consistent and defined once.
- **Next.js (App Router) + React + Tailwind CSS** for all three initial frontend channels
  (consumer, admin, POS) — consistent frontend stack across channels, per the architecture's
  "shared frontend technology, channel-specific apps" approach. Tailwind v3 (stable,
  config-file based) chosen over v4 for predictability during initial setup.
- **NestJS on the Fastify adapter** (not Express) for the Platform API — Fastify has lower
  overhead than Express and NestJS's Fastify adapter is first-class supported; matches the
  explicit stack requirement.
- **Modular monolith, not microservices**, for the backend. See
  `docs/PLATFORM_ARCHITECTURE.md` for rationale. Any future split requires a new entry here.
- **Separate channel apps (`apps/consumer`, `apps/admin`, `apps/pos`), one shared backend
  (`apps/api`)** — channels differ in UI/UX and device context; business logic must not be
  duplicated per channel, so it lives once in the API.
- **Supabase for Postgres/Auth/RLS/Realtime/Storage**, CLI installed as a local devDependency
  (`npm install --save-dev supabase`) rather than a global install, so the CLI version is
  pinned per-repo and reproducible via `package-lock.json`.
- **Migrations-first database development.** All schema changes go through
  `supabase/migrations/`; dashboard-only changes are disallowed. See
  `docs/SECURITY_MODEL.md` and Architecture Rule 11 in `CLAUDE.md`.
- **Zod for schema validation**, used for the one setup-verification schema
  (`healthCheckSchema`) and the env loader in `packages/config`. Chosen because it's
  TypeScript-first and needed for both API contracts and config validation later — avoids
  pulling in a second, overlapping validation library.
- **Vitest for unit/smoke tests, Playwright for e2e smoke tests.** Vitest has near-zero config
  for TS/ESM and is fast; Playwright is the explicit e2e requirement in the stack. No Jest, to
  avoid two overlapping test runners.
- **Excluded for this setup, per explicit instruction:** Prisma, GraphQL, Kafka, Redis,
  Kubernetes, RabbitMQ, Elasticsearch, Temporal, microservices. Re-evaluate only if a future
  module's requirements justify one of these — record that justification here if so.
