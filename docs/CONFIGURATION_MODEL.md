# Configuration Model

Status: **not implemented**. This document records the intended inheritance model so that when
the configuration/policy engine is built (a future module), it follows an agreed shape instead
of being designed ad hoc.

## Intended inheritance hierarchy

```
Global
  → Tenant
    → Site
      → Outlet
        → Channel
          → Persona
            → Device override
```

A setting resolves by walking from the most specific applicable scope up to Global, taking the
first value found (most specific wins). This is what lets one codebase serve every
tenant/site/outlet/channel/persona/device combination without hardcoded branches — see
Architecture Rule 6 in `CLAUDE.md`.

## Additional scopes to support later

Beyond the primary hierarchy above, the engine must eventually be able to key configuration or
policy by:

- Product
- Category
- Shift
- Meal session
- User group
- Contract
- Date range

These are expected to compose with the primary hierarchy (e.g., "this Outlet, during this
Shift, for this Persona") rather than replace it.

## What this document does not do

It does not specify a storage schema, a resolution algorithm's implementation, or a policy
evaluation engine — those are design decisions for the module that actually builds this
capability. This document only fixes the conceptual model so future design work has a stable
target.
