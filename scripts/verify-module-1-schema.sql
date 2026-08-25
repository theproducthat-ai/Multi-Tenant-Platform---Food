-- Module 1B remote verification.
--
-- Entirely wrapped in one transaction that is ROLLED BACK at the very end, regardless of
-- outcome, so no fixture data is ever left behind in the target database. Every assertion is a
-- self-contained DO block: an expected-success path runs the statement directly; an
-- expected-failure path uses plpgsql's implicit per-block savepoint (via EXCEPTION) to catch the
-- error without aborting the surrounding transaction. Results are recorded into a temporary
-- table and printed as a final summary before rollback.
--
-- Intended invocation: `supabase db query --linked --file scripts/verify-module-1-schema.sql`
-- (never against a production project — see scripts/verify-module-1-schema.mjs for the guarded
-- wrapper that checks SUPABASE_ENV first).

begin;

create temporary table test_results (
  seq serial primary key,
  name text not null,
  passed boolean not null,
  detail text
);

create temporary table test_type_ids as
select
  (select id from public.organisation_types where code = 'OPERATING_COMPANY') as org_type,
  (select id from public.organisation_unit_types where code = 'DIVISION') as org_unit_type,
  (select id from public.organisation_relationship_types where code = 'CLIENT') as rel_type,
  (select id from public.organisation_resource_role_types where code = 'OPERATES') as role_type,
  (select id from public.property_types where code = 'OFFICE_PARK') as property_type,
  (select id from public.site_types where code = 'CORPORATE_CAMPUS') as site_type,
  (select id from public.site_area_types where code = 'FLOOR') as site_area_type,
  (select id from public.service_location_types where code = 'CAFETERIA') as service_location_type;

do $$
begin
  insert into test_results (name, passed, detail)
  select
    'registry_type_ids_resolved',
    org_type is not null and org_unit_type is not null and rel_type is not null
      and role_type is not null and property_type is not null and site_type is not null
      and site_area_type is not null and service_location_type is not null,
    'all 8 seeded registry codes used by this script resolved to a row'
  from test_type_ids;
end $$;

-- Fixture: two tenants, distinct global contexts (India / Singapore / US).
insert into public.tenants (id, slug, name, default_locale, default_currency_code, default_timezone)
values
  ('11111111-1111-1111-1111-111111111111', 'verify-tenant-a', 'Verify Tenant A', 'en-IN', 'INR', 'Asia/Kolkata'),
  ('22222222-2222-2222-2222-222222222222', 'verify-tenant-b', 'Verify Tenant B', 'en-US', 'USD', 'America/New_York');

-- =====================================================================================
-- Hierarchy: organisations
-- =====================================================================================

do $$
declare
  v_org_type uuid := (select org_type from test_type_ids);
