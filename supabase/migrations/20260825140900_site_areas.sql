-- Module 1B: site_areas
--
-- Recursive physical/operational subdivision of a site (building -> floor -> zone, etc.). See
-- docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md, Sections B and F.

create table public.site_areas (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete restrict,
  site_id uuid not null,
  site_area_type_id uuid not null references public.site_area_types (id),
  parent_site_area_id uuid,
  code text not null,
  name text not null,
  lifecycle_status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint site_areas_site_id_code_key unique (site_id, code),
  -- The only FK-support unique this table exposes (Section L decision #2): junction tables that
  -- target a site area carry their own site_id context column instead of this table also
  -- exposing a bare (tenant_id, id).
  constraint site_areas_tenant_site_id_key unique (tenant_id, site_id, id),
  constraint site_areas_no_self_parent check (id <> parent_site_area_id),
  constraint site_areas_lifecycle_status_check
    check (lifecycle_status in ('draft', 'active', 'inactive', 'suspended', 'archived')),
  constraint site_areas_site_fk
    foreign key (tenant_id, site_id)
    references public.sites (tenant_id, id)
    on delete restrict,
  constraint site_areas_parent_fk
    foreign key (tenant_id, site_id, parent_site_area_id)
    references public.site_areas (tenant_id, site_id, id)
    on delete restrict
);

create index site_areas_tenant_id_idx on public.site_areas (tenant_id);
create index site_areas_site_id_idx on public.site_areas (site_id);
create index site_areas_parent_site_area_id_idx on public.site_areas (parent_site_area_id);

create trigger trg_site_areas_set_updated_at
  before update on public.site_areas
  for each row execute function public.set_updated_at();

create trigger trg_site_areas_prevent_cycle
  before insert or update of parent_site_area_id, site_id on public.site_areas
  for each row execute function public.prevent_site_area_cycle();

alter table public.site_areas enable row level security;
