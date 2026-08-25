# Decision Log

Records architecturally significant decisions. Newest first.

## 2026-08-25 — Module 1C: Scenario Validation & Module 1 Closure

- **Module 1 is closed as complete** (1A design → 1B implementation → 1C validation). See
  `docs/ORGANISATION_MODEL.md` for the final reference, `docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md`
  for the design record.
- **8 fictional global scenarios validated live against DEV/STAGING with zero schema changes**:
  food-service provider/client ecosystem, global enterprise (US/India/Singapore), conglomerate
  (Group→Company→Business Unit→Region→Site), multi-tenant property/realtor, mall, hospital,
  school/university, manufacturing. `scripts/verify-module-1c-scenarios.sql` — 35/35 assertions
  passing, one self-rolling-back transaction, zero residual fixture data confirmed by row-count
  check afterward. No `is_hospital`/`is_mall`/client-ID-style column was added anywhere to make
  any scenario pass — every difference is represented through the existing typed
  organisations/sites/site-areas/service-locations/relationships/assignments data, not schema.
- **No architectural gap was found.** Every scenario's structural claims (provider/client
  independence, different operators per site, ownership vs. management as independent coexisting
  facts, shared vs. private service locations distinguished by attachment point not a flag, brand
  vs. physical-store separation, clinical department vs. physical ward separation) held using only
  Module 1B's existing tables. The full deferred-capability list (users, membership, persona,
  roles, devices, configuration, policy, marketplace, delivery destinations, business calendars,
  templates, tags, NFC, facial recognition, payments, kitchen networks) was re-confirmed to have a
  clean, additive attachment point — none would require breaking or redesigning Module 1.
- **No server-side domain/query helper code was written.** `apps/api` has no domain modules and no
  auth layer yet, so building query helpers now would mean designing an abstraction with no real
  caller and no authorization context to enforce — deferred to whichever module first builds a
  consumer for them. The query *shapes* (recursive ancestor/descendant walks, per-target
  partial-index lookups) are documented in `docs/ORGANISATION_MODEL.md` instead.
- **Performance reviewed conceptually against all 8 scenarios; no missing index found**, and none
  added speculatively — the existing index set (tenant_id, parent columns, per-target partial
  indexes) covers every query shape the scenarios exercised. The one previously-identified future
  optimization (materialized path/`ltree` for very deep/wide hierarchies) remains appropriately
  deferred, with no new evidence that it's needed yet.
- **Test-script-only bugs found and fixed during 1C** (not schema bugs): a hardcoded past date in
  an effective-dating history test tripped the (correctly-working) date-range CHECK it wasn't
  meant to be testing. Fixed in the test script; no schema or migration change resulted.

## 2026-08-25 — Module 1A/1B: Global Organisation & Operating Structure

- **Architecture approved and implemented**: `docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md` (the full
  design, alternatives considered, and every resolved decision) and `docs/ORGANISATION_MODEL.md`
  (the reference for the live schema) are the durable record — this entry only calls out the
  decisions with the widest blast radius.
- **Composite foreign keys, not triggers, for cross-tenant safety.** Every parent/child
  relationship in this schema (e.g. `site_areas.site_id` → `sites`) uses a composite FK of the
  shape `FOREIGN KEY (tenant_id, x_id) REFERENCES parent (tenant_id, id)`, making a cross-tenant
  reference a constraint violation rather than an application-layer concern. The same mechanism
  extends to same-organisation (`organisation_units`) and same-site
  (`site_areas`/`service_locations`) safety by including that extra column in the key.
- **Scope Model: typed nullable columns + exactly-one-non-null CHECK** (not a central polymorphic
  registry table) is the chosen pattern for every present and future table that needs to target
  "any one of several resource types" (`portfolio_members`, `organisation_resource_assignments`,
  `external_identifiers` today). Future modules (configuration, access, branding, NFC policy,
  reporting) should repeat this pattern per table rather than sharing one generic table.
- **Hierarchy cycle prevention via dedicated `BEFORE INSERT OR UPDATE` triggers** (one per
  hierarchy — organisations, organisation units, site areas, service locations), each a plain
  recursive CTE, chosen over a generic dynamic-SQL trigger for reviewability, and over materialized
  path/`ltree`/closure tables as unjustified by any current query need.
- **No hard-delete path anywhere in this schema, with no exception** — every FK uses
  `ON DELETE RESTRICT` (the one narrow exception being `portfolio_members` cascading from its own
  `portfolio_id`). Removal is always `lifecycle_status = 'archived'`. This binds future modules
  too: no FK from a later table into this layer may use `CASCADE` to work around it.
- **RLS: enabled everywhere, zero policies for `anon`/`authenticated`** on tenant-owned tables
  (default deny — no membership model exists until Module 2); reference registries get one
  `SELECT USING (true)` policy. See `docs/SECURITY_MODEL.md`.
- **Effective-dating granularity is intentionally mixed**, governed by "does this fact have a
  single associated timezone": `organisation_relationships` uses `date` (org-to-org, no inherent
  timezone); `organisation_resource_assignments` and `portfolio_members` use `timestamptz`
  (anchored to a specific site, or an operational action where the exact moment matters).
- **Bug found and fixed during Module 1B verification**: `external_identifiers`'s originally
  proposed single wide `UNIQUE` constraint across several nullable target columns never actually
  caught duplicates — Postgres treats `NULL` as distinct from `NULL` by default, and six of the
  seven target columns are always `NULL` on any given row. Caught by
  `scripts/verify-module-1-schema.sql` and fixed in migration
  `20260825141400_fix_external_identifiers_uniqueness.sql`, switching to one partial unique index
  per target column (the pattern `portfolio_members` already used correctly). Recorded here and
  in `docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md` Section L as the one deviation from the originally
  approved design.
- **14 migrations applied to the confirmed DEV/STAGING project** (`tjquptsksqjmvztvfgfp`), plus
  one corrective migration — 15 total, covering extensions, shared trigger functions, 8 reference
  registries (seeded), and 12 structural tables. `packages/database-types` regenerated from the
  live schema. Verified via a self-rolling-back transactional test suite
  (`scripts/verify-module-1-schema.sql`, wrapped by `npm run verify:module-1`, which refuses to
  run unless `SUPABASE_ENV` is `development` or `staging`) covering relational integrity,
  cross-tenant rejection, hierarchy cycle rejection, RLS default-deny, and multi-country global
  context (India/Singapore/US) — 32/32 assertions passing, no fixture data left behind.
- **Work branched on `feature/module-1-global-org-foundation`**, off a `main` that was confirmed
  clean before branching. An unrelated, already-in-progress shadcn/ui integration (new `Button`
  component, Tailwind preset/theme, `@platform/ui` wired into all three channel apps) was found
  uncommitted on `main` at the start of this work; it was committed separately on `main` first
  (not mixed into the Module 1 branch) so Module 1's branch and validation results stay isolated
  from unrelated UI changes.

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
