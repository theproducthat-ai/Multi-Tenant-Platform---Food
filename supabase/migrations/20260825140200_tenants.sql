-- Module 1B: tenants
--
-- The SaaS security/data-isolation/commercial realm. Not assumed to equal a company.
-- See docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md, Section B.

create table public.tenants (
  id uuid primary key default gen_random_uuid(),
  slug text not null,
  name text not null,
  default_locale text,
  default_currency_code char(3),
  default_timezone text,
  lifecycle_status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tenants_slug_key unique (slug),
  constraint tenants_lifecycle_status_check
    check (lifecycle_status in ('draft', 'active', 'inactive', 'suspended', 'archived')),
  constraint tenants_default_currency_code_format
    check (default_currency_code is null or default_currency_code ~ '^[A-Z]{3}$')
);

create index tenants_lifecycle_status_idx on public.tenants (lifecycle_status);

create trigger trg_tenants_set_updated_at
  before update on public.tenants
  for each row execute function public.set_updated_at();

-- RLS: enabled, zero policies for anon/authenticated => default deny (Module 1 posture, no
-- membership model exists yet). service_role bypasses RLS by role attribute, not by policy.
alter table public.tenants enable row level security;
