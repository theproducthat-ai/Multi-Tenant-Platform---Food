-- Module 1C: scenario validation & global behaviour tests.
--
-- Same discipline as scripts/verify-module-1-schema.sql: one transaction, always ROLLED BACK at
-- the end regardless of outcome, so nothing persists in the target database. Eight fictional
-- tenants (one per required scenario) are built up using ONLY the tables/columns that already
-- exist from Module 1B — no schema changes, no is_hospital/is_mall/client-id style columns.
--
-- ID scheme: every fixture UUID is 'N0000000-0000-0000-000T-00000000000K' where N = scenario
-- number (1-8), T = entity-type digit (1=organisation, 2=organisation_unit, 3=property, 4=site,
-- 5=site_area, 6=service_location, 7=organisation_relationship, 8=organisation_resource_assignment,
-- 9=portfolio), K = sequence within that type. This keeps every fixture id collision-free and
-- traceable back to its scenario by inspection.
--
-- Intended invocation: `supabase db query --linked --file scripts/verify-module-1c-scenarios.sql`

begin;

create temporary table test_results (
  seq serial primary key,
  name text not null,
  passed boolean not null,
  detail text
);

-- Reusable registry-code lookup: (registry, code) -> id, across all 8 registries.
create temporary table type_lookup as
  select 'organisation_types' as registry, code, id from public.organisation_types
  union all
  select 'organisation_unit_types', code, id from public.organisation_unit_types
  union all
  select 'organisation_relationship_types', code, id from public.organisation_relationship_types
  union all
  select 'organisation_resource_role_types', code, id from public.organisation_resource_role_types
  union all
  select 'property_types', code, id from public.property_types
  union all
  select 'site_types', code, id from public.site_types
  union all
  select 'site_area_types', code, id from public.site_area_types
  union all
  select 'service_location_types', code, id from public.service_location_types;

create unique index on type_lookup (registry, code);

create or replace function pg_temp.type_id(p_registry text, p_code text)
returns uuid
language sql
stable
as $$
  select id from type_lookup where registry = p_registry and code = p_code;
$$;

-- =====================================================================================
-- Fixture tenants: one per required scenario.
-- =====================================================================================

insert into public.tenants (id, slug, name) values
  ('10000000-0000-0000-0000-000000000000', 'scenario-1-food-services', 'Demo Food Services Group'),
  ('20000000-0000-0000-0000-000000000000', 'scenario-2-global-tech', 'Global Technology Corporation'),
  ('30000000-0000-0000-0000-000000000000', 'scenario-3-conglomerate', 'Demo Conglomerate'),
  ('40000000-0000-0000-0000-000000000000', 'scenario-4-property', 'Metro Property Management'),
  ('50000000-0000-0000-0000-000000000000', 'scenario-5-mall', 'Demo Mall Operator'),
  ('60000000-0000-0000-0000-000000000000', 'scenario-6-hospital', 'Demo Hospital Group'),
  ('70000000-0000-0000-0000-000000000000', 'scenario-7-education', 'Global Education Group'),
  ('80000000-0000-0000-0000-000000000000', 'scenario-8-manufacturing', 'Industrial Manufacturing Group');

-- =====================================================================================
-- Scenario 1 — Food-Service Provider Ecosystem
-- =====================================================================================

do $$
begin
  insert into public.organisations (id, tenant_id, organisation_type_id, code, name) values
    ('10000000-0000-0000-0001-000000000001', '10000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','FOOD_SERVICE_PROVIDER'), 'PROVIDER-1', 'Demo Catering Provider'),
    ('10000000-0000-0000-0001-000000000002', '10000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','FOOD_SERVICE_PROVIDER'), 'PROVIDER-2', 'Second Catering Provider'),
    ('10000000-0000-0000-0001-000000000003', '10000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','CORPORATE_CLIENT'), 'CLIENT-A', 'Corporate Client A'),
    ('10000000-0000-0000-0001-000000000004', '10000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','CORPORATE_CLIENT'), 'CLIENT-B', 'Corporate Client B'),
    ('10000000-0000-0000-0001-000000000005', '10000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','CORPORATE_CLIENT'), 'CLIENT-C', 'Corporate Client C');

  insert into public.sites (id, tenant_id, site_type_id, code, name, country_code, timezone, currency_code, locale) values
    ('10000000-0000-0000-0004-000000000001', '10000000-0000-0000-0000-000000000000', pg_temp.type_id('site_types','CORPORATE_CAMPUS'), 'CLIENT-A-GGN', 'Client A Gurgaon', 'IN', 'Asia/Kolkata', 'INR', 'en-IN'),
    ('10000000-0000-0000-0004-000000000002', '10000000-0000-0000-0000-000000000000', pg_temp.type_id('site_types','CORPORATE_CAMPUS'), 'CLIENT-A-HYD', 'Client A Hyderabad', 'IN', 'Asia/Kolkata', 'INR', 'en-IN'),
    ('10000000-0000-0000-0004-000000000003', '10000000-0000-0000-0000-000000000000', pg_temp.type_id('site_types','CORPORATE_CAMPUS'), 'CLIENT-B-BLR', 'Client B Bangalore', 'IN', 'Asia/Kolkata', 'INR', 'en-IN');

  insert into public.service_locations (id, tenant_id, site_id, service_location_type_id, code, name) values
    ('10000000-0000-0000-0006-000000000001', '10000000-0000-0000-0000-000000000000', '10000000-0000-0000-0004-000000000001', pg_temp.type_id('service_location_types','CAFETERIA'), 'MAIN-CAFE', 'Main Cafeteria'),
    ('10000000-0000-0000-0006-000000000002', '10000000-0000-0000-0000-000000000000', '10000000-0000-0000-0004-000000000001', pg_temp.type_id('service_location_types','COFFEE_SHOP'), 'COFFEE', 'Coffee Shop'),
    ('10000000-0000-0000-0006-000000000003', '10000000-0000-0000-0000-000000000000', '10000000-0000-0000-0004-000000000001', pg_temp.type_id('service_location_types','PANTRY'), 'PANTRY', 'Pantry'),
    ('10000000-0000-0000-0006-000000000004', '10000000-0000-0000-0000-000000000000', '10000000-0000-0000-0004-000000000001', pg_temp.type_id('service_location_types','CENTRAL_KITCHEN'), 'CTRL-KITCHEN', 'Central Kitchen'),
    ('10000000-0000-0000-0006-000000000005', '10000000-0000-0000-0000-000000000000', '10000000-0000-0000-0004-000000000002', pg_temp.type_id('service_location_types','CAFETERIA'), 'MAIN-CAFE', 'Main Cafeteria'),
    ('10000000-0000-0000-0006-000000000006', '10000000-0000-0000-0000-000000000000', '10000000-0000-0000-0004-000000000003', pg_temp.type_id('service_location_types','CAFETERIA'), 'MAIN-CAFE', 'Main Cafeteria');

  insert into public.organisation_relationships (tenant_id, source_organisation_id, target_organisation_id, relationship_type_id) values
    ('10000000-0000-0000-0000-000000000000', '10000000-0000-0000-0001-000000000001', '10000000-0000-0000-0001-000000000003', pg_temp.type_id('organisation_relationship_types','SERVICE_PROVIDER')),
    ('10000000-0000-0000-0000-000000000000', '10000000-0000-0000-0001-000000000002', '10000000-0000-0000-0001-000000000004', pg_temp.type_id('organisation_relationship_types','SERVICE_PROVIDER')),
    ('10000000-0000-0000-0000-000000000000', '10000000-0000-0000-0001-000000000001', '10000000-0000-0000-0001-000000000005', pg_temp.type_id('organisation_relationship_types','SERVICE_PROVIDER'));

  insert into public.organisation_resource_assignments (tenant_id, organisation_id, role_type_id, service_location_id, service_location_site_id) values
    ('10000000-0000-0000-0000-000000000000', '10000000-0000-0000-0001-000000000001', pg_temp.type_id('organisation_resource_role_types','OPERATES'), '10000000-0000-0000-0006-000000000001', '10000000-0000-0000-0004-000000000001'),
    ('10000000-0000-0000-0000-000000000000', '10000000-0000-0000-0001-000000000001', pg_temp.type_id('organisation_resource_role_types','OPERATES'), '10000000-0000-0000-0006-000000000004', '10000000-0000-0000-0004-000000000001'),
    ('10000000-0000-0000-0000-000000000000', '10000000-0000-0000-0001-000000000001', pg_temp.type_id('organisation_resource_role_types','OPERATES'), '10000000-0000-0000-0006-000000000005', '10000000-0000-0000-0004-000000000002'),
    ('10000000-0000-0000-0000-000000000000', '10000000-0000-0000-0001-000000000002', pg_temp.type_id('organisation_resource_role_types','OPERATES'), '10000000-0000-0000-0006-000000000006', '10000000-0000-0000-0004-000000000003');

  insert into test_results (name, passed, detail) values ('scenario_1_construction_succeeds', true, 'provider/client ecosystem inserted');
