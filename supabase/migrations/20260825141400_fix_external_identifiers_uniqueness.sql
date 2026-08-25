-- Module 1B fix: external_identifiers_unique_target was ineffective.
--
-- Postgres composite UNIQUE constraints treat NULL as distinct from NULL by default. Since
-- exactly one of the seven target columns on external_identifiers is ever non-null per row (the
-- external_identifiers_exactly_one_target CHECK), the other six are always NULL — so no two rows
-- could ever be considered equal on those always-NULL columns, silently defeating the intended
-- uniqueness. Confirmed via scripts/verify-module-1-schema.sql
-- (external_identifier_duplicate_target_rejected failed: a duplicate insert succeeded when it
-- should have been rejected).
--
-- Fixed using the same partial-unique-index-per-target-column pattern already used successfully
-- by portfolio_members (see 20260825141200_portfolios_and_members.sql), rather than
-- `NULLS NOT DISTINCT` on the wide constraint: each partial index only ever indexes rows where
-- its one target column is non-null, so the NULL-distinctness problem cannot recur.

alter table public.external_identifiers drop constraint external_identifiers_unique_target;

create unique index external_identifiers_unique_organisation
  on public.external_identifiers (tenant_id, source_system, external_type, organisation_id)
  where organisation_id is not null;

create unique index external_identifiers_unique_organisation_unit
  on public.external_identifiers (tenant_id, source_system, external_type, organisation_unit_id)
  where organisation_unit_id is not null;

create unique index external_identifiers_unique_portfolio
  on public.external_identifiers (tenant_id, source_system, external_type, portfolio_id)
  where portfolio_id is not null;

create unique index external_identifiers_unique_property
  on public.external_identifiers (tenant_id, source_system, external_type, property_id)
  where property_id is not null;

create unique index external_identifiers_unique_site
  on public.external_identifiers (tenant_id, source_system, external_type, site_id)
  where site_id is not null;

create unique index external_identifiers_unique_site_area
  on public.external_identifiers (tenant_id, source_system, external_type, site_area_id)
  where site_area_id is not null;

create unique index external_identifiers_unique_service_location
  on public.external_identifiers (tenant_id, source_system, external_type, service_location_id)
  where service_location_id is not null;
