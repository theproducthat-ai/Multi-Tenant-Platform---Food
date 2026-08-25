# Module Master

## Completed modules

**Module 0 — Prerequisite and Environment Setup**

Scope: monorepo tooling, shared config, minimal app/API scaffolds for environment verification,
Supabase CLI + local project initialization, documentation, and testing foundation. No business
functionality. See `docs/BUILD_STATUS.md` for exact completion state.

## Current module

**Module 0A — Remote Supabase Development Environment**

Scope: replace the Docker-based local Supabase workflow (not permitted in this development
environment) with a migration-first workflow against a dedicated remote DEV/STAGING Supabase
project. CLI auth/link, safe remote-only npm scripts, real (tableless) generated database
types, a browser/server Supabase client package, and updated architecture/security
documentation. Still no business functionality — no tenants, users, or product tables. See
`docs/BUILD_STATUS.md` for exact completion state.

## Future modules (high level, not yet scoped in detail)

Order and numbering are indicative, not committed — each module gets properly scoped when it
starts.

1. **Module 1 — Core data model & multi-tenancy foundation**: tenants, sites, outlets, initial
   RLS-protected schema, first real migrations (applied to DEV/STAGING via `supabase:push`).
2. **Module 2 — Identity & access**: Supabase Auth integration, user-scoped outlet access,
   persona/role model.
3. **Module 3 — Configuration & policy engine**: implements the inheritance model in
   `docs/CONFIGURATION_MODEL.md`.
4. **Module 4 — Capability registry & entitlements**: what a tenant/site/persona is allowed to
   use.
5. **Module 5+ — Product modules**: ordering, pre-order, POS workflows, SOK, KDS, payments,
   wallet, NFC, facial recognition, marketing, reporting — each scoped independently when
   started.

Do not begin any future module without an explicit instruction to do so.
