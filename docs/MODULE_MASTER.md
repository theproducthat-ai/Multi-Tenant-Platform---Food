# Module Master

## Completed modules

**Module 0 — Prerequisite and Environment Setup**

Scope: monorepo tooling, shared config, minimal app/API scaffolds for environment verification,
Supabase CLI + local project initialization, documentation, and testing foundation. No business
functionality. See `docs/BUILD_STATUS.md` for exact completion state.

**Module 0A — Remote Supabase Development Environment**

Scope: replace the Docker-based local Supabase workflow (not permitted in this development
environment) with a migration-first workflow against a dedicated remote DEV/STAGING Supabase
project. CLI auth/link, safe remote-only npm scripts, real (tableless) generated database
types, a browser/server Supabase client package, and updated architecture/security
documentation. Still no business functionality — no tenants, users, or product tables. See
`docs/BUILD_STATUS.md` for exact completion state.

## Completed modules (continued)

**Module 1 — Global Multi-Tenancy, Organisation & Operating Structure**

- **Module 1A (architecture design)** — approved. See
  `docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md`.
- **Module 1B (database implementation)** — implemented. Tenants, organisations (recursive),
  organisation units (recursive), organisation relationships, portfolios/portfolio membership,
  properties, sites, site areas (recursive), service locations, organisation-resource assignments,
  external identifiers, and 8 reference type registries — all live on the DEV/STAGING project,
  RLS-enabled (default deny, no membership model yet), verified via `npm run verify:module-1`.
- **Module 1C (scenario validation & closure)** — complete. 8 global scenarios (food service,
  global enterprise, conglomerate, property/realtor, mall, hospital, education, manufacturing)
  validated live with zero schema changes — see `docs/ORGANISATION_MODEL.md`.
- Explicitly not part of Module 1: users, memberships, roles, permissions, devices, configuration,
  ordering, and everything else listed as out of scope in `CLAUDE.md` — confirmed to have clean
  attachment points, none built prematurely.

## Current module

None — Module 1 is closed. Module 2 has not been started; see below.

## Future modules (high level, not yet scoped in detail)

Order and numbering are indicative, not committed — each module gets properly scoped when it
starts.

1. **Module 2 — Identity & access**: Supabase Auth integration, user-scoped outlet access,
   persona/role model. Adds RLS *policies* to Module 1's tables (`auth.uid()` → membership →
   tenant/site access) — does not change Module 1's schema.
2. **Module 3 — Configuration & policy engine**: implements the inheritance model in
   `docs/CONFIGURATION_MODEL.md`, targeting the scopes established in Module 1 (see the Scope
   Model section of `docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md`).
3. **Module 4 — Capability registry & entitlements**: what a tenant/site/persona is allowed to
   use.
4. **Module 5+ — Product modules**: ordering, pre-order, POS workflows, SOK, KDS, payments,
   wallet, NFC, facial recognition, marketing, reporting — each scoped independently when
   started.

Do not begin any future module without an explicit instruction to do so.
