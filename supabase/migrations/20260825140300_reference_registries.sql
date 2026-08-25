-- Module 1B: reference type registries
--
-- Eight platform-controlled, tenant-immutable registries (no tenant_id — global platform data).
-- Shared shape: id, code (unique), name, description, is_active, sort_order.
-- See docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md, Section C.

create table public.organisation_types (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name text not null,
  description text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint organisation_types_code_key unique (code)
);

create table public.organisation_unit_types (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name text not null,
  description text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint organisation_unit_types_code_key unique (code)
);

create table public.organisation_relationship_types (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name text not null,
  description text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint organisation_relationship_types_code_key unique (code)
);

create table public.organisation_resource_role_types (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name text not null,
  description text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint organisation_resource_role_types_code_key unique (code)
);

create table public.property_types (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name text not null,
  description text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint property_types_code_key unique (code)
);

create table public.site_types (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name text not null,
  description text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint site_types_code_key unique (code)
);

create table public.site_area_types (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name text not null,
  description text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint site_area_types_code_key unique (code)
);

create table public.service_location_types (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name text not null,
  description text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint service_location_types_code_key unique (code)
);

-- Indexes, updated_at triggers, and RLS: identical shape for all 8 registries.
do $$
declare
  t text;
begin
  foreach t in array array[
    'organisation_types', 'organisation_unit_types', 'organisation_relationship_types',
    'organisation_resource_role_types', 'property_types', 'site_types', 'site_area_types',
    'service_location_types'
  ]
  loop
    execute format('create index %I_is_active_idx on public.%I (is_active)', t, t);
    execute format(
      'create trigger trg_%I_set_updated_at before update on public.%I for each row execute function public.set_updated_at()',
      t, t
    );
    execute format('alter table public.%I enable row level security', t);
    -- Non-sensitive platform metadata: readable by anon/authenticated (needed to render pickers
    -- even before Module 2 membership exists). No insert/update/delete policy for those roles —
    -- write-locked to service_role.
    execute format(
      'create policy %I_select_all on public.%I for select using (true)',
      t, t
    );
  end loop;
end;
$$;

-- Seed data: platform reference values only, idempotent. See
-- docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md, Section C for the rationale behind each list.

insert into public.organisation_types (code, name, sort_order) values
  ('GROUP', 'Group', 10),
  ('OPERATING_COMPANY', 'Operating Company', 20),
  ('SUBSIDIARY', 'Subsidiary', 30),
  ('CORPORATE_CLIENT', 'Corporate Client', 40),
  ('FOOD_SERVICE_PROVIDER', 'Food Service Provider', 50),
  ('PROPERTY_OWNER', 'Property Owner', 60),
  ('PROPERTY_MANAGER', 'Property Manager', 70),
  ('RETAILER', 'Retailer', 80),
  ('FRANCHISE_OPERATOR', 'Franchise Operator', 90),
  ('HOSPITAL', 'Hospital', 100),
  ('UNIVERSITY', 'University', 110),
  ('SCHOOL', 'School', 120),
  ('MALL_OPERATOR', 'Mall Operator', 130),
  ('GOVERNMENT_ENTITY', 'Government Entity', 140),
  ('OTHER', 'Other', 150)
on conflict (code) do nothing;

insert into public.organisation_unit_types (code, name, sort_order) values
  ('BUSINESS_UNIT', 'Business Unit', 10),
  ('DIVISION', 'Division', 20),
  ('REGION', 'Region', 30),
  ('COUNTRY_OPERATION', 'Country Operation', 40),
  ('DEPARTMENT', 'Department', 50),
  ('BRAND_DIVISION', 'Brand Division', 60),
  ('CLIENT_ACCOUNT', 'Client Account', 70),
  ('OPERATING_DIVISION', 'Operating Division', 80)
on conflict (code) do nothing;

