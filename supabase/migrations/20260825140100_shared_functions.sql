-- Module 1B: shared trigger functions
--
-- set_updated_at(): maintains updated_at on every structural table.
--
-- prevent_*_cycle(): one dedicated function per recursive hierarchy (organisations,
-- organisation_units, site_areas, service_locations), each a plain recursive CTE hardcoded to
-- its own table/columns. A single generic dynamic-SQL function (parameterized by table/column
-- name via TG_ARGV) was considered and rejected in favor of four small, plainly-readable,
-- independently testable functions — see docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md, Section F.

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.prevent_organisation_cycle()
returns trigger
language plpgsql
as $$
begin
  if new.parent_organisation_id is null then
    return new;
  end if;

  if exists (
    with recursive ancestors as (
      select id, parent_organisation_id
      from public.organisations
      where id = new.parent_organisation_id

      union all

      select o.id, o.parent_organisation_id
      from public.organisations o
      join ancestors a on o.id = a.parent_organisation_id
    )
    select 1 from ancestors where id = new.id
  ) then
    raise exception 'Cycle detected: organisation % cannot be its own ancestor', new.id
      using errcode = '23514';
  end if;

  return new;
end;
$$;

create or replace function public.prevent_organisation_unit_cycle()
returns trigger
language plpgsql
as $$
begin
  if new.parent_organisation_unit_id is null then
    return new;
  end if;

  if exists (
    with recursive ancestors as (
      select id, parent_organisation_unit_id
      from public.organisation_units
      where id = new.parent_organisation_unit_id
        and organisation_id = new.organisation_id

      union all

      select ou.id, ou.parent_organisation_unit_id
      from public.organisation_units ou
      join ancestors a on ou.id = a.parent_organisation_unit_id
      where ou.organisation_id = new.organisation_id
    )
    select 1 from ancestors where id = new.id
  ) then
    raise exception 'Cycle detected: organisation unit % cannot be its own ancestor', new.id
      using errcode = '23514';
  end if;

  return new;
end;
$$;

create or replace function public.prevent_site_area_cycle()
returns trigger
language plpgsql
as $$
begin
  if new.parent_site_area_id is null then
    return new;
  end if;

  if exists (
    with recursive ancestors as (
      select id, parent_site_area_id
      from public.site_areas
      where id = new.parent_site_area_id
        and site_id = new.site_id

      union all

      select sa.id, sa.parent_site_area_id
      from public.site_areas sa
      join ancestors a on sa.id = a.parent_site_area_id
      where sa.site_id = new.site_id
    )
    select 1 from ancestors where id = new.id
  ) then
    raise exception 'Cycle detected: site area % cannot be its own ancestor', new.id
      using errcode = '23514';
  end if;

  return new;
end;
$$;

create or replace function public.prevent_service_location_cycle()
returns trigger
language plpgsql
as $$
begin
  if new.parent_service_location_id is null then
    return new;
  end if;

  if exists (
    with recursive ancestors as (
      select id, parent_service_location_id
      from public.service_locations
      where id = new.parent_service_location_id
        and site_id = new.site_id

      union all

      select sl.id, sl.parent_service_location_id
      from public.service_locations sl
      join ancestors a on sl.id = a.parent_service_location_id
      where sl.site_id = new.site_id
    )
    select 1 from ancestors where id = new.id
  ) then
    raise exception 'Cycle detected: service location % cannot be its own ancestor', new.id
      using errcode = '23514';
  end if;

  return new;
end;
$$;
