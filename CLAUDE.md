# Platform — Claude Code Governance

This file establishes permanent rules for any Claude Code session working in this repository.
It applies to every module, not just Module 0.

## What this repository is

A long-term, multi-tenant, multi-channel SaaS platform (consumer app, admin portal, POS, and
future SOK/KDS/handheld/native/API channels), backed by Supabase (PostgreSQL, Auth, RLS,
Realtime, Storage). Built as an npm-workspaces + Turborepo monorepo, modular monolith on the
backend. See `docs/PLATFORM_ARCHITECTURE.md` for the full architecture.

## Architecture Rules

1. Read architecture documentation (`docs/`) before implementing a feature.
2. Do not duplicate business logic between channels.
3. Consumer, Admin, POS, SOK and KDS are experience layers — they render and collect input,
   they do not own business rules.
4. Shared business rules belong in the platform/domain layer (the API's shared capabilities),
   not in a channel app.
5. Never hardcode client-specific behavior.
6. Differences by tenant, site, outlet, persona, channel and device must ultimately be
   configuration or policy driven, not `if (tenant === 'x')` branches in application code.
7. Before adding a feature, classify it as one of:
   - configuration
   - policy
   - capability extension
   - new capability
   - presentation-only channel change
   State the classification when proposing the change.
8. Do not create microservices without an explicit architecture decision recorded in
   `docs/DECISION_LOG.md`.
9. Do not add dependencies without justification — explain the requirement and why the chosen
   package is the right fit; avoid overlapping libraries that do the same job.
10. Do not commit secrets. Real credentials never go in tracked files.
11. Database changes must use migrations (`supabase/migrations/`). Never rely on dashboard-only
    schema changes.
12. Tenant data must eventually be protected through Row Level Security (RLS).
13. Shared contract changes (API responses, schemas, types) must consider all channels that
    consume them.
14. Update architecture documentation when architectural behavior changes.
15. Do not claim tests passed unless they actually ran successfully — show the command and
    result, don't assert success from reading the code.

## Explicitly out of scope until instructed

Do not build tenant management, user management, ordering, pre-order, POS workflows, SOK, KDS,
payments, wallet, NFC, entitlements, facial recognition, marketing, or reporting unless a task
explicitly asks for that module. This repository is currently at **Module 0 — Prerequisite and
Environment Setup** (see `docs/MODULE_MASTER.md`).

## Practical repo conventions

- Package manager: npm only (workspaces). Do not introduce pnpm, yarn, or bun.
- Node 24 LTS. Keep `engines` in root `package.json` accurate.
- Run tasks through Turborepo (`npm run dev|build|lint|typecheck|test|test:e2e`) rather than
  invoking per-app tooling directly, so caching and dependency ordering stay correct.
- Supabase CLI is a local devDependency (`npx supabase ...`), not a global install.
- Docker is not permitted in this development environment. There is no local/Docker Supabase
  workflow — development happens against a remote DEV/STAGING Supabase project (see
  `docs/DEVELOPMENT_SETUP.md`, `docs/SECURITY_MODEL.md`). Never assume the currently-linked
  project is safe for a given operation just because it's linked — check `SUPABASE_ENV` (via
  `@platform/config`'s `getSupabaseEnv()`) before anything privileged or schema-changing.
- Do not create a cloud Supabase project or link/connect to production from this repo without
  explicit instruction. Do not add a script that could reset or destructively modify whatever
  Supabase project happens to be linked.