exception when others then
  insert into test_results (name, passed, detail) values ('scenario_1_construction_succeeds', false, sqlerrm);
end $$;

do $$
declare
  v_provider1_sites integer;
  v_provider2_sites integer;
begin
  select count(distinct service_location_site_id) into v_provider1_sites
  from public.organisation_resource_assignments where organisation_id = '10000000-0000-0000-0001-000000000001';
  select count(distinct service_location_site_id) into v_provider2_sites
  from public.organisation_resource_assignments where organisation_id = '10000000-0000-0000-0001-000000000002';

  insert into test_results (name, passed, detail) values (
    'scenario_1_different_operators_per_client_site',
    v_provider1_sites = 2 and v_provider2_sites = 1,
    format('provider1 operates %s site(s) (expected 2: Client A Gurgaon+Hyderabad), provider2 operates %s site(s) (expected 1: Client B Bangalore)', v_provider1_sites, v_provider2_sites)
  );
end $$;

do $$
declare
  v_has_org_fk_on_sites boolean;
begin
  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'sites' and column_name = 'organisation_id'
  ) into v_has_org_fk_on_sites;

  insert into test_results (name, passed, detail) values (
    'scenario_1_organisation_and_physical_structure_independent',
    not v_has_org_fk_on_sites,
    'sites has no organisation_id column: organisational and physical hierarchies connect only through explicit relationship/assignment tables, never a direct FK'
  );
end $$;

-- =====================================================================================
-- Scenario 2 — Global Enterprise
-- =====================================================================================

do $$
begin
  insert into public.organisations (id, tenant_id, organisation_type_id, code, name) values
    ('20000000-0000-0000-0001-000000000001', '20000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','OPERATING_COMPANY'), 'GLOBALTECH', 'Global Technology Corporation'),
    ('20000000-0000-0000-0001-000000000002', '20000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','FOOD_SERVICE_PROVIDER'), 'VENDOR-A', 'Campus Eats Vendor A'),
    ('20000000-0000-0000-0001-000000000003', '20000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','FOOD_SERVICE_PROVIDER'), 'VENDOR-B', 'Campus Eats Vendor B');

  insert into public.organisation_units (id, tenant_id, organisation_id, organisation_unit_type_id, code, name) values
    ('20000000-0000-0000-0002-000000000001', '20000000-0000-0000-0000-000000000000', '20000000-0000-0000-0001-000000000001', pg_temp.type_id('organisation_unit_types','COUNTRY_OPERATION'), 'US-OPS', 'United States Operations'),
    ('20000000-0000-0000-0002-000000000002', '20000000-0000-0000-0000-000000000000', '20000000-0000-0000-0001-000000000001', pg_temp.type_id('organisation_unit_types','COUNTRY_OPERATION'), 'IN-OPS', 'India Operations'),
    ('20000000-0000-0000-0002-000000000003', '20000000-0000-0000-0000-000000000000', '20000000-0000-0000-0001-000000000001', pg_temp.type_id('organisation_unit_types','COUNTRY_OPERATION'), 'SG-OPS', 'Singapore Operations');

  insert into public.sites (id, tenant_id, site_type_id, code, name, country_code, timezone, currency_code, locale) values
    ('20000000-0000-0000-0004-000000000001', '20000000-0000-0000-0000-000000000000', pg_temp.type_id('site_types','CORPORATE_CAMPUS'), 'GGN-SOHNA', 'Gurgaon Sohna Road', 'IN', 'Asia/Kolkata', 'INR', 'en-IN'),
    ('20000000-0000-0000-0004-000000000002', '20000000-0000-0000-0000-000000000000', pg_temp.type_id('site_types','CORPORATE_CAMPUS'), 'GGN-AMBIENCE', 'Gurgaon Ambience', 'IN', 'Asia/Kolkata', 'INR', 'en-IN'),
    ('20000000-0000-0000-0004-000000000003', '20000000-0000-0000-0000-000000000000', pg_temp.type_id('site_types','CORPORATE_CAMPUS'), 'HYD', 'Hyderabad', 'IN', 'Asia/Kolkata', 'INR', 'en-IN'),
    ('20000000-0000-0000-0004-000000000004', '20000000-0000-0000-0000-000000000000', pg_temp.type_id('site_types','CORPORATE_CAMPUS'), 'CHN', 'Chennai', 'IN', 'Asia/Kolkata', 'INR', 'en-IN'),
    ('20000000-0000-0000-0004-000000000005', '20000000-0000-0000-0000-000000000000', pg_temp.type_id('site_types','CORPORATE_CAMPUS'), 'SUNNYVALE', 'Sunnyvale HQ', 'US', 'America/Los_Angeles', 'USD', 'en-US'),
    ('20000000-0000-0000-0004-000000000006', '20000000-0000-0000-0000-000000000000', pg_temp.type_id('site_types','CORPORATE_CAMPUS'), 'SG-ONE', 'Singapore One', 'SG', 'Asia/Singapore', 'SGD', 'en-SG');

  insert into public.site_areas (id, tenant_id, site_id, site_area_type_id, parent_site_area_id, code, name) values
    ('20000000-0000-0000-0005-000000000001', '20000000-0000-0000-0000-000000000000', '20000000-0000-0000-0004-000000000002', pg_temp.type_id('site_area_types','TOWER'), null, 'TOWER-A', 'Tower A'),
    ('20000000-0000-0000-0005-000000000002', '20000000-0000-0000-0000-000000000000', '20000000-0000-0000-0004-000000000002', pg_temp.type_id('site_area_types','FLOOR'), '20000000-0000-0000-0005-000000000001', 'GROUND', 'Ground Floor'),
    ('20000000-0000-0000-0005-000000000003', '20000000-0000-0000-0000-000000000000', '20000000-0000-0000-0004-000000000002', pg_temp.type_id('site_area_types','FLOOR'), '20000000-0000-0000-0005-000000000001', 'FLOOR-5', 'Floor 5'),
    ('20000000-0000-0000-0005-000000000004', '20000000-0000-0000-0000-000000000000', '20000000-0000-0000-0004-000000000002', pg_temp.type_id('site_area_types','FLOOR'), '20000000-0000-0000-0005-000000000001', 'BASEMENT', 'Basement');

  insert into public.service_locations (id, tenant_id, site_id, site_area_id, service_location_type_id, code, name) values
    ('20000000-0000-0000-0006-000000000001', '20000000-0000-0000-0000-000000000000', '20000000-0000-0000-0004-000000000002', '20000000-0000-0000-0005-000000000002', pg_temp.type_id('service_location_types','COFFEE_SHOP'), 'GF-COFFEE', 'Ground Floor Coffee Shop'),
    ('20000000-0000-0000-0006-000000000002', '20000000-0000-0000-0000-000000000000', '20000000-0000-0000-0004-000000000002', '20000000-0000-0000-0005-000000000003', pg_temp.type_id('service_location_types','CAFETERIA'), 'F5-CAFE', 'Floor 5 Cafeteria'),
    ('20000000-0000-0000-0006-000000000003', '20000000-0000-0000-0000-000000000000', '20000000-0000-0000-0004-000000000002', '20000000-0000-0000-0005-000000000003', pg_temp.type_id('service_location_types','PANTRY'), 'F5-PANTRY', 'Floor 5 Pantry'),
    ('20000000-0000-0000-0006-000000000004', '20000000-0000-0000-0000-000000000000', '20000000-0000-0000-0004-000000000002', '20000000-0000-0000-0005-000000000004', pg_temp.type_id('service_location_types','CENTRAL_KITCHEN'), 'BSMT-KITCHEN', 'Basement Central Kitchen'),
    ('20000000-0000-0000-0006-000000000005', '20000000-0000-0000-0000-000000000000', '20000000-0000-0000-0004-000000000004', null, pg_temp.type_id('service_location_types','CAFETERIA'), 'CHN-CAFE', 'Chennai Cafeteria');

  insert into public.organisation_resource_assignments (tenant_id, organisation_id, role_type_id, service_location_id, service_location_site_id) values
    ('20000000-0000-0000-0000-000000000000', '20000000-0000-0000-0001-000000000002', pg_temp.type_id('organisation_resource_role_types','OPERATES'), '20000000-0000-0000-0006-000000000002', '20000000-0000-0000-0004-000000000002'),
    ('20000000-0000-0000-0000-000000000000', '20000000-0000-0000-0001-000000000003', pg_temp.type_id('organisation_resource_role_types','OPERATES'), '20000000-0000-0000-0006-000000000005', '20000000-0000-0000-0004-000000000004');

  insert into test_results (name, passed, detail) values ('scenario_2_construction_succeeds', true, 'global enterprise (US/India/Singapore) inserted');
