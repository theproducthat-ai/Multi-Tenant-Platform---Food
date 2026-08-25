-- Module 1B: external_identifiers
--
-- Generic extension point for identifiers owned by external systems (SAP, Workday, HRMS,
-- access-control, vendor systems), without polluting structural tables with per-integration
-- columns. Typed nullable target columns + parent-context columns, same pattern as
-- portfolio_members / organisation_resource_assignments. See
-- docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md, Section B.

create table public.external_identifiers (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete restrict,
  organisation_id uuid,
  organisation_unit_id uuid,
  organisation_unit_organisation_id uuid,
  portfolio_id uuid,
  property_id uuid,
  site_id uuid,
  site_area_id uuid,
  site_area_site_id uuid,
  service_location_id uuid,
  service_location_site_id uuid,
  source_system text not null,
  external_type text not null,
  external_value text not null,
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint external_identifiers_organisation_fk
    foreign key (tenant_id, organisation_id)
    references public.organisations (tenant_id, id)
    on delete restrict,
  constraint external_identifiers_org_unit_fk
    foreign key (tenant_id, organisation_unit_organisation_id, organisation_unit_id)
    references public.organisation_units (tenant_id, organisation_id, id)
    on delete restrict,
  constraint external_identifiers_portfolio_fk
    foreign key (tenant_id, portfolio_id)
    references public.portfolios (tenant_id, id)
    on delete restrict,
  constraint external_identifiers_property_fk
    foreign key (tenant_id, property_id)
    references public.properties (tenant_id, id)
    on delete restrict,
  constraint external_identifiers_site_fk
    foreign key (tenant_id, site_id)
    references public.sites (tenant_id, id)
    on delete restrict,
  constraint external_identifiers_site_area_fk
    foreign key (tenant_id, site_area_site_id, site_area_id)
    references public.site_areas (tenant_id, site_id, id)
    on delete restrict,
  constraint external_identifiers_service_location_fk
    foreign key (tenant_id, service_location_site_id, service_location_id)
    references public.service_locations (tenant_id, site_id, id)
    on delete restrict,
  constraint external_identifiers_exactly_one_target check (
    num_nonnulls(
      organisation_id, organisation_unit_id, portfolio_id, property_id, site_id, site_area_id,
      service_location_id
    ) = 1
  ),
  constraint external_identifiers_org_unit_context_pairing
    check ((organisation_unit_id is null) = (organisation_unit_organisation_id is null)),
  constraint external_identifiers_site_area_context_pairing
    check ((site_area_id is null) = (site_area_site_id is null)),
  constraint external_identifiers_service_location_context_pairing
    check ((service_location_id is null) = (service_location_site_id is null)),
  -- Context columns are functionally dependent on their target and are omitted from this key;
  -- exactly one target column is non-null per row so this correctly catches duplicates.
  constraint external_identifiers_unique_target unique (
    tenant_id, source_system, external_type, organisation_id, organisation_unit_id, portfolio_id,
    property_id, site_id, site_area_id, service_location_id
  )
);

create index external_identifiers_tenant_id_idx on public.external_identifiers (tenant_id);
create index external_identifiers_organisation_id_idx
  on public.external_identifiers (organisation_id) where organisation_id is not null;
create index external_identifiers_organisation_unit_id_idx
  on public.external_identifiers (organisation_unit_id) where organisation_unit_id is not null;
create index external_identifiers_portfolio_id_idx
  on public.external_identifiers (portfolio_id) where portfolio_id is not null;
create index external_identifiers_property_id_idx
  on public.external_identifiers (property_id) where property_id is not null;
create index external_identifiers_site_id_idx
  on public.external_identifiers (site_id) where site_id is not null;
create index external_identifiers_site_area_id_idx
  on public.external_identifiers (site_area_id) where site_area_id is not null;
create index external_identifiers_service_location_id_idx
  on public.external_identifiers (service_location_id) where service_location_id is not null;

create trigger trg_external_identifiers_set_updated_at
  before update on public.external_identifiers
  for each row execute function public.set_updated_at();

alter table public.external_identifiers enable row level security;
