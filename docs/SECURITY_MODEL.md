# Security Model

Status: directional. Auth, RLS, and device trust are **not implemented yet** — this document
records the rules the implementation must follow when those modules are built.

## Remote DEV/STAGING Supabase environment

Docker is not permitted in this development environment, so there is no local Supabase
instance. All development happens against a dedicated **remote DEV/STAGING** Supabase project
(currently `tjquptsksqjmvztvfgfp`, "Multi Tenant Platform -Food" — confirmed by the project
owner, recorded in `docs/DECISION_LOG.md`). This does not change the target production
architecture — a separate, still-to-be-created **production** Supabase project remains
completely isolated from DEV/STAGING, with its own keys and its own link. Nothing in this repo
should ever assume the currently-linked project is production-safe; scripts that can write
schema or data must check `SUPABASE_ENV` first (see `@platform/config`'s `getSupabaseEnv()`) —
"a project is linked" is not the same as "a project is verified safe."

## Authentication — Supabase Auth

- All human users authenticate via Supabase Auth. No custom auth system.
- Frontend apps use the Supabase JS client with the **publishable key** (or legacy anon key)
  only.
- The Platform API validates the caller's Supabase session/JWT server-side before trusting any
  identity claim from a request.

### Intended identity model (not implemented yet)

```
Supabase Auth
      ↓
auth.users
      ↓
Platform Profile
      ↓
Membership
      ↓
Tenant/Site/Outlet access
```

`auth.users` stays exactly what Supabase Auth manages — it must not accumulate business fields.
A separate "Platform Profile" table (Module 2+) holds platform-specific user data, linked
1:1 to `auth.users` by id. "Membership" rows are what actually grant a profile access to a
tenant/site/outlet with a given persona/role — a user can hold multiple memberships (e.g. staff
at one outlet, customer elsewhere). This keeps identity (who you are) cleanly separate from
authorization scope (what you can access, and as whom), which is what lets the same person be,
say, a cashier at one outlet and a customer app user in general.

## Authorization — Row Level Security (RLS)

The full security-layering model, from least to most trusted:

```
Authentication
      ↓
Application Authorization
      ↓
Policy Engine
      ↓
PostgreSQL RLS
```

Each layer is expected to hold even if the layer above it has a bug — RLS is the backstop, not
the primary control.

Rules:

1. RLS is mandatory for every tenant-owned table unless explicitly justified otherwise in
   `docs/DECISION_LOG.md`. A migration introducing a tenant-scoped table without RLS is
   incomplete.
2. RLS policies are the last line of defense, not the first: the API layer should also enforce
   scoping (tenant/site/outlet/persona) so that a bug in a policy isn't the only thing standing
   between a user and another tenant's data.
3. RLS policies must be tested with real authenticated and anonymous test contexts (e.g. via
   `supabase test db` or equivalent), not just written and trusted. Untested policies are
   treated as unverified.
4. The secret/service-role key must never be used as a shortcut to bypass normal application
   authorization — it exists for genuinely privileged server operations, not convenience.
5. Cross-tenant isolation must have explicit tests (Tenant A must never be able to read/write
   Tenant B's rows) once tenant-owned tables exist — this is a Module 1+ deliverable.

## Tenant isolation

- Isolation is enforced primarily through RLS keyed on tenant/site/outlet identifiers present
  in the authenticated user's claims or a joined membership table.
- No query path should rely on the client to self-report which tenant it belongs to for
  authorization purposes — the server derives it from the authenticated session.

## Server-side enforcement

- Business rules and entitlement checks are enforced in the Platform API (or in RLS), never
  solely in a channel app. A channel app hiding a button is a UX nicety, not a security
  control.

## Secret handling

- The Supabase **secret key** (`sb_secret_...`, or the legacy `service_role` JWT) bypasses RLS
  and must never be shipped to any frontend bundle or channel app. It is used only in trusted
  server-side contexts (the Platform API, migration/admin tooling). `@platform/supabase-client`'s
  `createBrowserSupabaseClient` actively rejects a key that looks like a secret key as a
  defensive check, and `createServerSupabaseClient` refuses to run in a `window` context.
- `NEXT_PUBLIC_*` variables are, by Next.js convention, bundled into client-side JavaScript —
  only the Supabase URL and the **publishable** key (or legacy anon key) belong there.
  `SUPABASE_SECRET_KEY` / `SUPABASE_SERVICE_ROLE_KEY` must never be prefixed `NEXT_PUBLIC_` or
  referenced from client components.
- Real secrets live only in untracked env files (`.env`, `.env.local`) or a secrets manager in
  deployed environments — never in tracked files. `.env.example` holds placeholders only.
- DEV/STAGING and production Supabase projects are separate projects with separate keys. A key
  for one environment must never be reused in another. There is no local Docker Supabase in
  this workflow, so "local" here means "your own `.env`, pointed at DEV/STAGING" — never at
  production.
- Careful with CLI output: `supabase projects api-keys` prints legacy `anon`/`service_role`
  JWTs in full even without `--reveal` (only the new `sb_secret_...` key format is masked by
  default). Treat any terminal session or log that ran this command as sensitive, and prefer
  reading keys from the Supabase dashboard instead.

## Migration-first database management

- `supabase/migrations/` is the only source of schema truth. Dashboard-only changes against
  DEV/STAGING (or any environment) are disallowed — they don't reproduce, and they drift from
  what production would get.
- The safe remote workflow is: write a migration locally → review the SQL → apply with
  `npm run supabase:push` (`supabase db push --linked`) → verify → regenerate types
  (`npm run supabase:types`) → run tests → commit. See `docs/DEVELOPMENT_SETUP.md`.
- There is deliberately no `supabase:reset`-style script wired to the remote project. A full
  reset is destructive; if one is ever genuinely needed, it's a manual, explicit CLI invocation
  with the target environment double-checked first, not a one-word npm script.

## Production safety rules

- Production Supabase does not exist yet in this repo (only DEV/STAGING is linked). When it is
  created, it must be a distinct Supabase project with distinct keys — never the same project
  promoted in place.
- No script in this repo should ever hardcode a project ref or auto-select "whichever project
  is currently linked" for a privileged operation without an explicit environment check
  (`SUPABASE_ENV`).
- Production credentials, once they exist, follow the same rule as any other secret: never in
  tracked files, server-side only, and never reused across environments.

## Device trust vs. user authorization

- These are two different concerns and must not be conflated: a user's identity/permissions
  (via Supabase Auth + RLS) determine *what they're allowed to do*; device trust (future work —
  e.g. a registered POS terminal or kiosk) determines *whether this physical device is allowed
  to act as a channel at all*. A trusted device does not imply an authorized user, and an
  authorized user does not imply a trusted device.
- Device-level credentials (when implemented) are modeled separately from user sessions.

## Audit

- Actions that change tenant data are expected to be auditable (future work). The audit trail
  is a platform-level concern, implemented once and reused by every channel — not something
  each channel implements independently.