begin
  insert into public.organisations (id, tenant_id, organisation_type_id, parent_organisation_id, code, name)
  values
    ('a0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', v_org_type, null, 'ORG-A1', 'Org A1'),
    ('a0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', v_org_type, 'a0000000-0000-0000-0000-000000000001', 'ORG-A2', 'Org A2'),
    ('b0000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', v_org_type, null, 'ORG-B1', 'Org B1');

  insert into test_results (name, passed, detail)
  values ('organisation_valid_hierarchy_succeeds', true, 'parent/child organisation insert succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('organisation_valid_hierarchy_succeeds', false, sqlerrm);
end $$;

do $$
begin
  update public.organisations
  set parent_organisation_id = 'a0000000-0000-0000-0000-000000000002'
  where id = 'a0000000-0000-0000-0000-000000000001';

  insert into test_results (name, passed, detail)
  values ('organisation_cycle_rejected', false, 'expected cycle rejection but update succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('organisation_cycle_rejected', sqlstate = '23514', sqlerrm);
end $$;

do $$
begin
  insert into public.organisations (tenant_id, organisation_type_id, code, name, parent_organisation_id)
  values ('11111111-1111-1111-1111-111111111111', (select org_type from test_type_ids), 'ORG-BAD-PARENT', 'Bad Parent', 'ffffffff-ffff-ffff-ffff-ffffffffffff');

  insert into test_results (name, passed, detail)
  values ('organisation_invalid_parent_rejected', false, 'expected FK violation but insert succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('organisation_invalid_parent_rejected', sqlstate = '23503', sqlerrm);
end $$;

do $$
begin
  insert into public.organisations (tenant_id, organisation_type_id, code, name)
  values ('11111111-1111-1111-1111-111111111111', (select org_type from test_type_ids), 'ORG-A1', 'Duplicate Code');

  insert into test_results (name, passed, detail)
  values ('organisation_duplicate_code_rejected', false, 'expected unique violation but insert succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('organisation_duplicate_code_rejected', sqlstate = '23505', sqlerrm);
end $$;

-- =====================================================================================
-- Hierarchy: organisation_units (cross-tenant + cycle)
-- =====================================================================================

do $$
declare
  v_unit_type uuid := (select org_unit_type from test_type_ids);
begin
  insert into public.organisation_units (id, tenant_id, organisation_id, organisation_unit_type_id, parent_organisation_unit_id, code, name)
  values
    ('a0000000-0000-0000-0001-000000000001', '11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000001', v_unit_type, null, 'UNIT-A1', 'Unit A1'),
    ('a0000000-0000-0000-0001-000000000002', '11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000001', v_unit_type, 'a0000000-0000-0000-0001-000000000001', 'UNIT-A2', 'Unit A2');

  insert into test_results (name, passed, detail)
  values ('organisation_unit_valid_hierarchy_succeeds', true, 'parent/child organisation unit insert succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('organisation_unit_valid_hierarchy_succeeds', false, sqlerrm);
end $$;

do $$
begin
  update public.organisation_units
  set parent_organisation_unit_id = 'a0000000-0000-0000-0001-000000000002'
  where id = 'a0000000-0000-0000-0001-000000000001';

  insert into test_results (name, passed, detail)
  values ('organisation_unit_cycle_rejected', false, 'expected cycle rejection but update succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('organisation_unit_cycle_rejected', sqlstate = '23514', sqlerrm);
end $$;

do $$
begin
  -- tenant_id says Tenant B, but organisation_id belongs to Tenant A: must fail the composite FK.
  insert into public.organisation_units (tenant_id, organisation_id, organisation_unit_type_id, code, name)
  values ('22222222-2222-2222-2222-222222222222', 'a0000000-0000-0000-0000-000000000001', (select org_unit_type from test_type_ids), 'UNIT-CROSS', 'Cross Tenant Unit');

  insert into test_results (name, passed, detail)
  values ('organisation_unit_cross_tenant_rejected', false, 'expected FK violation but insert succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('organisation_unit_cross_tenant_rejected', sqlstate = '23503', sqlerrm);
end $$;

-- =====================================================================================
-- Organisation relationships: same-tenant succeeds, cross-tenant fails, bad date range fails
-- =====================================================================================

do $$
declare
  v_rel_type uuid := (select rel_type from test_type_ids);
begin
  insert into public.organisation_relationships (source_organisation_id, target_organisation_id, tenant_id, relationship_type_id)
  values ('a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', v_rel_type);

  insert into test_results (name, passed, detail)
  values ('relationship_same_tenant_succeeds', true, 'same-tenant relationship insert succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('relationship_same_tenant_succeeds', false, sqlerrm);
end $$;

do $$
begin
  insert into public.organisation_relationships (source_organisation_id, target_organisation_id, tenant_id, relationship_type_id)
  values ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', (select rel_type from test_type_ids));

  insert into test_results (name, passed, detail)
  values ('relationship_cross_tenant_rejected', false, 'expected FK violation but insert succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('relationship_cross_tenant_rejected', sqlstate = '23503', sqlerrm);
end $$;

do $$
begin
  insert into public.organisation_relationships (source_organisation_id, target_organisation_id, tenant_id, relationship_type_id, effective_from, effective_until)
  values ('a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', (select rel_type from test_type_ids), '2026-06-01', '2026-01-01');

  insert into test_results (name, passed, detail)
  values ('relationship_invalid_date_range_rejected', false, 'expected check violation but insert succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('relationship_invalid_date_range_rejected', sqlstate = '23514', sqlerrm);
end $$;

-- =====================================================================================
-- Global context: India / Singapore / US sites, plus virtual-site address guard
-- =====================================================================================

do $$
declare
  v_property_type uuid := (select property_type from test_type_ids);
  v_site_type uuid := (select site_type from test_type_ids);
begin
  insert into public.properties (id, tenant_id, property_type_id, code, name, country_code)
  values ('a0000000-0000-0000-0002-000000000001', '11111111-1111-1111-1111-111111111111', v_property_type, 'PROP-A1', 'Property A1', 'IN');

  insert into public.sites (id, tenant_id, property_id, site_type_id, mode, code, name, country_code, timezone, currency_code, locale)
  values
    ('a0000000-0000-0000-0003-000000000001', '11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0002-000000000001', v_site_type, 'physical', 'SITE-A-IN', 'Site A India', 'IN', 'Asia/Kolkata', 'INR', 'en-IN'),
    ('a0000000-0000-0000-0003-000000000002', '11111111-1111-1111-1111-111111111111', null, v_site_type, 'physical', 'SITE-A-SG', 'Site A Singapore', 'SG', 'Asia/Singapore', 'SGD', 'en-SG'),
    ('a0000000-0000-0000-0003-000000000003', '11111111-1111-1111-1111-111111111111', null, v_site_type, 'virtual', 'SITE-A-US-VIRTUAL', 'Site A US Virtual', null, 'America/New_York', 'USD', 'en-US');

  insert into test_results (name, passed, detail)
  values ('global_context_multi_country_sites_succeed', true, 'India/Singapore/US(virtual) sites inserted with distinct country/currency/timezone/locale');
exception when others then
  insert into test_results (name, passed, detail)
  values ('global_context_multi_country_sites_succeed', false, sqlerrm);
end $$;

do $$
begin
  insert into public.sites (tenant_id, site_type_id, mode, code, name, country_code, address_line_1, timezone)
  values ('11111111-1111-1111-1111-111111111111', (select site_type from test_type_ids), 'virtual', 'SITE-BAD-VIRTUAL', 'Bad Virtual Site', 'US', '123 Main St', 'America/New_York');

  insert into test_results (name, passed, detail)
  values ('virtual_site_with_address_rejected', false, 'expected check violation but insert succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('virtual_site_with_address_rejected', sqlstate = '23514', sqlerrm);
end $$;

-- =====================================================================================
-- Site areas: valid nesting, cycle rejection, cross-site mismatch
-- =====================================================================================

do $$
declare
  v_area_type uuid := (select site_area_type from test_type_ids);
begin
  insert into public.site_areas (id, tenant_id, site_id, site_area_type_id, parent_site_area_id, code, name)
  values
    ('a0000000-0000-0000-0004-000000000001', '11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0003-000000000001', v_area_type, null, 'AREA-A1', 'Floor 1'),
    ('a0000000-0000-0000-0004-000000000002', '11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0003-000000000001', v_area_type, 'a0000000-0000-0000-0004-000000000001', 'AREA-A2', 'Floor 1 East Zone'),
    ('a0000000-0000-0000-0004-000000000010', '11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0003-000000000002', v_area_type, null, 'AREA-SG1', 'Singapore Floor 1');

  insert into test_results (name, passed, detail)
  values ('site_area_valid_nesting_succeeds', true, 'nested site area insert succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('site_area_valid_nesting_succeeds', false, sqlerrm);
end $$;

do $$
begin
  update public.site_areas
  set parent_site_area_id = 'a0000000-0000-0000-0004-000000000002'
  where id = 'a0000000-0000-0000-0004-000000000001';

  insert into test_results (name, passed, detail)
  values ('site_area_cycle_rejected', false, 'expected cycle rejection but update succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('site_area_cycle_rejected', sqlstate = '23514', sqlerrm);
end $$;

do $$
begin
  -- AREA-SG1 belongs to the Singapore site, not India: referencing it as a child of the India
  -- site (site_id mismatch) must fail the composite FK.
  insert into public.site_areas (tenant_id, site_id, site_area_type_id, parent_site_area_id, code, name)
  values ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0003-000000000001', (select site_area_type from test_type_ids), 'a0000000-0000-0000-0004-000000000010', 'AREA-BAD', 'Bad Cross-Site Area');

  insert into test_results (name, passed, detail)
  values ('site_area_cross_site_parent_rejected', false, 'expected FK violation but insert succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('site_area_cross_site_parent_rejected', sqlstate = '23503', sqlerrm);
end $$;

-- =====================================================================================
-- Service locations: valid insert, cross-site area mismatch
-- =====================================================================================

do $$
declare
  v_sl_type uuid := (select service_location_type from test_type_ids);
begin
  insert into public.service_locations (id, tenant_id, site_id, site_area_id, service_location_type_id, code, name, is_consumer_facing)
  values ('a0000000-0000-0000-0005-000000000001', '11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0003-000000000001', 'a0000000-0000-0000-0004-000000000001', v_sl_type, 'CAFE-A1', 'Cafeteria A1', true);

  insert into test_results (name, passed, detail)
  values ('service_location_valid_insert_succeeds', true, 'service location insert (with matching site/site area) succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('service_location_valid_insert_succeeds', false, sqlerrm);
end $$;

do $$
begin
  -- AREA-SG1 belongs to the Singapore site; referencing it from a service location declared
  -- against the India site (site_id mismatch) must fail the composite FK.
  insert into public.service_locations (tenant_id, site_id, site_area_id, service_location_type_id, code, name)
  values ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0003-000000000001', 'a0000000-0000-0000-0004-000000000010', (select service_location_type from test_type_ids), 'CAFE-BAD', 'Bad Cross-Site Cafeteria');

  insert into test_results (name, passed, detail)
  values ('service_location_cross_site_area_rejected', false, 'expected FK violation but insert succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('service_location_cross_site_area_rejected', sqlstate = '23503', sqlerrm);
end $$;

-- =====================================================================================
-- Typed-column junction tables: exactly-one-target CHECK, context-column FK correctness
-- =====================================================================================

do $$
begin
  insert into public.portfolios (id, tenant_id, code, name)
  values ('a0000000-0000-0000-0006-000000000001', '11111111-1111-1111-1111-111111111111', 'PORT-A1', 'Portfolio A1');

  insert into test_results (name, passed, detail)
  values ('portfolio_insert_succeeds', true, 'portfolio insert succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('portfolio_insert_succeeds', false, sqlerrm);
end $$;

do $$
begin
  -- Zero targets set: must fail the exactly-one-target CHECK.
  insert into public.portfolio_members (tenant_id, portfolio_id)
  values ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0006-000000000001');

  insert into test_results (name, passed, detail)
  values ('portfolio_member_zero_targets_rejected', false, 'expected check violation but insert succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('portfolio_member_zero_targets_rejected', sqlstate = '23514', sqlerrm);
end $$;

do $$
begin
  -- Two targets set (organisation + site): must fail the exactly-one-target CHECK.
  insert into public.portfolio_members (tenant_id, portfolio_id, organisation_id, site_id)
  values ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0006-000000000001', 'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0003-000000000001');

  insert into test_results (name, passed, detail)
  values ('portfolio_member_two_targets_rejected', false, 'expected check violation but insert succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('portfolio_member_two_targets_rejected', sqlstate = '23514', sqlerrm);
end $$;

do $$
begin
  -- Correct context (site_area_site_id matches the area's real site): must succeed.
  insert into public.portfolio_members (tenant_id, portfolio_id, site_area_id, site_area_site_id)
  values ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0006-000000000001', 'a0000000-0000-0000-0004-000000000001', 'a0000000-0000-0000-0003-000000000001');

  insert into test_results (name, passed, detail)
  values ('portfolio_member_correct_context_succeeds', true, 'portfolio member targeting a site area with correct context succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('portfolio_member_correct_context_succeeds', false, sqlerrm);
end $$;

do $$
begin
  -- Wrong context (site_area_site_id points at the Singapore site, but AREA-A2 belongs to the
  -- India site): must fail the composite FK, proving the context column cannot drift. Uses a
  -- different site_area_id than the "correct context" test above so this doesn't instead trip
  -- the (portfolio_id, site_area_id) active-membership uniqueness index.
  insert into public.portfolio_members (tenant_id, portfolio_id, site_area_id, site_area_site_id)
  values ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0006-000000000001', 'a0000000-0000-0000-0004-000000000002', 'a0000000-0000-0000-0003-000000000002');

  insert into test_results (name, passed, detail)
  values ('portfolio_member_wrong_context_rejected', false, 'expected FK violation but insert succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('portfolio_member_wrong_context_rejected', sqlstate = '23503', sqlerrm);
end $$;

do $$
begin
  insert into public.external_identifiers (tenant_id, site_id, source_system, external_type, external_value)
  values ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0003-000000000001', 'SAP', 'LOCATION_ID', 'SAP-LOC-001');

  insert into test_results (name, passed, detail)
  values ('external_identifier_insert_succeeds', true, 'external identifier insert succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('external_identifier_insert_succeeds', false, sqlerrm);
end $$;

do $$
begin
  insert into public.external_identifiers (tenant_id, site_id, source_system, external_type, external_value)
  values ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0003-000000000001', 'SAP', 'LOCATION_ID', 'SAP-LOC-002');

  insert into test_results (name, passed, detail)
  values ('external_identifier_duplicate_target_rejected', false, 'expected unique violation but insert succeeded');
exception when others then
  insert into test_results (name, passed, detail)
  values ('external_identifier_duplicate_target_rejected', sqlstate = '23505', sqlerrm);
end $$;

-- =====================================================================================
-- RLS: default deny for anon/authenticated on tenant-owned tables; registries stay readable.
-- Every SET ROLE is paired with RESET ROLE in the same block (success and failure paths) so
-- the session role is never left changed for later statements in this script.
-- =====================================================================================

do $$
declare
  v_count integer;
begin
  set local role anon;
  select count(*) into v_count from public.tenants;
  reset role;

  insert into test_results (name, passed, detail)
  values ('rls_anon_select_tenants_zero_rows', v_count = 0, format('anon saw %s tenant row(s), expected 0', v_count));
exception when others then
  reset role;
  insert into test_results (name, passed, detail)
  values ('rls_anon_select_tenants_zero_rows', false, sqlerrm);
end $$;

do $$
declare
  v_count integer;
begin
  set local role authenticated;
  select count(*) into v_count from public.tenants;
  reset role;

  insert into test_results (name, passed, detail)
  values ('rls_authenticated_no_membership_select_tenants_zero_rows', v_count = 0, format('authenticated saw %s tenant row(s), expected 0', v_count));
exception when others then
  reset role;
  insert into test_results (name, passed, detail)
  values ('rls_authenticated_no_membership_select_tenants_zero_rows', false, sqlerrm);
end $$;

do $$
declare
  v_count integer;
begin
  set local role anon;
  select count(*) into v_count from public.organisations;
  reset role;

  insert into test_results (name, passed, detail)
  values ('rls_anon_select_organisations_zero_rows', v_count = 0, format('anon saw %s organisation row(s), expected 0', v_count));
exception when others then
  reset role;
  insert into test_results (name, passed, detail)
  values ('rls_anon_select_organisations_zero_rows', false, sqlerrm);
end $$;

do $$
begin
  set local role anon;
  insert into public.tenants (slug, name) values ('rls-anon-should-fail', 'Should Not Insert');
  reset role;

  insert into test_results (name, passed, detail)
  values ('rls_anon_insert_tenant_rejected', false, 'expected RLS violation but insert succeeded');
exception when others then
  reset role;
  insert into test_results (name, passed, detail)
  values ('rls_anon_insert_tenant_rejected', sqlstate = '42501', sqlerrm);
end $$;

do $$
begin
  set local role authenticated;
  insert into public.organisations (tenant_id, organisation_type_id, code, name)
  values ('11111111-1111-1111-1111-111111111111', (select org_type from test_type_ids), 'ORG-AUTH-FAIL', 'Should Not Insert');
  reset role;

  insert into test_results (name, passed, detail)
  values ('rls_authenticated_insert_organisation_rejected', false, 'expected RLS violation but insert succeeded');
exception when others then
  reset role;
  insert into test_results (name, passed, detail)
  values ('rls_authenticated_insert_organisation_rejected', sqlstate = '42501', sqlerrm);
end $$;

do $$
declare
  v_count integer;
begin
  set local role anon;
  select count(*) into v_count from public.organisation_types;
  reset role;

  insert into test_results (name, passed, detail)
  values ('rls_anon_select_registry_readable', v_count > 0, format('anon saw %s organisation_types row(s), expected > 0', v_count));
exception when others then
  reset role;
  insert into test_results (name, passed, detail)
  values ('rls_anon_select_registry_readable', false, sqlerrm);
end $$;

do $$
declare
  v_count integer;
begin
  set local role authenticated;
  select count(*) into v_count from public.service_location_types;
  reset role;

  insert into test_results (name, passed, detail)
  values ('rls_authenticated_select_registry_readable', v_count > 0, format('authenticated saw %s service_location_types row(s), expected > 0', v_count));
exception when others then
  reset role;
  insert into test_results (name, passed, detail)
  values ('rls_authenticated_select_registry_readable', false, sqlerrm);
end $$;

-- =====================================================================================
-- Summary
-- =====================================================================================

select
  (select count(*) filter (where passed) from test_results) as passed_count,
  (select count(*) filter (where not passed) from test_results) as failed_count,
  (select count(*) from test_results) as total_count,
  (select coalesce(jsonb_agg(jsonb_build_object('name', name, 'detail', detail) order by seq), '[]'::jsonb)
     from test_results where not passed) as failures,
  (select jsonb_agg(name order by seq) from test_results) as all_test_names;

-- Guaranteed cleanup: every fixture row and temp table inserted above is undone here,
-- regardless of how many assertions passed or failed.
rollback;
