# Channel Registry

A channel is an experience layer that calls the Platform API — see
`docs/PLATFORM_ARCHITECTURE.md`. This registry tracks which channels exist as scaffolded apps
versus which are only planned.

## Bootstrapped (Module 0 — app scaffold exists, no product features)

| Channel  | App path         | Port | Status                                   |
|----------|------------------|------|-------------------------------------------|
| Consumer | `apps/consumer`  | 3000 | Scaffolded — placeholder page only        |
| Admin    | `apps/admin`     | 3001 | Scaffolded — placeholder page only        |
| POS      | `apps/pos`       | 3002 | Scaffolded — placeholder page only        |

None of these currently implement any product functionality. "Scaffolded" means: builds,
lints, typechecks, and serves a placeholder page confirming the environment works.

## Planned (not scaffolded, no app exists yet)

| Channel               | Notes                                                     |
|------------------------|-------------------------------------------------------------|
| SOK (Self-Ordering Kiosk) | Future device-based interface, likely touch-first UI    |
| KDS (Kitchen Display System) | Future, likely real-time-heavy via Supabase Realtime  |
| Handheld POS            | Future, likely a constrained variant of POS               |
| Native Mobile App          | Future, out of scope for the Next.js app set            |
| External API                | Future, third-party/enterprise integration surface   |
| Future device-based interfaces | Unspecified — new channels register here when planned |

Do not treat anything in the "Planned" table as implemented. Adding a new channel here when it
moves from idea to actual scaffold is part of that work, not a separate task.
