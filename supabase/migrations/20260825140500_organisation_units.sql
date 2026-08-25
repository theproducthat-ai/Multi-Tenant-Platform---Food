-- Module 1B: organisation_units
--
-- Flexible, recursive internal hierarchy inside a single organisation (business unit, division,
-- region, department, etc.) — no fixed levels. See
-- docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md, Section B.

create table public.organisation_units (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete restrict,
  organisation_id uuid not null,
  organisation_unit_type_id uuid not null references public.organisation_unit_types (id),
  parent_organisation_unit_id uuid,
  code text not null,
  name text not null,
  lifecycle_status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint organisation_units_organisation_id_code_key unique (organisation_id, code),
  -- The only FK-support unique this table exposes (Section L decision #2): junction tables that
  -- target an organisation unit carry their own organisation_id context column instead of this
  -- table also exposing a bare (tenant_id, id).
  constraint organisation_units_tenant_organisation_id_key unique (tenant_id, organisation_id, id),
  constraint organisation_units_no_self_parent check (id <> parent_organisation_unit_id),
  constraint organisation_units_lifecycle_status_check
    check (lifecycle_status in ('draft', 'active', 'inactive', 'suspended', 'archived')),
  -- Composite FK: guarantees the organisation belongs to the same tenant.
  constraint organisation_units_organisation_fk
    foreign key (tenant_id, organisation_id)
    references public.organisations (tenant_id, id)
    on delete restrict,
  -- Composite FK: guarantees the parent unit is the same tenant AND the same organisation.
  constraint organisation_units_parent_fk
    foreign key (tenant_id, organisation_id, parent_organisation_unit_id)
    references public.organisation_units (tenant_id, organisation_id, id)
    on delete restrict
);

create index organisation_units_tenant_id_idx on public.organisation_units (tenant_id);
create index organisation_units_organisation_id_idx on public.organisation_units (organisation_id);
create index organisation_units_parent_organisation_unit_id_idx
  on public.organisation_units (parent_organisation_unit_id);

create trigger trg_organisation_units_set_updated_at
  before update on public.organisation_units
  for each row execute function public.set_updated_at();

create trigger trg_organisation_units_prevent_cycle
  before insert or update of parent_organisation_unit_id, organisation_id on public.organisation_units
  for each row execute function public.prevent_organisation_unit_cycle();

alter table public.organisation_units enable row level security;
