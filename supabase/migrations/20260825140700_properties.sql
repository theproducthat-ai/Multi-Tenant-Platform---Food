-- Module 1B: properties
--
-- Optional estate/building ownership layer above Site. Address fields are structural columns,
-- not a dedicated Address entity (Section H) — globally neutral, no mandatory India-specific
-- fields. See docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md, Section B.

create table public.properties (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete restrict,
  property_type_id uuid not null references public.property_types (id),
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
  lifecycle_status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint properties_tenant_id_code_key unique (tenant_id, code),
  constraint properties_tenant_id_id_key unique (tenant_id, id),
  constraint properties_lifecycle_status_check
    check (lifecycle_status in ('draft', 'active', 'inactive', 'suspended', 'archived')),
  constraint properties_country_code_format
    check (country_code is null or country_code ~ '^[A-Z]{2}$')
);

create index properties_tenant_id_idx on public.properties (tenant_id);

create trigger trg_properties_set_updated_at
  before update on public.properties
  for each row execute function public.set_updated_at();

alter table public.properties enable row level security;
