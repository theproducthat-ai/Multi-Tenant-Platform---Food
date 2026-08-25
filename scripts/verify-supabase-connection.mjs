#!/usr/bin/env node
/**
 * Non-destructive connectivity check against the linked remote Supabase project.
 * Reads server-side env vars, makes one read-only request to Supabase Auth's
 * (GoTrue) health endpoint, and reports success/failure. Never prints the key
 * itself — only whether one was found and its type.
 *
 * Note: PostgREST's own root endpoint (`/rest/v1/`) now requires the *secret*
 * key on this project ("Secret API key required" — schema introspection is
 * gated to avoid exposing it anonymously), so it's not a usable target for a
 * check meant to run with the browser-safe publishable/anon key. The Auth
 * health endpoint is public-by-design and proves the project is reachable
 * without needing any privileged key.
 *
 * Usage: npm run supabase:verify
 * Requires SUPABASE_URL and (SUPABASE_PUBLISHABLE_KEY | SUPABASE_ANON_KEY) to
 * be set in the environment (e.g. via `.env`, not committed) — see
 * docs/DEVELOPMENT_SETUP.md.
 */

function maskedKeyLabel(key) {
  if (!key) return 'not set';
  if (key.startsWith('sb_publishable_')) return 'sb_publishable_… (new-style publishable key)';
  if (key.startsWith('sb_secret_')) return 'sb_secret_… (SECRET KEY — this script should not be given this)';
  return 'legacy JWT key (anon/service_role — type not distinguishable from the string alone)';
}

async function main() {
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_PUBLISHABLE_KEY ?? process.env.SUPABASE_ANON_KEY;

  if (!url || !key) {
    console.error('Missing SUPABASE_URL and/or SUPABASE_PUBLISHABLE_KEY (or SUPABASE_ANON_KEY).');
    console.error('Set them in a local, gitignored env file (.env) before running this script.');
    console.error('See docs/DEVELOPMENT_SETUP.md for the full list of expected variables.');
    process.exitCode = 1;
    return;
  }

  if (key.startsWith('sb_secret_')) {
    console.error('Refusing to run: a secret key was provided. Use the publishable/anon key for this check.');
    process.exitCode = 1;
    return;
  }

  console.log(`Checking connectivity to ${url} using ${maskedKeyLabel(key)}...`);

  let response;
  try {
    response = await fetch(`${url.replace(/\/$/, '')}/auth/v1/health`, {
      headers: { apikey: key, Authorization: `Bearer ${key}` },
    });
  } catch (error) {
    console.error('✗ Failed to reach the remote Supabase project.');
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
    return;
  }

  // Always drain the body before finishing — leaving it unread has been
  // observed to crash the process during fetch/socket teardown on Windows.
  await response.text();

  if (!response.ok) {
    console.error(`Connection reached the server but got HTTP ${response.status} ${response.statusText}.`);
    process.exitCode = 1;
    return;
  }

  console.log('✓ Remote Supabase project is reachable (Auth health endpoint responded 200 OK).');
  process.exitCode = 0;
}

await main();