exception when others then
  insert into test_results (name, passed, detail) values ('scenario_2_construction_succeeds', false, sqlerrm);
end $$;

do $$
declare
  v_depth integer;
begin
  with recursive ancestry as (
    select id, parent_site_area_id, 1 as depth
    from public.site_areas where id = '20000000-0000-0000-0005-000000000004' -- Basement
    union all
    select sa.id, sa.parent_site_area_id, a.depth + 1
    from public.site_areas sa join ancestry a on sa.id = a.parent_site_area_id
  )
  select max(depth) into v_depth from ancestry;

  insert into test_results (name, passed, detail) values (
    'scenario_2_nested_site_area_depth',
    v_depth = 2,
    format('Basement -> Tower A ancestry depth = %s (expected 2)', v_depth)
  );
end $$;

do $$
declare
  v_a integer;
  v_b integer;
begin
  select count(*) into v_a from public.organisation_resource_assignments
  where organisation_id = '20000000-0000-0000-0001-000000000002' and service_location_site_id = '20000000-0000-0000-0004-000000000002';
  select count(*) into v_b from public.organisation_resource_assignments
  where organisation_id = '20000000-0000-0000-0001-000000000003' and service_location_site_id = '20000000-0000-0000-0004-000000000004';

  insert into test_results (name, passed, detail) values (
    'scenario_2_different_operator_per_site',
    v_a = 1 and v_b = 1,
    'Vendor A operates Gurgaon Ambience, Vendor B operates Chennai — distinct operators, distinct sites, no schema branching'
  );
end $$;

do $$
declare
  v_count integer;
begin
  select count(*) into v_count from public.sites
  where tenant_id = '20000000-0000-0000-0000-000000000000'
    and (
      (country_code = 'IN' and currency_code = 'INR' and timezone = 'Asia/Kolkata' and locale = 'en-IN')
      or (country_code = 'SG' and currency_code = 'SGD' and timezone = 'Asia/Singapore' and locale = 'en-SG')
      or (country_code = 'US' and currency_code = 'USD' and timezone = 'America/Los_Angeles' and locale = 'en-US')
    );

  insert into test_results (name, passed, detail) values (
    'global_context_india_singapore_us_sites',
    v_count >= 3,
    format('%s site(s) matched the required India/Singapore/US country+currency+timezone+locale combinations', v_count)
  );
end $$;

-- =====================================================================================
-- Scenario 3 — Conglomerate
-- =====================================================================================

do $$
begin
  insert into public.organisations (id, tenant_id, organisation_type_id, parent_organisation_id, code, name) values
    ('30000000-0000-0000-0001-000000000001', '30000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','GROUP'), null, 'CONGLOMERATE', 'Demo Conglomerate'),
    ('30000000-0000-0000-0001-000000000002', '30000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','OPERATING_COMPANY'), '30000000-0000-0000-0001-000000000001', 'INFRA-CO', 'Infrastructure Company'),
    ('30000000-0000-0000-0001-000000000003', '30000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','OPERATING_COMPANY'), '30000000-0000-0000-0001-000000000001', 'RETAIL-CO', 'Retail Company'),
    ('30000000-0000-0000-0001-000000000004', '30000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','OPERATING_COMPANY'), '30000000-0000-0000-0001-000000000001', 'TELECOM-CO', 'Telecom Company'),
    ('30000000-0000-0000-0001-000000000005', '30000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','OPERATING_COMPANY'), '30000000-0000-0000-0001-000000000001', 'MFG-CO', 'Manufacturing Company');

  insert into public.organisation_units (id, tenant_id, organisation_id, organisation_unit_type_id, parent_organisation_unit_id, code, name) values
    ('30000000-0000-0000-0002-000000000001', '30000000-0000-0000-0000-000000000000', '30000000-0000-0000-0001-000000000002', pg_temp.type_id('organisation_unit_types','BUSINESS_UNIT'), null, 'ENG-BU', 'Engineering Business Unit'),
    ('30000000-0000-0000-0002-000000000002', '30000000-0000-0000-0000-000000000000', '30000000-0000-0000-0001-000000000002', pg_temp.type_id('organisation_unit_types','REGION'), '30000000-0000-0000-0002-000000000001', 'NORTH', 'North Region');

  insert into public.sites (id, tenant_id, site_type_id, code, name, timezone) values
    ('30000000-0000-0000-0004-000000000001', '30000000-0000-0000-0000-000000000000', pg_temp.type_id('site_types','CORPORATE_CAMPUS'), 'INFRA-NORTH-1', 'Infrastructure North Site 1', 'Asia/Kolkata'),
    ('30000000-0000-0000-0004-000000000002', '30000000-0000-0000-0000-000000000000', pg_temp.type_id('site_types','MANUFACTURING_PLANT'), 'MFG-SITE-1', 'Manufacturing Company Site 1', 'Asia/Kolkata');

  insert into public.organisation_resource_assignments (tenant_id, organisation_id, role_type_id, site_id) values
    ('30000000-0000-0000-0000-000000000000', '30000000-0000-0000-0001-000000000002', pg_temp.type_id('organisation_resource_role_types','OPERATES'), '30000000-0000-0000-0004-000000000001'),
    ('30000000-0000-0000-0000-000000000000', '30000000-0000-0000-0001-000000000005', pg_temp.type_id('organisation_resource_role_types','OPERATES'), '30000000-0000-0000-0004-000000000002');

  insert into test_results (name, passed, detail) values ('scenario_3_construction_succeeds', true, 'Group -> Company -> Business Unit -> Region -> Site chain inserted');
exception when others then
  insert into test_results (name, passed, detail) values ('scenario_3_construction_succeeds', false, sqlerrm);
end $$;

do $$
declare
  v_depth integer;
begin
  with recursive ancestry as (
    select id, parent_organisation_id, 1 as depth
    from public.organisations where id = '30000000-0000-0000-0001-000000000002' -- Infrastructure Company
    union all
    select o.id, o.parent_organisation_id, a.depth + 1
    from public.organisations o join ancestry a on o.id = a.parent_organisation_id
  )
  select max(depth) into v_depth from ancestry;

  insert into test_results (name, passed, detail) values (
    'scenario_3_group_company_hierarchy_resolves',
    v_depth = 2,
    format('Infrastructure Company -> Demo Conglomerate ancestry depth = %s (expected 2)', v_depth)
  );
end $$;

do $$
declare
  v_has_site_fk_on_org_units boolean;
