-- Module 1B: organisation_resource_assignments
--
-- "Organisation X plays role R over resource Y" (OWNS/MANAGES/OCCUPIES/LEASES/OPERATES/SERVES/
-- MAINTAINS/SUPPLIES), targeting Property, Site, Site Area, or Service Location. Typed nullable
-- target columns + exactly-one-non-null CHECK (Scope Model Option B, Section D).
--
-- site_area_site_id / service_location_site_id are parent-context columns (Section L decision
-- #2): site_areas/service_locations only expose a context-qualified unique (tenant_id, site_id,
-- id), not a bare (tenant_id, id), so a composite FK from here needs the site_id alongside the
-- target id. The composite FK also guarantees the supplied context always matches the target's
-- real site — it cannot drift.
--
-- effective_from/effective_until use timestamptz (not date, unlike organisation_relationships):
-- every target here is anchored to a site with a real timezone, so a plain date would be
-- ambiguous across a globally distributed estate (Section J).

create table public.organisation_resource_assignments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete restrict,
  organisation_id uuid not null,
  role_type_id uuid not null references public.organisation_resource_role_types (id),
  property_id uuid,
  site_id uuid,
  site_area_id uuid,
  site_area_site_id uuid,
  service_location_id uuid,
  service_location_site_id uuid,
  effective_from timestamptz not null default now(),
  effective_until timestamptz,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ora_organisation_fk
    foreign key (tenant_id, organisation_id)
    references public.organisations (tenant_id, id)
    on delete restrict,
  constraint ora_property_fk
    foreign key (tenant_id, property_id)
    references public.properties (tenant_id, id)
    on delete restrict,
  constraint ora_site_fk
    foreign key (tenant_id, site_id)
    references public.sites (tenant_id, id)
    on delete restrict,
  constraint ora_site_area_fk
    foreign key (tenant_id, site_area_site_id, site_area_id)
    references public.site_areas (tenant_id, site_id, id)
    on delete restrict,
  constraint ora_service_location_fk
    foreign key (tenant_id, service_location_site_id, service_location_id)
    references public.service_locations (tenant_id, site_id, id)
    on delete restrict,
  constraint ora_exactly_one_target
    check (num_nonnulls(property_id, site_id, site_area_id, service_location_id) = 1),
  constraint ora_site_area_context_pairing
    check ((site_area_id is null) = (site_area_site_id is null)),
  constraint ora_service_location_context_pairing
    check ((service_location_id is null) = (service_location_site_id is null)),
  constraint ora_date_range_check
    check (effective_until is null or effective_until >= effective_from),
  constraint ora_status_check check (status in ('active', 'ended', 'cancelled'))
);

create index ora_tenant_id_idx on public.organisation_resource_assignments (tenant_id);
create index ora_organisation_id_idx on public.organisation_resource_assignments (organisation_id);
create index ora_role_type_id_idx on public.organisation_resource_assignments (role_type_id);
create index ora_property_id_idx
  on public.organisation_resource_assignments (property_id) where property_id is not null;
create index ora_site_id_idx
  on public.organisation_resource_assignments (site_id) where site_id is not null;
create index ora_site_area_id_idx
  on public.organisation_resource_assignments (site_area_id) where site_area_id is not null;
create index ora_service_location_id_idx
  on public.organisation_resource_assignments (service_location_id)
  where service_location_id is not null;
-- Fast "what's currently assigned" lookups, one per target type.
create index ora_property_current_idx
  on public.organisation_resource_assignments (property_id)
  where property_id is not null and effective_until is null;
create index ora_site_current_idx
  on public.organisation_resource_assignments (site_id)
  where site_id is not null and effective_until is null;
create index ora_site_area_current_idx
  on public.organisation_resource_assignments (site_area_id)
  where site_area_id is not null and effective_until is null;
create index ora_service_location_current_idx
  on public.organisation_resource_assignments (service_location_id)
  where service_location_id is not null and effective_until is null;

create trigger trg_ora_set_updated_at
  before update on public.organisation_resource_assignments
  for each row execute function public.set_updated_at();

alter table public.organisation_resource_assignments enable row level security;
