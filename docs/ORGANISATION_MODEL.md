# Organisation & Operating Structure Model

Status: **implemented and validated** (Module 1B implementation, Module 1C scenario validation).
This is the reference for the schema now live in the DEV/STAGING Supabase project. For the full
design rationale, alternatives considered, and the decisions made along the way, see
`docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md` — this document is the shorter "what it is and how to
use it" companion, not a replacement.

Module 1C proved, with real fixture data against the live DEV/STAGING schema (35/35 assertions
passing, `scripts/verify-module-1c-scenarios.sql`), that all eight scenarios below — food-service
provider, global enterprise, conglomerate, multi-tenant property, mall, hospital, education, and
manufacturing — are representable **without any schema change and without a single
industry-specific column** (no `is_hospital`, no `sodexo_client_id`, nothing of the kind).

No users, memberships, roles, configuration, or API endpoints exist yet — this is structural data
only, reachable today solely via the Supabase secret key (server-side). See
`docs/SECURITY_MODEL.md`.

## The concepts, in one pass

| Concept | Table(s) | What it answers |
|---|---|---|
| Tenant | `tenants` | Which SaaS security/data-isolation realm owns this data? (Not the same as "a company.") |
| Organisation | `organisations` | Which real-world business/legal entity or institution is involved? Recursive (`parent_organisation_id`) for Group → Company → Subsidiary shapes. |
| Organisation Unit | `organisation_units` | Where does this sit inside one organisation's internal structure (division, region, department, ...)? Recursive, scoped to one organisation. |
| Organisation Relationship | `organisation_relationships` | How are two independent organisations related (CLIENT, LANDLORD, VENDOR, ...), and since/until when? |
| Portfolio | `portfolios` / `portfolio_members` | An ad hoc management grouping of any mix of resources, independent of hierarchy or geography. |
| Property | `properties` | The estate/building layer, when ownership/property-management genuinely matters. Optional. |
| Site | `sites` | The operational location itself — physical, virtual, or hybrid. |
| Site Area | `site_areas` | Recursive physical/operational subdivision of a site (building → floor → zone). |
| Service Location | `service_locations` | Where a service is actually produced, delivered, or consumed (cafeteria, kitchen, kiosk, ...). |
| Organisation Resource Assignment | `organisation_resource_assignments` | Which organisation OWNS/MANAGES/OCCUPIES/OPERATES/... which property, site, site area, or service location, and since/until when? |
| External Identifier | `external_identifiers` | The generic hook for a resource's ID in an external system (SAP, Workday, an access-control platform, ...), without adding a column per integration. |

Eight platform-controlled reference registries back the `_type`/`_role`/`_relationship_type`
columns above (`organisation_types`, `organisation_unit_types`, `organisation_relationship_types`,
`organisation_resource_role_types`, `property_types`, `site_types`, `site_area_types`,
`service_location_types`) — global, tenant-immutable rows, not enums, so new categories are an
`INSERT`, not a migration.

## Two hierarchies, never merged

**Organisational hierarchy** (who): `organisations` → `organisation_units`. Answers "who runs
this" and "who reports to whom commercially."

**Physical/operational hierarchy** (where): `sites` → `site_areas` → `service_locations`.
Answers "where does this actually happen."

They connect only through explicit, typed links — `organisation_resource_assignments` (an
organisation plays a role over a property/site/site area/service location) and
`organisation_relationships` (two organisations relate to each other, e.g. CLIENT ↔
SERVICE_PROVIDER over a shared site). Neither hierarchy is ever forced to mirror the other, and a
future consumer-facing "Marketplace" or "Delivery Destination" attaches to the physical side
without ever touching the organisational side — see the Deferred section below.

## Worked examples across industries

**Food service provider running multiple clients' sites** (Scenario A): one `organisation`
(the provider) has an `organisation_relationship` (`SERVICE_PROVIDER`) with each client
`organisation`, and separately an `organisation_resource_assignment` (`OPERATES`) over each
client's `service_locations`. Different clients can use different providers on different sites
without any schema branching.