begin
  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'organisation_units'
      and column_name in ('site_id', 'site_area_id')
  ) into v_has_site_fk_on_org_units;

  insert into test_results (name, passed, detail) values (
    'scenario_3_company_hierarchy_not_confused_with_physical_hierarchy',
    not v_has_site_fk_on_org_units,
    'organisation_units has no site_id/site_area_id column: Group/Company/BU/Region structure cannot be confused with the physical Site/Area tree'
  );
end $$;

-- =====================================================================================
-- Scenario 4 — Multi-Tenant Property / Realtor
-- =====================================================================================

do $$
begin
  insert into public.organisations (id, tenant_id, organisation_type_id, code, name) values
    ('40000000-0000-0000-0001-000000000001', '40000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','PROPERTY_OWNER'), 'DEMO-REALTY', 'Demo Realty'),
    ('40000000-0000-0000-0001-000000000002', '40000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','PROPERTY_MANAGER'), 'METRO-PM', 'Metro Property Management'),
    ('40000000-0000-0000-0001-000000000003', '40000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','CORPORATE_CLIENT'), 'TENANT-A', 'Tenant Company A'),
    ('40000000-0000-0000-0001-000000000004', '40000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','CORPORATE_CLIENT'), 'TENANT-B', 'Tenant Company B'),
    ('40000000-0000-0000-0001-000000000005', '40000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','CORPORATE_CLIENT'), 'TENANT-C', 'Tenant Company C'),
    ('40000000-0000-0000-0001-000000000006', '40000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','FOOD_SERVICE_PROVIDER'), 'FOOD-OP', 'Food Service Provider Org'),
    ('40000000-0000-0000-0001-000000000007', '40000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','RETAILER'), 'COFFEE-OP', 'Retail Coffee Operator Org');

  insert into public.properties (id, tenant_id, property_type_id, code, name) values
    ('40000000-0000-0000-0003-000000000001', '40000000-0000-0000-0000-000000000000', pg_temp.type_id('property_types','OFFICE_PARK'), 'METRO-PARK', 'Metro Commercial Park');

  insert into public.sites (id, tenant_id, property_id, site_type_id, code, name, timezone) values
    ('40000000-0000-0000-0004-000000000001', '40000000-0000-0000-0000-000000000000', '40000000-0000-0000-0003-000000000001', pg_temp.type_id('site_types','CORPORATE_CAMPUS'), 'METRO-PARK-SITE', 'Metro Commercial Park Site', 'America/New_York');

  insert into public.site_areas (id, tenant_id, site_id, site_area_type_id, parent_site_area_id, code, name) values
    ('40000000-0000-0000-0005-000000000001', '40000000-0000-0000-0000-000000000000', '40000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','TOWER'), null, 'TOWER-A', 'Tower A'),
    ('40000000-0000-0000-0005-000000000002', '40000000-0000-0000-0000-000000000000', '40000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','TOWER'), null, 'TOWER-B', 'Tower B'),
    ('40000000-0000-0000-0005-000000000003', '40000000-0000-0000-0000-000000000000', '40000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','COMMON_AREA'), null, 'COMMON', 'Common Areas'),
    ('40000000-0000-0000-0005-000000000004', '40000000-0000-0000-0000-000000000000', '40000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','FLOOR'), '40000000-0000-0000-0005-000000000001', 'FLOOR-4', 'Floor 4'),
    ('40000000-0000-0000-0005-000000000005', '40000000-0000-0000-0000-000000000000', '40000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','FLOOR'), '40000000-0000-0000-0005-000000000001', 'FLOOR-8', 'Floor 8');

  insert into public.service_locations (id, tenant_id, site_id, site_area_id, service_location_type_id, code, name) values
    ('40000000-0000-0000-0006-000000000001', '40000000-0000-0000-0000-000000000000', '40000000-0000-0000-0004-000000000001', '40000000-0000-0000-0005-000000000003', pg_temp.type_id('service_location_types','FOOD_COURT'), 'SHARED-FC', 'Shared Food Court'),
    ('40000000-0000-0000-0006-000000000002', '40000000-0000-0000-0000-000000000000', '40000000-0000-0000-0004-000000000001', '40000000-0000-0000-0005-000000000003', pg_temp.type_id('service_location_types','COFFEE_SHOP'), 'SHARED-COFFEE', 'Shared Coffee Shop'),
    ('40000000-0000-0000-0006-000000000003', '40000000-0000-0000-0000-000000000000', '40000000-0000-0000-0004-000000000001', '40000000-0000-0000-0005-000000000004', pg_temp.type_id('service_location_types','CAFETERIA'), 'TENANT-A-CAFE', 'Company A Private Cafeteria');

  insert into public.organisation_resource_assignments (tenant_id, organisation_id, role_type_id, property_id) values
    ('40000000-0000-0000-0000-000000000000', '40000000-0000-0000-0001-000000000001', pg_temp.type_id('organisation_resource_role_types','OWNS'), '40000000-0000-0000-0003-000000000001'),
    ('40000000-0000-0000-0000-000000000000', '40000000-0000-0000-0001-000000000002', pg_temp.type_id('organisation_resource_role_types','MANAGES'), '40000000-0000-0000-0003-000000000001');

  insert into public.organisation_resource_assignments (tenant_id, organisation_id, role_type_id, site_area_id, site_area_site_id) values
    ('40000000-0000-0000-0000-000000000000', '40000000-0000-0000-0001-000000000003', pg_temp.type_id('organisation_resource_role_types','OCCUPIES'), '40000000-0000-0000-0005-000000000004', '40000000-0000-0000-0004-000000000001'),
    ('40000000-0000-0000-0000-000000000000', '40000000-0000-0000-0001-000000000004', pg_temp.type_id('organisation_resource_role_types','OCCUPIES'), '40000000-0000-0000-0005-000000000005', '40000000-0000-0000-0004-000000000001'),
    ('40000000-0000-0000-0000-000000000000', '40000000-0000-0000-0001-000000000005', pg_temp.type_id('organisation_resource_role_types','OCCUPIES'), '40000000-0000-0000-0005-000000000002', '40000000-0000-0000-0004-000000000001');

  insert into public.organisation_resource_assignments (tenant_id, organisation_id, role_type_id, service_location_id, service_location_site_id) values
    ('40000000-0000-0000-0000-000000000000', '40000000-0000-0000-0001-000000000006', pg_temp.type_id('organisation_resource_role_types','OPERATES'), '40000000-0000-0000-0006-000000000001', '40000000-0000-0000-0004-000000000001'),
    ('40000000-0000-0000-0000-000000000000', '40000000-0000-0000-0001-000000000007', pg_temp.type_id('organisation_resource_role_types','OPERATES'), '40000000-0000-0000-0006-000000000002', '40000000-0000-0000-0004-000000000001'),
    ('40000000-0000-0000-0000-000000000000', '40000000-0000-0000-0001-000000000006', pg_temp.type_id('organisation_resource_role_types','OPERATES'), '40000000-0000-0000-0006-000000000003', '40000000-0000-0000-0004-000000000001');

  insert into test_results (name, passed, detail) values ('scenario_4_construction_succeeds', true, 'owner/manager/occupants/operators over one property inserted');
exception when others then
  insert into test_results (name, passed, detail) values ('scenario_4_construction_succeeds', false, sqlerrm);
end $$;

do $$
declare
  v_owns integer;
  v_manages integer;
begin
  select count(*) into v_owns from public.organisation_resource_assignments
  where property_id = '40000000-0000-0000-0003-000000000001' and role_type_id = pg_temp.type_id('organisation_resource_role_types','OWNS');
  select count(*) into v_manages from public.organisation_resource_assignments
  where property_id = '40000000-0000-0000-0003-000000000001' and role_type_id = pg_temp.type_id('organisation_resource_role_types','MANAGES');

  insert into test_results (name, passed, detail) values (
    'scenario_4_ownership_and_management_coexist_independently',
    v_owns = 1 and v_manages = 1,
    'Demo Realty OWNS and Metro Property Management MANAGES the same property as two independent, coexisting rows — not a single owner column'
  );
end $$;

do $$
declare
  v_shared_area uuid;
  v_private_area uuid;