insert into public.organisation_relationship_types (code, name, sort_order) values
  ('CLIENT', 'Client', 10),
  ('SERVICE_PROVIDER', 'Service Provider', 20),
  ('PROPERTY_OWNER', 'Property Owner', 30),
  ('PROPERTY_MANAGER', 'Property Manager', 40),
  ('OPERATOR', 'Operator', 50),
  ('OCCUPANT', 'Occupant', 60),
  ('RETAILER', 'Retailer', 70),
  ('VENDOR', 'Vendor', 80),
  ('LANDLORD', 'Landlord', 90),
  ('FACILITY_OPERATOR', 'Facility Operator', 100),
  ('KITCHEN_OPERATOR', 'Kitchen Operator', 110),
  ('LOGISTICS_PROVIDER', 'Logistics Provider', 120)
on conflict (code) do nothing;

insert into public.organisation_resource_role_types (code, name, sort_order) values
  ('OWNS', 'Owns', 10),
  ('MANAGES', 'Manages', 20),
  ('OCCUPIES', 'Occupies', 30),
  ('LEASES', 'Leases', 40),
  ('OPERATES', 'Operates', 50),
  ('SERVES', 'Serves', 60),
  ('MAINTAINS', 'Maintains', 70),
  ('SUPPLIES', 'Supplies', 80)
on conflict (code) do nothing;

insert into public.property_types (code, name, sort_order) values
  ('OFFICE_PARK', 'Office Park', 10),
  ('COMMERCIAL_BUILDING', 'Commercial Building', 20),
  ('MALL', 'Mall', 30),
  ('CAMPUS_ESTATE', 'Campus Estate', 40),
  ('AIRPORT_ESTATE', 'Airport Estate', 50),
  ('MIXED_USE', 'Mixed Use', 60)
on conflict (code) do nothing;

insert into public.site_types (code, name, sort_order) values
  ('CORPORATE_CAMPUS', 'Corporate Campus', 10),
  ('MANUFACTURING_PLANT', 'Manufacturing Plant', 20),
  ('HOSPITAL', 'Hospital', 30),
  ('UNIVERSITY_CAMPUS', 'University Campus', 40),
  ('SCHOOL_CAMPUS', 'School Campus', 50),
  ('MALL', 'Mall', 60),
  ('PORT_TERMINAL', 'Port Terminal', 70),
  ('WAREHOUSE', 'Warehouse', 80),
  ('AIRPORT_TERMINAL', 'Airport Terminal', 90),
  ('CENTRAL_PRODUCTION_FACILITY', 'Central Production Facility', 100),
  ('VIRTUAL_SITE', 'Virtual Site', 110)
on conflict (code) do nothing;

insert into public.site_area_types (code, name, sort_order) values
  ('BUILDING', 'Building', 10),
  ('TOWER', 'Tower', 20),
  ('BLOCK', 'Block', 30),
  ('FLOOR', 'Floor', 40),
  ('WING', 'Wing', 50),
  ('ZONE', 'Zone', 60),
  ('WARD', 'Ward', 70),
  ('HOSTEL', 'Hostel', 80),
  ('TERMINAL', 'Terminal', 90),
  ('PRODUCTION_BLOCK', 'Production Block', 100),
  ('OFFICE_BLOCK', 'Office Block', 110),
  ('COMMON_AREA', 'Common Area', 120)
on conflict (code) do nothing;

insert into public.service_location_types (code, name, sort_order) values
  ('CAFETERIA', 'Cafeteria', 10),
  ('CANTEEN', 'Canteen', 20),
  ('MESS', 'Mess', 30),
  ('FOOD_COURT', 'Food Court', 40),
  ('RESTAURANT', 'Restaurant', 50),
  ('RETAIL_OUTLET', 'Retail Outlet', 60),
  ('COFFEE_SHOP', 'Coffee Shop', 70),
  ('PANTRY', 'Pantry', 80),
  ('KITCHEN', 'Kitchen', 90),
  ('CENTRAL_KITCHEN', 'Central Kitchen', 100),
  ('SATELLITE_KITCHEN', 'Satellite Kitchen', 110),
  ('PICKUP_POINT', 'Pickup Point', 120),
  ('KIOSK', 'Kiosk', 130),
  ('VENDING_ZONE', 'Vending Zone', 140),
  ('CONCESSION', 'Concession', 150),
  ('SNACK_POINT', 'Snack Point', 160)
on conflict (code) do nothing;
