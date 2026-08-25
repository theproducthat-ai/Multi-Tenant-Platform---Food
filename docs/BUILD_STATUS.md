# Build Status

Last updated: 2026-08-24, at the end of Module 0A.

Legend: **Complete** (verified working) · **In progress** · **Planned** · **Deferred**

## Module status

| Module | Status |
|---|---|
| Module 0 — Prerequisite and Environment Setup | **Complete** |
| Module 0A — Remote Supabase Development Environment | **Complete** — see validation results below |
| Module 1 — Core data model & multi-tenancy foundation | **Not started** |

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
| `packages/ui`                    | Complete — one placeholder component, no business logic |
| `packages/schemas`                | Complete — `healthCheckSchema` only |
| `packages/config`                  | Complete — env schema/loader + `getSupabaseEnv()` environment-tier guard |
| `packages/api-client`                | Complete — placeholder client factory, no endpoints |
| `packages/database-types`             | Complete — real generated types from the linked DEV/STAGING project (tableless schema; no business tables exist yet) |
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

## Documentation

All required documents exist and were updated for Module 0A: `PLATFORM_ARCHITECTURE.md`,
`DEVELOPMENT_SETUP.md`, `SECURITY_MODEL.md`, `CHANNEL_REGISTRY.md`, `CONFIGURATION_MODEL.md`,
`MODULE_MASTER.md`, `BUILD_STATUS.md` (this file), `DECISION_LOG.md`. Status: **Complete**.

## Testing foundation

| Item                          | Status   |
|--------------------------------|----------|
| Vitest configured, smoke tests passing | See validation results in final report |
| Playwright installed                    | Complete (config + one smoke spec) |
| Playwright e2e run against a live app     | Verified in Module 0 |

## Explicitly not started (out of scope for Module 0 / 0A)

Tenant management, user management, ordering, pre-order, POS workflows, SOK, KDS, payments,
wallet, NFC, entitlements, facial recognition, marketing, reporting — **Planned**, not started.
No tenants/sites/outlets/profiles/memberships/roles/personas/device/capability/configuration
tables exist. No production Supabase project exists.