begin
  select site_area_id into v_shared_area from public.service_locations where id = '40000000-0000-0000-0006-000000000001';
  select site_area_id into v_private_area from public.service_locations where id = '40000000-0000-0000-0006-000000000003';

  insert into test_results (name, passed, detail) values (
    'scenario_4_shared_vs_private_service_location_distinguishable_structurally',
    v_shared_area is distinct from v_private_area,
    format('Shared Food Court attaches to site area %s (Common Areas), Company A Private Cafeteria attaches to %s (Floor 4) — distinguished by attachment point, not a boolean flag', v_shared_area, v_private_area)
  );
end $$;

-- =====================================================================================
-- Scenario 5 — Mall
-- =====================================================================================

do $$
begin
  insert into public.organisations (id, tenant_id, organisation_type_id, code, name) values
    ('50000000-0000-0000-0001-000000000001', '50000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','MALL_OPERATOR'), 'MALL-OP', 'Demo Mall Operator'),
    ('50000000-0000-0000-0001-000000000002', '50000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','RETAILER'), 'BRAND-A', 'Retail Brand A'),
    ('50000000-0000-0000-0001-000000000003', '50000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','RETAILER'), 'BRAND-B', 'Retail Brand B'),
    ('50000000-0000-0000-0001-000000000004', '50000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','RETAILER'), 'BRAND-C', 'Restaurant Brand C');

  insert into public.sites (id, tenant_id, site_type_id, code, name, timezone) values
    ('50000000-0000-0000-0004-000000000001', '50000000-0000-0000-0000-000000000000', pg_temp.type_id('site_types','MALL'), 'DEMO-MALL', 'Demo Mall', 'Asia/Dubai');

  insert into public.site_areas (id, tenant_id, site_id, site_area_type_id, parent_site_area_id, code, name) values
    ('50000000-0000-0000-0005-000000000001', '50000000-0000-0000-0000-000000000000', '50000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','FLOOR'), null, 'GROUND', 'Ground Floor'),
    ('50000000-0000-0000-0005-000000000002', '50000000-0000-0000-0000-000000000000', '50000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','FLOOR'), null, 'FIRST', 'First Floor'),
    ('50000000-0000-0000-0005-000000000003', '50000000-0000-0000-0000-000000000000', '50000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','FLOOR'), null, 'SECOND', 'Second Floor'),
    ('50000000-0000-0000-0005-000000000004', '50000000-0000-0000-0000-000000000000', '50000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','ZONE'), '50000000-0000-0000-0005-000000000002', 'FOOD-COURT-ZONE', 'Food Court Zone');

  insert into public.service_locations (id, tenant_id, site_id, site_area_id, service_location_type_id, code, name) values
    ('50000000-0000-0000-0006-000000000001', '50000000-0000-0000-0000-000000000000', '50000000-0000-0000-0004-000000000001', '50000000-0000-0000-0005-000000000001', pg_temp.type_id('service_location_types','RETAIL_OUTLET'), 'BRAND-A-GF', 'Brand A Ground Floor'),
    ('50000000-0000-0000-0006-000000000002', '50000000-0000-0000-0000-000000000000', '50000000-0000-0000-0004-000000000001', '50000000-0000-0000-0005-000000000004', pg_temp.type_id('service_location_types','RETAIL_OUTLET'), 'BRAND-B-FC', 'Brand B Food Court'),
    ('50000000-0000-0000-0006-000000000003', '50000000-0000-0000-0000-000000000000', '50000000-0000-0000-0004-000000000001', '50000000-0000-0000-0005-000000000003', pg_temp.type_id('service_location_types','RESTAURANT'), 'BRAND-C-2F', 'Restaurant C Second Floor');

  insert into public.organisation_resource_assignments (tenant_id, organisation_id, role_type_id, site_id) values
    ('50000000-0000-0000-0000-000000000000', '50000000-0000-0000-0001-000000000001', pg_temp.type_id('organisation_resource_role_types','MANAGES'), '50000000-0000-0000-0004-000000000001');

  insert into public.organisation_resource_assignments (tenant_id, organisation_id, role_type_id, service_location_id, service_location_site_id) values
    ('50000000-0000-0000-0000-000000000000', '50000000-0000-0000-0001-000000000002', pg_temp.type_id('organisation_resource_role_types','OPERATES'), '50000000-0000-0000-0006-000000000001', '50000000-0000-0000-0004-000000000001'),
    ('50000000-0000-0000-0000-000000000000', '50000000-0000-0000-0001-000000000003', pg_temp.type_id('organisation_resource_role_types','OPERATES'), '50000000-0000-0000-0006-000000000002', '50000000-0000-0000-0004-000000000001'),
    ('50000000-0000-0000-0000-000000000000', '50000000-0000-0000-0001-000000000004', pg_temp.type_id('organisation_resource_role_types','OPERATES'), '50000000-0000-0000-0006-000000000003', '50000000-0000-0000-0004-000000000001');

  insert into test_results (name, passed, detail) values ('scenario_5_construction_succeeds', true, 'mall operator + 3 retail/restaurant brands inserted');
exception when others then
  insert into test_results (name, passed, detail) values ('scenario_5_construction_succeeds', false, sqlerrm);
end $$;

do $$
declare
  v_has_org_fk_on_service_locations boolean;
begin
  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'service_locations' and column_name = 'organisation_id'
  ) into v_has_org_fk_on_service_locations;

  insert into test_results (name, passed, detail) values (
    'scenario_5_brand_distinct_from_physical_location',
    not v_has_org_fk_on_service_locations,
    'service_locations has no organisation_id column: a brand (organisation) and its store (service_location) are only ever connected via organisation_resource_assignments'
  );
end $$;

do $$
declare
  v_count integer;
begin
  -- A future Marketplace would group these 3 service_locations directly, regardless of floor.
  select count(*) into v_count from public.service_locations
  where id in ('50000000-0000-0000-0006-000000000001', '50000000-0000-0000-0006-000000000002', '50000000-0000-0000-0006-000000000003');

  insert into test_results (name, passed, detail) values (
    'scenario_5_marketplace_can_group_across_floors',
    v_count = 3,
    'all 3 brand locations (spread across Ground/First/Second floors) are independently addressable service_location rows a future Marketplace junction table could reference directly, with no floor-based constraint in the way'
  );
end $$;

-- =====================================================================================
-- Scenario 6 — Hospital
-- =====================================================================================

