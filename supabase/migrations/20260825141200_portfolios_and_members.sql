-- Module 1B: portfolios, portfolio_members
--
-- Portfolio: logical management grouping independent of organisation or geography. No
-- portfolio_types registry (Section C) — a portfolio is a free-form, user-named grouping.
--
-- portfolio_members: typed nullable target columns + exactly-one-non-null CHECK (Scope Model
-- Option B, Section D), with parent-context columns for organisation_unit/site_area/
-- service_location targets (Section L decision #2) — see rationale in the
-- organisation_resource_assignments migration.
--
-- effective_from/effective_until use timestamptz — membership changes are operational/admin
-- actions where the exact moment matters, not a business-day-level fact (Section J).

create table public.portfolios (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete restrict,
  code text not null,
  name text not null,
  description text,
  lifecycle_status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint portfolios_tenant_id_code_key unique (tenant_id, code),
  constraint portfolios_tenant_id_id_key unique (tenant_id, id),
  constraint portfolios_lifecycle_status_check
    check (lifecycle_status in ('draft', 'active', 'inactive', 'suspended', 'archived'))
);

create index portfolios_tenant_id_idx on public.portfolios (tenant_id);

create trigger trg_portfolios_set_updated_at
  before update on public.portfolios
  for each row execute function public.set_updated_at();

alter table public.portfolios enable row level security;

create table public.portfolio_members (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete restrict,
  portfolio_id uuid not null,
  organisation_id uuid,
  organisation_unit_id uuid,
  organisation_unit_organisation_id uuid,
  property_id uuid,
  site_id uuid,
  site_area_id uuid,
  site_area_site_id uuid,
  service_location_id uuid,
  service_location_site_id uuid,
  effective_from timestamptz not null default now(),
  effective_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- The owning portfolio is the one documented exception to "no cascade delete of structural
  -- rows" (Section L decision #3): a membership row has no meaning without its portfolio.
  constraint portfolio_members_portfolio_fk
    foreign key (tenant_id, portfolio_id)
    references public.portfolios (tenant_id, id)
    on delete cascade,
  constraint portfolio_members_organisation_fk
    foreign key (tenant_id, organisation_id)
    references public.organisations (tenant_id, id)
    on delete restrict,
  constraint portfolio_members_org_unit_fk
    foreign key (tenant_id, organisation_unit_organisation_id, organisation_unit_id)
    references public.organisation_units (tenant_id, organisation_id, id)
    on delete restrict,
  constraint portfolio_members_property_fk
    foreign key (tenant_id, property_id)
    references public.properties (tenant_id, id)
    on delete restrict,
  constraint portfolio_members_site_fk
    foreign key (tenant_id, site_id)
    references public.sites (tenant_id, id)
    on delete restrict,
  constraint portfolio_members_site_area_fk
    foreign key (tenant_id, site_area_site_id, site_area_id)
    references public.site_areas (tenant_id, site_id, id)
    on delete restrict,
  constraint portfolio_members_service_location_fk
    foreign key (tenant_id, service_location_site_id, service_location_id)
    references public.service_locations (tenant_id, site_id, id)
    on delete restrict,
  constraint portfolio_members_exactly_one_target check (
    num_nonnulls(
      organisation_id, organisation_unit_id, property_id, site_id, site_area_id,
      service_location_id
    ) = 1
  ),
  constraint portfolio_members_org_unit_context_pairing
    check ((organisation_unit_id is null) = (organisation_unit_organisation_id is null)),
  constraint portfolio_members_site_area_context_pairing
    check ((site_area_id is null) = (site_area_site_id is null)),
  constraint portfolio_members_service_location_context_pairing
    check ((service_location_id is null) = (service_location_site_id is null)),
  constraint portfolio_members_date_range_check
    check (effective_until is null or effective_until >= effective_from)
);

create index portfolio_members_tenant_id_idx on public.portfolio_members (tenant_id);
create index portfolio_members_portfolio_id_idx on public.portfolio_members (portfolio_id);
create index portfolio_members_organisation_id_idx
  on public.portfolio_members (organisation_id) where organisation_id is not null;
create index portfolio_members_organisation_unit_id_idx
  on public.portfolio_members (organisation_unit_id) where organisation_unit_id is not null;
create index portfolio_members_property_id_idx
  on public.portfolio_members (property_id) where property_id is not null;
create index portfolio_members_site_id_idx
  on public.portfolio_members (site_id) where site_id is not null;
create index portfolio_members_site_area_id_idx
  on public.portfolio_members (site_area_id) where site_area_id is not null;
create index portfolio_members_service_location_id_idx
  on public.portfolio_members (service_location_id) where service_location_id is not null;

-- Prevent duplicate active membership of the same resource in the same portfolio: one partial
-- unique index per target column (simpler and more efficient than one expression index over six
-- coalesced columns).
create unique index portfolio_members_unique_organisation_active
  on public.portfolio_members (portfolio_id, organisation_id)
  where organisation_id is not null and effective_until is null;
create unique index portfolio_members_unique_organisation_unit_active
  on public.portfolio_members (portfolio_id, organisation_unit_id)
  where organisation_unit_id is not null and effective_until is null;
create unique index portfolio_members_unique_property_active
  on public.portfolio_members (portfolio_id, property_id)
  where property_id is not null and effective_until is null;
create unique index portfolio_members_unique_site_active
  on public.portfolio_members (portfolio_id, site_id)
  where site_id is not null and effective_until is null;
create unique index portfolio_members_unique_site_area_active
  on public.portfolio_members (portfolio_id, site_area_id)
  where site_area_id is not null and effective_until is null;
create unique index portfolio_members_unique_service_location_active
  on public.portfolio_members (portfolio_id, service_location_id)
  where service_location_id is not null and effective_until is null;

create trigger trg_portfolio_members_set_updated_at
  before update on public.portfolio_members
  for each row execute function public.set_updated_at();

alter table public.portfolio_members enable row level security;
