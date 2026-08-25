-- Module 1B: organisation_relationships
--
-- Time-bound relationships between two independent organisations (CLIENT, SERVICE_PROVIDER,
-- LANDLORD, VENDOR, ...). Never overwritten. Uses `date` granularity deliberately — an org-to-org
-- relationship has no single associated timezone. See
-- docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md, Sections B and J.
--
-- Overlap between relationships of the same type is NOT enforced here by design (Section J /
-- Section L decision #1) — type-specific exclusivity is a policy-layer concern, deferred.

create table public.organisation_relationships (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants (id) on delete restrict,
  source_organisation_id uuid not null,
  target_organisation_id uuid not null,
  relationship_type_id uuid not null references public.organisation_relationship_types (id),
  effective_from date not null default current_date,
  effective_until date,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint organisation_relationships_not_self
    check (source_organisation_id <> target_organisation_id),
  constraint organisation_relationships_date_range_check
    check (effective_until is null or effective_until >= effective_from),
  constraint organisation_relationships_status_check
    check (status in ('active', 'ended', 'cancelled')),
  constraint organisation_relationships_source_fk
    foreign key (tenant_id, source_organisation_id)
    references public.organisations (tenant_id, id)
    on delete restrict,
  constraint organisation_relationships_target_fk
    foreign key (tenant_id, target_organisation_id)
    references public.organisations (tenant_id, id)
    on delete restrict
);

create index organisation_relationships_tenant_id_idx on public.organisation_relationships (tenant_id);
create index organisation_relationships_source_idx on public.organisation_relationships (source_organisation_id);
create index organisation_relationships_target_idx on public.organisation_relationships (target_organisation_id);
create index organisation_relationships_type_idx on public.organisation_relationships (relationship_type_id);
-- Fast "what's currently active" lookups.
create index organisation_relationships_current_idx
  on public.organisation_relationships (source_organisation_id, target_organisation_id)
  where effective_until is null;

create trigger trg_organisation_relationships_set_updated_at
  before update on public.organisation_relationships
  for each row execute function public.set_updated_at();

alter table public.organisation_relationships enable row level security;