do $$
begin
  insert into public.organisations (id, tenant_id, organisation_type_id, code, name) values
    ('60000000-0000-0000-0001-000000000001', '60000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','HOSPITAL'), 'HOSP-GROUP', 'Demo Hospital Group');

  insert into public.organisation_units (id, tenant_id, organisation_id, organisation_unit_type_id, code, name) values
    ('60000000-0000-0000-0002-000000000001', '60000000-0000-0000-0000-000000000000', '60000000-0000-0000-0001-000000000001', pg_temp.type_id('organisation_unit_types','DEPARTMENT'), 'CARDIO', 'Cardiology'),
    ('60000000-0000-0000-0002-000000000002', '60000000-0000-0000-0000-000000000000', '60000000-0000-0000-0001-000000000001', pg_temp.type_id('organisation_unit_types','DEPARTMENT'), 'ONCO', 'Oncology'),
    ('60000000-0000-0000-0002-000000000003', '60000000-0000-0000-0000-000000000000', '60000000-0000-0000-0001-000000000001', pg_temp.type_id('organisation_unit_types','DEPARTMENT'), 'ADMIN', 'Administration');

  insert into public.sites (id, tenant_id, site_type_id, code, name, timezone) values
    ('60000000-0000-0000-0004-000000000001', '60000000-0000-0000-0000-000000000000', pg_temp.type_id('site_types','HOSPITAL'), 'HOSP-SITE', 'Demo Hospital Site', 'Asia/Kolkata');

  insert into public.site_areas (id, tenant_id, site_id, site_area_type_id, parent_site_area_id, code, name) values
    ('60000000-0000-0000-0005-000000000001', '60000000-0000-0000-0000-000000000000', '60000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','TOWER'), null, 'TOWER', 'Tower'),
    ('60000000-0000-0000-0005-000000000002', '60000000-0000-0000-0000-000000000000', '60000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','FLOOR'), '60000000-0000-0000-0005-000000000001', 'FLOOR-3', 'Floor 3'),
    ('60000000-0000-0000-0005-000000000003', '60000000-0000-0000-0000-000000000000', '60000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','WARD'), '60000000-0000-0000-0005-000000000002', 'WARD-3A', 'Ward 3A'),
    ('60000000-0000-0000-0005-000000000004', '60000000-0000-0000-0000-000000000000', '60000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','WING'), '60000000-0000-0000-0005-000000000003', 'WARD-3A-WEST', 'Ward 3A West Wing');

  insert into public.service_locations (id, tenant_id, site_id, site_area_id, service_location_type_id, code, name) values
    ('60000000-0000-0000-0006-000000000001', '60000000-0000-0000-0000-000000000000', '60000000-0000-0000-0004-000000000001', null, pg_temp.type_id('service_location_types','CENTRAL_KITCHEN'), 'CTRL-KITCHEN', 'Central Kitchen'),
    ('60000000-0000-0000-0006-000000000002', '60000000-0000-0000-0000-000000000000', '60000000-0000-0000-0004-000000000001', null, pg_temp.type_id('service_location_types','CAFETERIA'), 'STAFF-CAFE', 'Staff Cafeteria'),
    ('60000000-0000-0000-0006-000000000003', '60000000-0000-0000-0000-000000000000', '60000000-0000-0000-0004-000000000001', null, pg_temp.type_id('service_location_types','CAFETERIA'), 'DOCTOR-CAFE', 'Doctor Cafe'),
    ('60000000-0000-0000-0006-000000000004', '60000000-0000-0000-0000-000000000000', '60000000-0000-0000-0004-000000000001', null, pg_temp.type_id('service_location_types','CAFETERIA'), 'VISITOR-CAFE', 'Visitor Cafeteria'),
    ('60000000-0000-0000-0006-000000000005', '60000000-0000-0000-0000-000000000000', '60000000-0000-0000-0004-000000000001', '60000000-0000-0000-0005-000000000003', pg_temp.type_id('service_location_types','PANTRY'), 'WARD-3A-PANTRY', 'Ward 3A Pantry');

  insert into test_results (name, passed, detail) values ('scenario_6_construction_succeeds', true, 'hospital group, clinical departments, and ward hierarchy inserted');
exception when others then
  insert into test_results (name, passed, detail) values ('scenario_6_construction_succeeds', false, sqlerrm);
end $$;

do $$
declare
  v_has_cross_fk boolean;
begin
  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'organisation_units'
      and column_name in ('site_id', 'site_area_id')
  ) into v_has_cross_fk;

  insert into test_results (name, passed, detail) values (
    'scenario_6_clinical_departments_independent_of_ward_hierarchy',
    not v_has_cross_fk,
    'Cardiology/Oncology/Administration (organisation_units) have no possible FK path into the Tower/Floor/Ward (site_areas) tree — the two hierarchies cannot be forced together'
  );
end $$;

-- =====================================================================================
-- Scenario 7 — School / University
-- =====================================================================================

do $$
begin
  insert into public.organisations (id, tenant_id, organisation_type_id, parent_organisation_id, code, name) values
    ('70000000-0000-0000-0001-000000000001', '70000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','GROUP'), null, 'EDU-GROUP', 'Global Education Group'),
    ('70000000-0000-0000-0001-000000000002', '70000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','UNIVERSITY'), '70000000-0000-0000-0001-000000000001', 'DEMO-UNI', 'Demo University');

  insert into public.organisation_units (id, tenant_id, organisation_id, organisation_unit_type_id, code, name) values
    ('70000000-0000-0000-0002-000000000001', '70000000-0000-0000-0000-000000000000', '70000000-0000-0000-0001-000000000002', pg_temp.type_id('organisation_unit_types','DIVISION'), 'ENG-COLLEGE', 'College of Engineering'),
    ('70000000-0000-0000-0002-000000000002', '70000000-0000-0000-0000-000000000000', '70000000-0000-0000-0001-000000000002', pg_temp.type_id('organisation_unit_types','DIVISION'), 'BIZ-COLLEGE', 'College of Business');

  insert into public.sites (id, tenant_id, site_type_id, code, name, timezone) values
    ('70000000-0000-0000-0004-000000000001', '70000000-0000-0000-0000-000000000000', pg_temp.type_id('site_types','UNIVERSITY_CAMPUS'), 'MAIN-CAMPUS', 'Main Campus', 'Asia/Kolkata');

  insert into public.site_areas (id, tenant_id, site_id, site_area_type_id, code, name) values
    ('70000000-0000-0000-0005-000000000001', '70000000-0000-0000-0000-000000000000', '70000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','BLOCK'), 'ACAD-BLOCK', 'Academic Block'),
    ('70000000-0000-0000-0005-000000000002', '70000000-0000-0000-0000-000000000000', '70000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','HOSTEL'), 'HOSTEL-A', 'Hostel A'),
    ('70000000-0000-0000-0005-000000000003', '70000000-0000-0000-0000-000000000000', '70000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','HOSTEL'), 'HOSTEL-B', 'Hostel B'),
    ('70000000-0000-0000-0005-000000000004', '70000000-0000-0000-0000-000000000000', '70000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','BLOCK'), 'SPORTS', 'Sports Complex');

  insert into public.service_locations (id, tenant_id, site_id, site_area_id, service_location_type_id, code, name) values
    ('70000000-0000-0000-0006-000000000001', '70000000-0000-0000-0000-000000000000', '70000000-0000-0000-0004-000000000001', null, pg_temp.type_id('service_location_types','FOOD_COURT'), 'CTRL-FC', 'Central Food Court'),
    ('70000000-0000-0000-0006-000000000002', '70000000-0000-0000-0000-000000000000', '70000000-0000-0000-0004-000000000001', '70000000-0000-0000-0005-000000000002', pg_temp.type_id('service_location_types','MESS'), 'HOSTEL-A-MESS', 'Hostel A Mess'),
    ('70000000-0000-0000-0006-000000000003', '70000000-0000-0000-0000-000000000000', '70000000-0000-0000-0004-000000000001', '70000000-0000-0000-0005-000000000003', pg_temp.type_id('service_location_types','MESS'), 'HOSTEL-B-MESS', 'Hostel B Mess'),
    ('70000000-0000-0000-0006-000000000004', '70000000-0000-0000-0000-000000000000', '70000000-0000-0000-0004-000000000001', '70000000-0000-0000-0005-000000000001', pg_temp.type_id('service_location_types','COFFEE_SHOP'), 'COFFEE-CTR', 'Coffee Counter'),
    ('70000000-0000-0000-0006-000000000005', '70000000-0000-0000-0000-000000000000', '70000000-0000-0000-0004-000000000001', '70000000-0000-0000-0005-000000000004', pg_temp.type_id('service_location_types','SNACK_POINT'), 'SPORTS-CAFE', 'Sports Cafe');

  insert into test_results (name, passed, detail) values ('scenario_7_construction_succeeds', true, 'education group, university, colleges, campus/hostel structure inserted');
exception when others then
  insert into test_results (name, passed, detail) values ('scenario_7_construction_succeeds', false, sqlerrm);
end $$;

do $$
declare
  v_count integer;
begin
  select count(*) into v_count from public.site_areas
  where id in ('70000000-0000-0000-0005-000000000002', '70000000-0000-0000-0005-000000000003')
    and tenant_id = '70000000-0000-0000-0000-000000000000';

  insert into test_results (name, passed, detail) values (
    'scenario_7_hostels_are_independently_addressable_attachment_points',
    v_count = 2,
    'Hostel A and Hostel B are ordinary site_area rows with the full tenant-safe composite-FK identity a future hostel-membership table needs — no redesign required to attach one'
  );
end $$;

-- =====================================================================================
-- Scenario 8 — Manufacturing
-- =====================================================================================

