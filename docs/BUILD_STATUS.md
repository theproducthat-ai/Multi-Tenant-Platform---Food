# Build Status

Last updated: 2026-08-25, at the end of Module 1C.

Legend: **Complete** (verified working) · **In progress** · **Planned** · **Deferred**

## Module status

| Module | Status |
|---|---|
| Module 0 — Prerequisite and Environment Setup | **Complete** |
| Module 0A — Remote Supabase Development Environment | **Complete** — see validation results below |
| Module 1A — Global Organisation & Operating Structure (architecture design) | **Complete** — see `docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md` |
| Module 1B — Global Organisation & Operating Structure (database implementation) | **Complete** — see below and `docs/ORGANISATION_MODEL.md` |
| Module 1C — Scenario Validation & Closure | **Complete** — 8 global scenarios validated live, zero schema changes, see below |

## Repository & tooling

| Item                                  | Status    |
|-----------------------------------------|-----------|
| npm workspaces configured                | Complete |
| Turborepo configured                     | Complete |
| Strict TypeScript config (shared base)   | Complete |
| ESLint (flat config, shared)             | Complete |
| Prettier                                    | Complete |
| EditorConfig                                 | Complete |
| package-lock.json committed                    | Complete |

## Applications (scaffolds only — no product functionality)

| App      | Scaffolded | Builds | Serves placeholder page |
|----------|------------|--------|---------------------------|
| Consumer (3000) | Complete | See validation results in final report | Yes |
| Admin (3001)    | Complete | See validation results in final report | Yes |
| POS (3002)      | Complete | See validation results in final report | Yes |
| API (4000)      | Complete | See validation results in final report | `GET /health` only |

## Shared packages

| Package                        | Status   |
|---------------------------------|----------|
| `packages/ui`                    | Complete — shadcn/ui `Button`, shared Tailwind preset/theme, wired into all three channel apps (Module 1B, unrelated to the data model work) |
| `packages/schemas`                | Complete — `healthCheckSchema`, plus (Module 1B) `lifecycleStatusSchema`, `siteModeSchema`, `structuralCodeSchema`, `countryCodeSchema`, `currencyCodeSchema`, `timezoneSchema`, `localeSchema` |
| `packages/config`                  | Complete — env schema/loader + `getSupabaseEnv()` environment-tier guard |
| `packages/api-client`                | Complete — placeholder client factory, no endpoints |
| `packages/database-types`             | Complete — real generated types from the linked DEV/STAGING project, now including the full Module 1 organisation-model schema |
| `packages/supabase-client`             | Complete (Module 0A) — `createBrowserSupabaseClient` / `createServerSupabaseClient`, infra only |
| `packages/eslint-config`                | Complete |
| `packages/typescript-config`             | Complete — added `library.json` variant for CJS-built packages |

## Supabase (Module 0A — remote DEV/STAGING workflow)

Docker is not permitted in this development environment. Local/Docker Supabase is **not** part
of the supported workflow — see `docs/DEVELOPMENT_SETUP.md` and `docs/SECURITY_MODEL.md`.

| Item                                       | Status                                    |
|----------------------------------------------|--------------------------------------------|
| Supabase CLI installed as devDependency        | Complete |
| `supabase/` initialized (`config.toml`)          | Complete |
| `supabase/migrations/` ready (empty, no business migrations) | Complete |
| CLI authenticated                                  | Complete — confirmed via `supabase projects list` |
| CLI linked to confirmed DEV/STAGING project (`supabase link`) | Complete |
| Remote connectivity verified (non-destructively)     | Complete — via `supabase migration list --linked` (real read-only query) and `npm run supabase:verify` (HTTP request to the Auth health endpoint), both run successfully against the live project |
| Database type generation from remote schema            | Complete — `packages/database-types/src/database.ts` |
| Docker-based local Supabase (`start`/`stop`/`reset`)      | **Removed** — not part of this repo's workflow, not a blocker |
| Schema pushed to DEV/STAGING                                | Not done — no migrations exist yet (expected; Module 1 will add the first ones) |
| Production Supabase project                                    | Does not exist yet (intentionally — out of scope) |

