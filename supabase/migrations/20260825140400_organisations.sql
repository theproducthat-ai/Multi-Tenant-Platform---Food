-- Module 1B: organisations
--
-- A real-world organisation/legal/business entity or institution, tenant-scoped, with a
-- recursive parent hierarchy. See docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md, Section B.

create table public.organisations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete restrict,
  organisation_type_id uuid not null references public.organisation_types (id),
  parent_organisation_id uuid,
  code text not null,
  name text not null,
  country_of_registration_code char(2),
  lifecycle_status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint organisations_tenant_id_code_key unique (tenant_id, code),
  -- FK-support unique: lets composite FKs from this table's own self-reference, and from other
  -- tenant-owned tables, guarantee "same tenant" at the database level (Section E).
  constraint organisations_tenant_id_id_key unique (tenant_id, id),
  constraint organisations_no_self_parent check (id <> parent_organisation_id),
  constraint organisations_lifecycle_status_check
    check (lifecycle_status in ('draft', 'active', 'inactive', 'suspended', 'archived')),
  constraint organisations_country_code_format
    check (country_of_registration_code is null or country_of_registration_code ~ '^[A-Z]{2}$'),
  -- Composite FK: guarantees a parent organisation belongs to the same tenant, for free.
  constraint organisations_parent_fk
    foreign key (tenant_id, parent_organisation_id)
    references public.organisations (tenant_id, id)
    on delete restrict
);

create index organisations_tenant_id_idx on public.organisations (tenant_id);
create index organisations_parent_organisation_id_idx on public.organisations (parent_organisation_id);

create trigger trg_organisations_set_updated_at
  before update on public.organisations
  for each row execute function public.set_updated_at();

create trigger trg_organisations_prevent_cycle
  before insert or update of parent_organisation_id on public.organisations
  for each row execute function public.prevent_organisation_cycle();

alter table public.organisations enable row level security;