do $$
begin
  insert into public.organisations (id, tenant_id, organisation_type_id, parent_organisation_id, code, name) values
    ('80000000-0000-0000-0001-000000000001', '80000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','GROUP'), null, 'MFG-GROUP', 'Manufacturing Group'),
    ('80000000-0000-0000-0001-000000000002', '80000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','OPERATING_COMPANY'), '80000000-0000-0000-0001-000000000001', 'MFG-CO', 'Manufacturing Company');

  insert into public.organisation_units (id, tenant_id, organisation_id, organisation_unit_type_id, code, name) values
    ('80000000-0000-0000-0002-000000000001', '80000000-0000-0000-0000-000000000000', '80000000-0000-0000-0001-000000000002', pg_temp.type_id('organisation_unit_types','REGION'), 'WEST', 'West Region');

  insert into public.sites (id, tenant_id, site_type_id, code, name, timezone) values
    ('80000000-0000-0000-0004-000000000001', '80000000-0000-0000-0000-000000000000', pg_temp.type_id('site_types','MANUFACTURING_PLANT'), 'PUNE-PLANT', 'Pune Plant', 'Asia/Kolkata');

  insert into public.site_areas (id, tenant_id, site_id, site_area_type_id, code, name) values
    ('80000000-0000-0000-0005-000000000001', '80000000-0000-0000-0000-000000000000', '80000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','PRODUCTION_BLOCK'), 'PROD-A', 'Production Block A'),
    ('80000000-0000-0000-0005-000000000002', '80000000-0000-0000-0000-000000000000', '80000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','PRODUCTION_BLOCK'), 'PROD-B', 'Production Block B'),
    ('80000000-0000-0000-0005-000000000003', '80000000-0000-0000-0000-000000000000', '80000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','OFFICE_BLOCK'), 'ADMIN-BLOCK', 'Administration Block'),
    ('80000000-0000-0000-0005-000000000004', '80000000-0000-0000-0000-000000000000', '80000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','ZONE'), 'WORKER-ZONE', 'Worker Services Zone'),
    ('80000000-0000-0000-0005-000000000005', '80000000-0000-0000-0000-000000000000', '80000000-0000-0000-0004-000000000001', pg_temp.type_id('site_area_types','BLOCK'), 'UTILITY', 'Utility Block');

  insert into public.service_locations (id, tenant_id, site_id, site_area_id, service_location_type_id, code, name) values
    ('80000000-0000-0000-0006-000000000001', '80000000-0000-0000-0000-000000000000', '80000000-0000-0000-0004-000000000001', '80000000-0000-0000-0005-000000000004', pg_temp.type_id('service_location_types','CANTEEN'), 'MAIN-CANTEEN', 'Main Canteen'),
    ('80000000-0000-0000-0006-000000000002', '80000000-0000-0000-0000-000000000000', '80000000-0000-0000-0004-000000000001', '80000000-0000-0000-0005-000000000003', pg_temp.type_id('service_location_types','RESTAURANT'), 'EXEC-DINING', 'Executive Dining'),
    ('80000000-0000-0000-0006-000000000003', '80000000-0000-0000-0000-000000000000', '80000000-0000-0000-0004-000000000001', '80000000-0000-0000-0005-000000000001', pg_temp.type_id('service_location_types','SNACK_POINT'), 'SNACK-PT', 'Snack Point'),
    ('80000000-0000-0000-0006-000000000004', '80000000-0000-0000-0000-000000000000', '80000000-0000-0000-0004-000000000001', '80000000-0000-0000-0005-000000000004', pg_temp.type_id('service_location_types','PICKUP_POINT'), 'NIGHT-SHIFT', 'Night Shift Counter'),
    ('80000000-0000-0000-0006-000000000005', '80000000-0000-0000-0000-000000000000', '80000000-0000-0000-0004-000000000001', null, pg_temp.type_id('service_location_types','CENTRAL_KITCHEN'), 'CTRL-KITCHEN', 'Central Kitchen');

  insert into public.organisation_resource_assignments (tenant_id, organisation_id, role_type_id, site_id) values
    ('80000000-0000-0000-0000-000000000000', '80000000-0000-0000-0001-000000000002', pg_temp.type_id('organisation_resource_role_types','OPERATES'), '80000000-0000-0000-0004-000000000001');

  insert into test_results (name, passed, detail) values ('scenario_8_construction_succeeds', true, 'manufacturing group/company/plant/production-block structure inserted');
exception when others then
  insert into test_results (name, passed, detail) values ('scenario_8_construction_succeeds', false, sqlerrm);
end $$;

do $$
declare
  v_canteen uuid;
  v_night_shift uuid;
begin
  select id into v_canteen from public.service_locations where id = '80000000-0000-0000-0006-000000000001';
  select id into v_night_shift from public.service_locations where id = '80000000-0000-0000-0006-000000000004';

  insert into test_results (name, passed, detail) values (
    'scenario_8_shift_specific_locations_independently_addressable',
    v_canteen is not null and v_night_shift is not null and v_canteen is distinct from v_night_shift,
    'Main Canteen and Night Shift Counter are distinct service_location rows a future shift/NFC/entitlement table can reference independently'
  );
end $$;

-- =====================================================================================
-- Global Behaviour Tests — Hierarchy (deep nesting, ancestor retrieval, cycle rejection)
-- =====================================================================================

do $$
declare
  v_depth integer;
begin
  with recursive ancestry as (
    select id, parent_site_area_id, 1 as depth
    from public.site_areas where id = '60000000-0000-0000-0005-000000000004' -- Ward 3A West Wing
    union all
    select sa.id, sa.parent_site_area_id, a.depth + 1
    from public.site_areas sa join ancestry a on sa.id = a.parent_site_area_id
  )
  select max(depth) into v_depth from ancestry;

  insert into test_results (name, passed, detail) values (
    'hierarchy_deep_nesting_ancestor_retrieval',
    v_depth = 4,
    format('Ward 3A West Wing -> Ward 3A -> Floor 3 -> Tower: recursive ancestor retrieval depth = %s (expected 4)', v_depth)
  );
end $$;

do $$
begin
  insert into public.service_locations (tenant_id, site_id, service_location_type_id, code, name)
  values ('60000000-0000-0000-0000-000000000000', '60000000-0000-0000-0004-000000000001', pg_temp.type_id('service_location_types','KIOSK'), 'SELF-PARENT-TEST', 'Self Parent Test');
  update public.service_locations
  set parent_service_location_id = id
  where code = 'SELF-PARENT-TEST' and tenant_id = '60000000-0000-0000-0000-000000000000';

  insert into test_results (name, passed, detail) values ('service_location_self_parent_rejected', false, 'expected check violation but self-parent update succeeded');
exception when others then
  insert into test_results (name, passed, detail) values ('service_location_self_parent_rejected', sqlstate = '23514', sqlerrm);
end $$;

do $$
declare
  v_a uuid := '60000000-0000-0000-0006-000000000006';
  v_b uuid := '60000000-0000-0000-0006-000000000007';
begin
  insert into public.service_locations (id, tenant_id, site_id, service_location_type_id, code, name, parent_service_location_id)
  values (v_a, '60000000-0000-0000-0000-000000000000', '60000000-0000-0000-0004-000000000001', pg_temp.type_id('service_location_types','KIOSK'), 'CYCLE-A', 'Cycle Node A', null);
  insert into public.service_locations (id, tenant_id, site_id, service_location_type_id, code, name, parent_service_location_id)
  values (v_b, '60000000-0000-0000-0000-000000000000', '60000000-0000-0000-0004-000000000001', pg_temp.type_id('service_location_types','KIOSK'), 'CYCLE-B', 'Cycle Node B', v_a);

  update public.service_locations set parent_service_location_id = v_b where id = v_a;

  insert into test_results (name, passed, detail) values ('service_location_two_node_cycle_rejected', false, 'expected cycle rejection but update succeeded');
exception when others then
  insert into test_results (name, passed, detail) values ('service_location_two_node_cycle_rejected', sqlstate = '23514', sqlerrm);
end $$;

