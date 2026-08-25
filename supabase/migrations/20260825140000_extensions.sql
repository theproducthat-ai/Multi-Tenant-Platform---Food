-- Module 1B: extensions
--
-- gen_random_uuid() is a PostgreSQL core builtin since v13 (this project runs v17), so pgcrypto
-- is not strictly required for UUID generation. Enabled defensively/for future crypto needs,
-- matching the approved Module 1A migration plan (docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md,
-- Section I, step 1).
create extension if not exists pgcrypto with schema extensions;
