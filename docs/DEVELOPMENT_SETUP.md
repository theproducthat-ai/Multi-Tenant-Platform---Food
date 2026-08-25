# Development Setup

## Required software

| Tool         | Version         | Notes                                             |
|--------------|-----------------|----------------------------------------------------|
| Node.js      | 24 LTS          | Verify with `node --version`                       |
| npm          | 11.x+           | Ships with Node 24. Verify with `npm --version`     |
| Git          | any recent      | Verify with `git --version`                         |
| VS Code      | recommended     | Workspace settings live in `.vscode/`               |

This repo uses **npm workspaces only** — do not use pnpm, yarn, or bun.

> **Docker/local Supabase is not part of the supported development workflow for this
> repository.** Docker is not permitted in this development environment. All Supabase
> development happens against a **remote DEV/STAGING project** — see "Remote Supabase
> workflow" below. Docker documentation exists elsewhere (Supabase's own docs) if you're
> working in an environment where local Supabase is viable, but it is not a project
> prerequisite here.

## Clone and install

```bash
git clone <repo-url>
cd platform
npm install
```

## Environment variables

```bash
cp .env.example .env.local   # for frontend apps (Next.js reads .env.local)
cp .env.example .env         # for apps/api, scripts/, and the Supabase CLI
```

Fill in real values locally, sourced from the remote DEV/STAGING Supabase project (Project
Settings → API in the Supabase dashboard, or `npx supabase projects api-keys` — see security
note below). Never commit `.env`, `.env.local`, or any file with real secrets — `.gitignore`
already excludes them.

Supabase now issues two key formats; use the current one where possible:

| Purpose | Current key | Legacy key (still works) |
|---|---|---|
| Browser-safe, RLS-respecting | `sb_publishable_...` | `anon` (JWT) |
| Server-only, bypasses RLS | `sb_secret_...` | `service_role` (JWT) |

`NEXT_PUBLIC_*`-prefixed variables get bundled into client-side JavaScript by Next.js — only
ever put the URL and the **publishable** key there. `SUPABASE_SECRET_KEY` (or the legacy
`SUPABASE_SERVICE_ROLE_KEY`) must only exist in server-side env files, never `NEXT_PUBLIC_*`.

`APP_ENV` / `SUPABASE_ENV` are explicit environment markers (`development` | `staging` |
`production`), independent of `NODE_ENV`. Any script capable of destructive or privileged
database activity should check `SUPABASE_ENV` (see `@platform/config`'s `getSupabaseEnv()`)
before running, rather than assuming a linked project is safe just because it's linked.

**Security note:** running `supabase projects api-keys` without `--reveal` still prints legacy
`anon`/`service_role` JWTs in full (only the new `sb_secret_...`-style key is masked by
default). Prefer reading keys from the Supabase dashboard when possible, and treat any
terminal/log output containing them as sensitive.

## Local startup

Start every app (via Turborepo, in parallel):

```bash
npm run dev
```

Or start a single app from its own workspace:

```bash
npm run dev --workspace=@platform/consumer
```

### Ports

| App      | URL                       |
|----------|---------------------------|
| Consumer | http://localhost:3000     |
| Admin    | http://localhost:3001     |
| POS      | http://localhost:3002     |
| API      | http://localhost:4000     |

API health check: `GET http://localhost:4000/health`

## Remote Supabase workflow

```text
Local applications
        ↓
Remote Supabase DEV/STAGING
```

There is no local/Docker Supabase step. `supabase/config.toml`, `supabase/migrations/`, and
`supabase/seed.sql` are still the canonical, migration-first source of schema — they're just
applied to a remote DEV/STAGING project instead of a local Docker instance.

### Authenticate the CLI (one-time per machine)

```bash
npm run supabase:login
```

This opens a browser to authenticate the Supabase CLI to your account. It does not touch any
database. Skip if `npx supabase projects list` already succeeds (already authenticated).

### Link the repository to the DEV/STAGING project

```bash
npm run supabase:link -- --project-ref <DEV_PROJECT_REF>
```

The project ref is intentionally not hardcoded into any script — pass it explicitly. This
repository is currently linked to `tjquptsksqjmvztvfgfp` ("Multi Tenant Platform -Food"),
confirmed as the DEV/STAGING project — see `docs/DECISION_LOG.md`. If the CLI ever asks for a
database password interactively, provide it directly at the prompt — never put it in a file.

### Check migration status

```bash
npm run supabase:migrations   # supabase migration list --linked — read-only
```

Shows which migrations exist locally in `supabase/migrations/` vs. which have been applied to
the linked remote project.

### Apply local migrations to DEV/STAGING

```bash
npm run supabase:push   # supabase db push --linked — SCHEMA-CHANGING
```

Applies any local migrations not yet present on the linked project. This *does* change the
remote database — review the migration SQL first. There is deliberately no `supabase:reset`
script: a full remote reset is destructive and this repo never automates that.

### Generate TypeScript types from the current schema

```bash
npm run supabase:types
```

Regenerates `packages/database-types/src/database.ts` from the linked project's live schema
(wraps `supabase gen types typescript --linked`) and re-exports it from
`packages/database-types/src/index.ts`. Run this after every migration that changes the schema.

### Verify connectivity (non-destructive)

```bash
npm run supabase:verify
```

Runs `scripts/verify-supabase-connection.mjs`, which makes one read-only request to the linked
project's Supabase Auth health endpoint using `SUPABASE_URL` + `SUPABASE_PUBLISHABLE_KEY` (or
the legacy anon key) from your environment, and reports reachability. It never prints the key
itself. Requires a local `.env` with those two variables set. (PostgREST's own root endpoint
now requires the secret key on this project — schema introspection is gated — so it isn't a
usable target for a check meant to run with the browser-safe key.)

## Common commands

```bash
npm run dev          # run all apps in dev mode
npm run build         # build all apps/packages
npm run lint           # lint all workspaces
npm run typecheck       # typecheck all workspaces
npm run test              # unit tests (Vitest)
npm run test:e2e           # e2e smoke tests (Playwright)
npm run format               # format with Prettier
npm run format:check          # check formatting without writing
```

## Troubleshooting

- **`supabase migration list --linked` / `supabase:push` fails to connect** — check
  `npx supabase projects list` succeeds first (CLI authentication); if not, run
  `npm run supabase:login`. If authenticated but still failing, confirm the project ref with
  `cat supabase/.temp/project-ref` matches the intended DEV/STAGING project.
- **`supabase:verify` reports missing env vars** — it reads `SUPABASE_URL` and
  `SUPABASE_PUBLISHABLE_KEY` (or `SUPABASE_ANON_KEY`) from `process.env`; make sure you've
  copied `.env.example` to `.env` and filled in real values (see "Environment variables"
  above).
- **Port already in use** — another process is bound to 3000/3001/3002/4000. Stop it or check
  `netstat -ano | findstr :<port>` (Windows) to find the owning process.
- **TypeScript can't resolve a `@platform/*` package** — run `npm install` at the repo root so
  npm workspaces symlinks packages into `node_modules`.
- **ESLint can't find a shared config** — the same as above; shared configs
  (`@platform/eslint-config`) are workspace packages, not published npm packages.