-- =====================================================================================
-- Global Behaviour Tests — Tenant Isolation (new checks beyond Module 1B's coverage)
-- =====================================================================================

do $$
begin
  -- organisation from Scenario 1's tenant assigned OPERATES over Scenario 2's site: must fail.
  insert into public.organisation_resource_assignments (tenant_id, organisation_id, role_type_id, site_id)
  values ('10000000-0000-0000-0000-000000000000', '10000000-0000-0000-0001-000000000001', pg_temp.type_id('organisation_resource_role_types','OPERATES'), '20000000-0000-0000-0004-000000000001');

  insert into test_results (name, passed, detail) values ('cross_tenant_organisation_resource_assignment_rejected', false, 'expected FK violation but insert succeeded');
exception when others then
  insert into test_results (name, passed, detail) values ('cross_tenant_organisation_resource_assignment_rejected', sqlstate = '23503', sqlerrm);
end $$;

do $$
declare
  v_portfolio_id uuid := '10000000-0000-0000-0009-000000000001';
begin
  insert into public.portfolios (id, tenant_id, code, name)
  values (v_portfolio_id, '10000000-0000-0000-0000-000000000000', 'FOOD-PORTFOLIO', 'Food Sites Portfolio');

  -- organisation from Scenario 2's tenant as a member of Scenario 1's portfolio: must fail.
  insert into public.portfolio_members (tenant_id, portfolio_id, organisation_id)
  values ('10000000-0000-0000-0000-000000000000', v_portfolio_id, '20000000-0000-0000-0001-000000000001');

  insert into test_results (name, passed, detail) values ('cross_tenant_portfolio_membership_rejected', false, 'expected FK violation but insert succeeded');
exception when others then
  insert into test_results (name, passed, detail) values ('cross_tenant_portfolio_membership_rejected', sqlstate = '23503', sqlerrm);
end $$;

-- =====================================================================================
-- Global Behaviour Tests — Codes
-- =====================================================================================

do $$
begin
  -- Same code, two different tenants: must both succeed (uniqueness is tenant-scoped, not global).
  insert into public.sites (tenant_id, site_type_id, code, name, timezone)
  values ('50000000-0000-0000-0000-000000000000', pg_temp.type_id('site_types','CORPORATE_CAMPUS'), 'MAIN-SITE', 'Reused Code Site', 'Asia/Dubai');
  insert into public.sites (tenant_id, site_type_id, code, name, timezone)
  values ('60000000-0000-0000-0000-000000000000', pg_temp.type_id('site_types','CORPORATE_CAMPUS'), 'MAIN-SITE', 'Reused Code Site', 'Asia/Kolkata');

  insert into test_results (name, passed, detail) values ('code_reuse_across_tenants_succeeds', true, 'the same site code (MAIN-SITE) exists independently in two different tenants — uniqueness is per-tenant, not global');
exception when others then
  insert into test_results (name, passed, detail) values ('code_reuse_across_tenants_succeeds', false, sqlerrm);
end $$;

do $$
begin
  insert into public.service_locations (tenant_id, site_id, service_location_type_id, code, name)
  values ('60000000-0000-0000-0000-000000000000', '60000000-0000-0000-0004-000000000001', pg_temp.type_id('service_location_types','CAFETERIA'), 'STAFF-CAFE', 'Duplicate Staff Cafeteria');

  insert into test_results (name, passed, detail) values ('service_location_duplicate_code_within_site_rejected', false, 'expected unique violation but insert succeeded');
exception when others then
  insert into test_results (name, passed, detail) values ('service_location_duplicate_code_within_site_rejected', sqlstate = '23505', sqlerrm);
end $$;

-- =====================================================================================
-- Global Behaviour Tests — Lifecycle
-- =====================================================================================

do $$
declare
  v_status text;
begin
  update public.organisations
  set lifecycle_status = 'archived'
  where id = '10000000-0000-0000-0001-000000000005'; -- Client C, unused elsewhere

  select lifecycle_status into v_status from public.organisations where id = '10000000-0000-0000-0001-000000000005';

  insert into test_results (name, passed, detail) values (
    'lifecycle_archive_succeeds_and_row_persists',
    v_status = 'archived',
    format('organisation lifecycle_status = %s after archiving (row still present, not deleted)', v_status)
  );
exception when others then
  insert into test_results (name, passed, detail) values ('lifecycle_archive_succeeds_and_row_persists', false, sqlerrm);
end $$;

do $$
begin
  -- Infrastructure Company is referenced by organisation_units and organisation_resource_assignments;
  -- deleting it must be blocked by ON DELETE RESTRICT.
  delete from public.organisations where id = '30000000-0000-0000-0001-000000000002';

  insert into test_results (name, passed, detail) values ('referenced_organisation_hard_delete_rejected', false, 'expected FK RESTRICT violation but delete succeeded');
exception when others then
  insert into test_results (name, passed, detail) values ('referenced_organisation_hard_delete_rejected', sqlstate = '23503', sqlerrm);
end $$;

-- =====================================================================================
-- Global Behaviour Tests — Effective Dating
-- =====================================================================================

do $$
declare
  v_count integer;
begin
  -- End the existing Provider1 -> Client A relationship, then start a new one for the same
  -- pair+type: both rows must coexist (history is never overwritten).
  update public.organisation_relationships
  set effective_until = current_date, status = 'ended'
  where source_organisation_id = '10000000-0000-0000-0001-000000000001'
    and target_organisation_id = '10000000-0000-0000-0001-000000000003';

  insert into public.organisation_relationships (tenant_id, source_organisation_id, target_organisation_id, relationship_type_id, effective_from)
  values ('10000000-0000-0000-0000-000000000000', '10000000-0000-0000-0001-000000000001', '10000000-0000-0000-0001-000000000003', pg_temp.type_id('organisation_relationship_types','SERVICE_PROVIDER'), current_date + 1);

  select count(*) into v_count from public.organisation_relationships
  where source_organisation_id = '10000000-0000-0000-0001-000000000001'
    and target_organisation_id = '10000000-0000-0000-0001-000000000003';

  insert into test_results (name, passed, detail) values (
    'effective_dating_history_preserved_not_overwritten',
    v_count = 2,
    format('%s relationship row(s) exist for this pair (1 ended + 1 current) after superseding — history was not overwritten', v_count)
  );
exception when others then
  insert into test_results (name, passed, detail) values ('effective_dating_history_preserved_not_overwritten', false, sqlerrm);
end $$;

-- =====================================================================================
-- Security — re-run RLS default-deny checks against 1C fixtures
-- =====================================================================================

do $$
declare
  v_count integer;
begin
  set local role anon;
  select count(*) into v_count from public.organisations;
  reset role;

  insert into test_results (name, passed, detail) values (
    'rls_anon_select_organisations_zero_rows_1c',
    v_count = 0,
    format('anon saw %s organisation row(s) across all 8 scenario tenants, expected 0', v_count)
  );
exception when others then
  reset role;
  insert into test_results (name, passed, detail) values ('rls_anon_select_organisations_zero_rows_1c', false, sqlerrm);
end $$;

do $$
declare
  v_count integer;
begin
  set local role authenticated;
  select count(*) into v_count from public.sites;
  reset role;

  insert into test_results (name, passed, detail) values (
    'rls_authenticated_no_membership_select_sites_zero_rows_1c',
    v_count = 0,
    format('authenticated (no membership) saw %s site row(s), expected 0', v_count)
  );
exception when others then
  reset role;
  insert into test_results (name, passed, detail) values ('rls_authenticated_no_membership_select_sites_zero_rows_1c', false, sqlerrm);
end $$;

do $$
begin
  set local role anon;
  insert into public.organisations (tenant_id, organisation_type_id, code, name)
  values ('10000000-0000-0000-0000-000000000000', pg_temp.type_id('organisation_types','OTHER'), 'ANON-FAIL', 'Should Not Insert');
  reset role;

  insert into test_results (name, passed, detail) values ('rls_anon_insert_organisation_rejected_1c', false, 'expected RLS violation but insert succeeded');
exception when others then
  reset role;
  insert into test_results (name, passed, detail) values ('rls_anon_insert_organisation_rejected_1c', sqlstate = '42501', sqlerrm);
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

rollback;