**Linked project:** `tjquptsksqjmvztvfgfp` ("Multi Tenant Platform -Food", region
`ap-southeast-2`), confirmed by the project owner as the dedicated DEV/STAGING project. See
`docs/DECISION_LOG.md` for the confirmation record.

## Module 1B — Global Organisation & Operating Structure (database)

| Item | Status |
|---|---|
| Migrations (`supabase/migrations/`) | Complete — 15 files applied to DEV/STAGING (14 initial + 1 corrective, see Decision Log) |
| Tables | Complete — `tenants`, `organisations`, `organisation_units`, `organisation_relationships`, `portfolios`, `portfolio_members`, `properties`, `sites`, `site_areas`, `service_locations`, `organisation_resource_assignments`, `external_identifiers` (12 structural tables) |
| Reference registries | Complete — 8 tables, seeded (`organisation_types`, `organisation_unit_types`, `organisation_relationship_types`, `organisation_resource_role_types`, `property_types`, `site_types`, `site_area_types`, `service_location_types`) |
| Composite FKs / cross-tenant integrity | Complete — verified via `npm run verify:module-1` |
| Hierarchy cycle prevention (4 recursive hierarchies) | Complete — dedicated triggers, verified |
| RLS | Complete for Module 1's posture (enabled, default deny, registries readable) — see `docs/SECURITY_MODEL.md`. Membership-based policies are Module 2. |
| `packages/database-types` regenerated | Complete |
| Remote verification suite (`scripts/verify-module-1-schema.sql` + guarded `.mjs` wrapper) | Complete — 32/32 assertions passing against DEV/STAGING, self-rolling-back (no residual fixture data) |
| `docs/ORGANISATION_MODEL.md` | Complete |

## Module 1C — Scenario Validation & Closure

| Item | Status |
|---|---|
| 8 scenario fixtures (food service, global enterprise, conglomerate, property/realtor, mall, hospital, education, manufacturing) | Complete — `scripts/verify-module-1c-scenarios.sql`, 35/35 assertions passing, self-rolling-back (zero residual rows confirmed) |
| Global behaviour tests (hierarchy depth/cycles, tenant isolation, codes, lifecycle, effective dating) | Complete |
| RLS re-verification against 1C fixtures | Complete — same default-deny result |
| Performance/index review | Complete — no missing index found, none added speculatively |
| Deferred-capability attachment-point audit (users, membership, config, policy, marketplace, NFC, payments, etc.) | Complete — no architectural gap found |
| `docs/ORGANISATION_MODEL.md` scenario coverage + query patterns | Complete |
| Server-side query helpers | **Deliberately not built** — no domain/auth layer exists yet to own them |

## Documentation

All required documents exist and were updated for Module 0A: `PLATFORM_ARCHITECTURE.md`,
`DEVELOPMENT_SETUP.md`, `SECURITY_MODEL.md`, `CHANNEL_REGISTRY.md`, `CONFIGURATION_MODEL.md`,
`MODULE_MASTER.md`, `BUILD_STATUS.md` (this file), `DECISION_LOG.md`. Status: **Complete**.

Updated again for Module 1B: `PLATFORM_ARCHITECTURE.md`, `SECURITY_MODEL.md`, `MODULE_MASTER.md`,
`BUILD_STATUS.md` (this file), `DECISION_LOG.md`; new `MODULE_1A_ARCHITECTURE_PROPOSAL.md` and
`ORGANISATION_MODEL.md`. Updated again for Module 1C closure: the same six files, plus
`ORGANISATION_MODEL.md` extended with all 8 scenario examples, query patterns, the full deferred-
capability attachment-point table, and performance observations. Status: **Complete**.

## Testing foundation

| Item                          | Status   |
|--------------------------------|----------|
| Vitest configured, smoke tests passing | See validation results in final report |
| Playwright installed                    | Complete (config + one smoke spec) |
| Playwright e2e run against a live app     | Verified in Module 0 |

## Explicitly not started (out of scope for Module 1)

User management, ordering, pre-order, POS workflows, SOK, KDS, payments, wallet, NFC,
entitlements, facial recognition, marketing, reporting — **Planned**, not started. No
profiles/memberships/roles/personas/device/capability/configuration tables exist — tenant,
organisation, and site-structure tables now exist as of Module 1B (see above), but nothing that
grants access to them does. No production Supabase project exists.