**Global technology company** (Scenario B): `organisations` chain Group → (via
`organisation_units`, type `COUNTRY_OPERATION`/`REGION`) US/India/Singapore → Gurgaon/Hyderabad.
Physically: `sites` (one per campus) → `site_areas` (buildings, floors) → `service_locations`
(cafeteria, coffee shop, pantry, central kitchen). The org chart and the campus map are two
independent trees that happen to describe the same company.

**Conglomerate** (Scenario C): `organisations` chain Demo Conglomerate (`GROUP`) → Infrastructure
Company / Retail Company / Telecom Company / Manufacturing Company (`OPERATING_COMPANY`,
`parent_organisation_id` = the group). Each company has its own `organisation_units` (e.g.
Infrastructure Company → Engineering Business Unit → North Region), and separately its own
`sites` reachable only via `organisation_resource_assignments`. `organisation_units` has no
`site_id`/`site_area_id` column at all — there is no way, even by mistake, for the Group/Company/
Business-Unit/Region chain to become entangled with the physical Site/Area tree.

**Multi-tenant building / property manager** (Scenario D): a `property` (the building) has
`organisation_resource_assignments` — the owner `OWNS` it, a manager `MANAGES` it, occupant
companies `OCCUPY` specific `sites`/`site_areas` inside it, and a food operator `OPERATES` a
shared food court `service_location` that multiple occupants can use. No polymorphic hacks: every
one of those is a typed row with a real foreign key.

**Mall** (Scenario E): one `site` (Demo Mall, `site_type` `MALL`) with `site_areas` for each floor
and a `Food Court Zone` nested under one of them. Retail/restaurant brands are `organisations`
(`RETAILER`); their physical stores are `service_locations` linked only through
`organisation_resource_assignments` (`OPERATES`) — `service_locations` has no `organisation_id`
column, so a brand and its store are always two separate, independently addressable rows. A
future Marketplace can group Brand A's Ground Floor store with Brand C's Second Floor restaurant
into one consumer-facing collection by referencing their `service_location` ids directly, with no
floor/zone constraint standing in the way.

**Hospital group** (Scenario F): `organisations` (hospital group → hospital) with `sites` (the
hospital campus) → `site_areas` (towers, floors, wards) → `service_locations` (central kitchen,
visitor/doctor/staff cafeterias, ward pantries). Future patient/delivery-destination/diet-eligibility
work attaches at the `site`/`site_area` level without touching this layer.

**School / university** (Scenario G): Education Group (`GROUP`) → Demo University (`UNIVERSITY`,
child organisation) → Colleges (`organisation_units`, type `DIVISION`). Physically: one `site`
(Main Campus) → `site_areas` (Academic Block, Hostel A, Hostel B, Sports Complex) →
`service_locations` (central food court, hostel messes, coffee counter, sports café). Hostel A/B
are ordinary `site_area` rows with the same tenant-safe composite-FK identity as any other — a
future hostel-membership or meal-plan table attaches to them exactly the way it would attach to a
hospital ward or an office floor, no special-casing required.

**Manufacturing plant** (Scenario H): `organisation` (the manufacturer) → `site` (the plant) →
`site_areas` (production blocks, admin block) → `service_locations` (canteens, shift meal
points). Future NFC/meal-entitlement work attaches to `service_locations` without redesign.

## How the model stays safe

- **Every tenant-owned table carries its own `tenant_id`.** No table's tenant is ever inferred by
  walking a join at query time.
- **Cross-tenant references are structurally impossible, not just application-checked.** Every
  parent/child link uses a *composite* foreign key — e.g. `site_areas` has
  `FOREIGN KEY (tenant_id, site_id) REFERENCES sites (tenant_id, id)` — so a row can never
  reference a parent belonging to a different tenant. The same mechanism makes
  `organisation_units` same-organisation-safe and `site_areas`/`service_locations`
  same-site-safe, for free, with no application code involved.
