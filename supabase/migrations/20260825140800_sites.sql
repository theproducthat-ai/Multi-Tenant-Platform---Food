-- Module 1B: sites
--
-- Operational physical/virtual/hybrid location — the primary structural unit later capabilities
-- attach to. timezone is required (even for virtual sites) so future business-date/calendar
-- logic always has a correct anchor. See docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md, Sections B, G.

create table public.sites (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete restrict,
  property_id uuid,
  site_type_id uuid not null references public.site_types (id),
  mode text not null default 'physical',
  code text not null,
  name text not null,
  address_line_1 text,
  address_line_2 text,
  locality text,
  administrative_area text,
  postal_code text,
  country_code char(2),
  latitude numeric(9, 6),
  longitude numeric(9, 6),
  timezone text not null,
  currency_code char(3),
  locale text,
  lifecycle_status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint sites_tenant_id_code_key unique (tenant_id, code),
  constraint sites_tenant_id_id_key unique (tenant_id, id),
  constraint sites_mode_check check (mode in ('physical', 'virtual', 'hybrid')),
  constraint sites_lifecycle_status_check
    check (lifecycle_status in ('draft', 'active', 'inactive', 'suspended', 'archived')),
  constraint sites_country_code_format
    check (country_code is null or country_code ~ '^[A-Z]{2}$'),
  constraint sites_currency_code_format
    check (currency_code is null or currency_code ~ '^[A-Z]{3}$'),
  -- Prevents a nonsensical physical address on a declared-virtual site, without forbidding a
  -- physical/hybrid site from lacking an address (not every site needs full geocoding day one).
  constraint sites_virtual_no_address check (
    mode <> 'virtual'
    or (address_line_1 is null and country_code is null and latitude is null and longitude is null)
  ),
  constraint sites_property_fk
    foreign key (tenant_id, property_id)
    references public.properties (tenant_id, id)
    on delete restrict
);

create index sites_tenant_id_idx on public.sites (tenant_id);
create index sites_property_id_idx on public.sites (property_id);
-- Hot path: "active sites for tenant".
create index sites_tenant_lifecycle_idx on public.sites (tenant_id, lifecycle_status);

create trigger trg_sites_set_updated_at
  before update on public.sites
  for each row execute function public.set_updated_at();

alter table public.sites enable row level security;
