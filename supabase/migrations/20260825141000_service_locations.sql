-- Module 1B: service_locations
--
-- Where a service is produced/delivered/ordered/consumed (cafeteria, kitchen, kiosk, etc.).
-- is_consumer_facing is explicit (do not assume every location is consumer-facing). See
-- docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md, Sections B and F.

create table public.service_locations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete restrict,
  site_id uuid not null,
  site_area_id uuid,
  parent_service_location_id uuid,
  service_location_type_id uuid not null references public.service_location_types (id),
  code text not null,
  name text not null,
  is_consumer_facing boolean not null default true,
  lifecycle_status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint service_locations_site_id_code_key unique (site_id, code),
  -- The only FK-support unique this table exposes (Section L decision #2): junction tables that
  -- target a service location carry their own site_id context column instead of this table also
  -- exposing a bare (tenant_id, id).
  constraint service_locations_tenant_site_id_key unique (tenant_id, site_id, id),
  constraint service_locations_no_self_parent check (id <> parent_service_location_id),
  constraint service_locations_lifecycle_status_check
    check (lifecycle_status in ('draft', 'active', 'inactive', 'suspended', 'archived')),
  constraint service_locations_site_fk
    foreign key (tenant_id, site_id)
    references public.sites (tenant_id, id)
    on delete restrict,
  -- Composite FK: when set, guarantees the site area belongs to the SAME site as this location.
  constraint service_locations_site_area_fk
    foreign key (tenant_id, site_id, site_area_id)
    references public.site_areas (tenant_id, site_id, id)
    on delete restrict,
  constraint service_locations_parent_fk
    foreign key (tenant_id, site_id, parent_service_location_id)
    references public.service_locations (tenant_id, site_id, id)
    on delete restrict
);

create index service_locations_tenant_id_idx on public.service_locations (tenant_id);
create index service_locations_site_id_idx on public.service_locations (site_id);
create index service_locations_site_area_id_idx on public.service_locations (site_area_id);
create index service_locations_parent_service_location_id_idx
  on public.service_locations (parent_service_location_id);

create trigger trg_service_locations_set_updated_at
  before update on public.service_locations
  for each row execute function public.set_updated_at();

create trigger trg_service_locations_prevent_cycle
  before insert or update of parent_service_location_id, site_id on public.service_locations
  for each row execute function public.prevent_service_location_cycle();

alter table public.service_locations enable row level security;