- **Hierarchy cycles are impossible.** `organisations`, `organisation_units`, `site_areas`, and
  `service_locations` each have a trigger that walks the proposed parent's ancestry and rejects
  the write if it would ever reach back to the row itself.
- **A resource can be "OWNS by A, MANAGED by B, OPERATED by C" simultaneously** —
  `organisation_resource_assignments` is a proper table of typed rows, not a single "owner"
  column, so ownership/management/operation are independent facts that can coexist and change
  over time (`effective_from`/`effective_until`) without overwriting history.
- **Nothing is ever hard-deleted.** Every structural table uses `lifecycle_status` (`draft` →
  `active` → `inactive`/`suspended` → `archived`); every foreign key from a future business table
  (orders, devices, reports, ...) into this layer will use `ON DELETE RESTRICT`.
- **RLS is on for every tenant-owned table, with zero policies for `anon`/`authenticated`** — this
  is a deliberate default-deny posture, not an oversight: there is no membership model yet
  (that's Module 2), so nobody outside server-side (secret-key) access can read or write anything
  here. The 8 reference registries are the one exception — they're non-sensitive platform
  metadata, readable by anyone, writable by nobody but the platform itself.

## Global by default

Every site carries its own `timezone` (required, even for virtual sites), and optionally its own
`currency_code`/`locale`/address — a single tenant can run sites in India, Singapore, and the US
simultaneously with no schema branching. `tenants.default_locale`/`default_currency_code`/
`default_timezone` are fallback defaults only, not operating configuration. Country/currency codes
are format-checked (ISO 3166-1 alpha-2 / ISO 4217 shape) but not validated against a canonical
list — see the shared `@platform/schemas` validators (`countryCodeSchema`, `currencyCodeSchema`,
`timezoneSchema`, `localeSchema`, `lifecycleStatusSchema`, `siteModeSchema`,
`structuralCodeSchema`).

## Query patterns for future platform services

No server-side domain/query helpers were built in Module 1C — there is no NestJS domain module,
no auth layer, and no caller for them yet (`apps/api` is still a bare health-check scaffold), so
writing service code now would mean designing an abstraction with no real consumer and no
authorization context to enforce, which risks being redesigned wholesale once Module 2 exists.
Instead, here are the query *shapes* future services will use — plain SQL over the tables above,
each already covered by an index (see `docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md` Section
"Performance and Index Strategy" and the Module 1C performance review):

- **Descendants of an organisation/site area/service location**: `WITH RECURSIVE` walking
  *down* from a root via `parent_x_id = ancestor.id`, seeded by the root row. Supported by the
  plain btree index on each `parent_x_id` column.
- **Ancestors of a resource** (breadcrumb): `WITH RECURSIVE` walking *up* via
  `id = child.parent_x_id`, seeded by the leaf row — the same shape the cycle-prevention triggers
  themselves already use. Supported by the primary key (every `parent_x_id` join lands on a PK
  lookup).
- **Site areas / service locations under a site**: `WHERE site_id = :site_id`, supported by the
  `site_id` index on both tables.
- **Organisations operating/managing/occupying a resource**: `WHERE service_location_id = :id`
  (or `site_id`/`site_area_id`/`property_id`) `AND role_type_id = :role`, on
  `organisation_resource_assignments` — supported by the per-target partial indexes; add
  `AND effective_until IS NULL` for "currently," supported by the per-target "current" partial
  indexes.
- **Resources an organisation manages**: `WHERE organisation_id = :id`, supported by that index.
- **Portfolio members**: `WHERE portfolio_id = :id`, supported by that index.

## What's deliberately not here yet

These have a documented attachment point in `docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md` and require
no redesign of this layer when built:

- **Users, memberships, roles, permissions** — Module 2.
- **Configuration/policy engine** — Module 3, targets scopes from this layer (see the Scope Model
  section of the proposal).
- **Marketplace** (consumer-facing grouping of service locations, e.g. "Coffee" / "Lunch") — not
  `site_areas`, attaches directly to `service_locations`.
- **Delivery Destination** (patient bed, desk, hostel room, ...) — attaches to `site`/`site_area`,
  same shape as `service_locations`.
- **Service network relationships** (e.g. a central kitchen `SUPPLIES` a ward pantry) — mirrors
  `organisation_relationships` exactly when built.
- **Business calendar** — `sites.timezone` being mandatory today is the groundwork; the calendar
  itself is a later module.
- **Tags, templates/cloning, setup checklists** — pure application/UI or later-schema concerns,
  no blocker in this layer.

Module 1C explicitly re-confirmed a clean, additive attachment point for every one of these —
**none would require breaking or redesigning anything built in Module 1**:

| Future capability | Attaches via |
|---|---|
| Users, profiles | New table, 1:1 with `auth.users` — no FK into Module 1 at all until membership |
| Membership, persona, roles, scoped access | New membership table: `auth.uid()` → profile → typed-column link to tenant/organisation/site/service_location (the Option B pattern, Section D) |
| Devices, operational sessions | New tables scoped to tenant + site/service_location, same typed-column or plain-FK pattern |
| Configuration, policy | The Scope Model pattern itself (Section D) — this is what it was designed for |
| Marketplace | New junction table referencing `service_location` ids directly (proven representable in Scenario E) |
| Delivery destinations | New table referencing `site_id` + optional `site_area_id`, same shape as `service_locations` |
| Business calendars | `sites.timezone NOT NULL` already in place; calendar itself is a new table keyed by site/service_location |
| Site templates, cloning, setup checklist | Pure application-layer operations over the existing recursive, tenant-scoped-code schema — no new tables required to remain possible |
| Tags / classifications | New generic tag + typed-column tag-assignment table, deferred only because no consumer needs it yet |
| External integrations | **Already implemented** — `external_identifiers` |
| NFC policy | Scope Model pattern, scope = Service Location (the brief's own original example) |
| Facial recognition | Attaches at a future device/kiosk row tied to a Service Location; enrollment data belongs to a future Profile, not this layer |
| Payments / wallet | References `organisation_id` (merchant of record), `tenant_id`, `service_location_id` — all already first-class, addressable columns |
| Kitchen networks (service-to-service supply) | New `service_location_relationships` table mirroring `organisation_relationships` exactly (documented above) |

No architectural gap was found that would force a Module 1 schema change to support any of these.

## Performance observations (Module 1C review)

No missing index was found, and none was added speculatively. Reasoning through the scenarios
above against the existing index set (`docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md`, "Performance and
Index Strategy"):

- Hierarchy traversal (ancestors/descendants) is a recursive walk through single-row primary-key
  or parent-column-indexed lookups at each step — efficient for the depths every scenario actually
  produced (2-4 levels). The one already-identified future risk — very deep or very wide trees
  making repeated single-level traversal expensive — was already flagged as a deferred
  optimization (materialized path/`ltree`) in Module 1A, not something Module 1C's scenarios gave
  any evidence of needing yet.
- "Many sites/site areas/service locations per tenant" is served by the existing `tenant_id` and
  `site_id` indexes on every physical table, plus `(tenant_id, lifecycle_status)` on `sites` for
  "active sites" filtering.
- "Organisations operating a resource" / "resources an organisation manages" queries are served by
  the per-target partial indexes and the `organisation_id` index on
  `organisation_resource_assignments` respectively; no N+1 risk in the query *shapes* themselves —
  that risk would come from an application layer that doesn't exist yet.

## Admin navigation over this model

The organisational view and the physical view are genuinely different traversals of the same
data — never force them into one tree:

- **Conglomerate admin:** `organisations` (parent chain) → `sites` reachable via
  `organisation_resource_assignments` or `organisation_relationships`.
- **Property manager:** `portfolios` → `properties` → occupant `organisations` /
  `sites` / `service_locations`.
- **Food provider:** `organisation_relationships` (CLIENT) → client's `sites` → provider's
  `service_locations` (via `OPERATES`).
- **Site manager:** one `site` → its `site_areas` tree → its `service_locations`.
