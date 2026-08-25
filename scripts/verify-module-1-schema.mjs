#!/usr/bin/env node
/**
 * Guarded wrapper for scripts/verify-module-1-schema.sql — the Module 1 remote database
 * verification suite (integrity, RLS, global-context assertions).
 *
 * Refuses to run unless SUPABASE_ENV is explicitly 'development' or 'staging' (never
 * 'production', never unset) — same convention as @platform/config's getSupabaseEnv(), kept
 * as a plain inline check here (not imported) so this root script stays dependency-free, matching
 * scripts/verify-supabase-connection.mjs.
 *
 * Delegates to the Supabase CLI (`supabase db query --linked`), which uses the CLI's own
 * authenticated session against whichever project is linked — this script never touches, reads,
 * or prints SUPABASE_URL/SUPABASE_SECRET_KEY/SUPABASE_PUBLISHABLE_KEY. The SQL file itself wraps
 * every assertion in one transaction that is always ROLLED BACK, so no fixture data is ever left
 * behind in the target database regardless of pass/fail outcome.
 *
 * Usage: npm run verify:module-1 (requires SUPABASE_ENV=development or SUPABASE_ENV=staging)
 */

import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const ALLOWED_ENVS = new Set(['development', 'staging']);
const SQL_FILE = path.join(path.dirname(fileURLToPath(import.meta.url)), 'verify-module-1-schema.sql');

function main() {
  const supabaseEnv = process.env.SUPABASE_ENV;

  if (!supabaseEnv) {
    console.error('SUPABASE_ENV is not set. Refusing to run against an unverified environment.');
    console.error("Set SUPABASE_ENV=development (or 'staging') before running this script — see docs/DEVELOPMENT_SETUP.md.");
    process.exitCode = 1;
    return;
  }

  if (!ALLOWED_ENVS.has(supabaseEnv)) {
    console.error(`Refusing to run: SUPABASE_ENV=${supabaseEnv} is not an allowed target for this script.`);
    console.error(`Allowed values: ${[...ALLOWED_ENVS].join(', ')}. This script must never run against production.`);
    process.exitCode = 1;
    return;
  }

  console.log(`SUPABASE_ENV=${supabaseEnv} — proceeding against the linked project.`);
  console.log('Running scripts/verify-module-1-schema.sql via the Supabase CLI (self-rolling-back transaction)...');

  // Built as a single pre-quoted command string (rather than an args array) because
  // spawnSync's shell:true mode concatenates array args without escaping them — the file path
  // contains spaces, so it must be quoted here, not left to shell re-splitting.
  const command = `npx supabase db query --linked --file "${SQL_FILE}" --output-format json`;
  const result = spawnSync(command, { encoding: 'utf8', shell: true });

  if (result.error) {
    console.error('Failed to invoke the Supabase CLI.');
    console.error(result.error.message);
    process.exitCode = 1;
    return;
  }

  if (result.status !== 0) {
    console.error('Verification query failed to execute.');
    console.error(result.stderr || result.stdout);
    process.exitCode = 1;
    return;
  }

  let parsed;
  try {
    // The CLI prints a status line before the JSON payload; extract just the JSON object.
    const jsonStart = result.stdout.indexOf('{');
    parsed = JSON.parse(result.stdout.slice(jsonStart));
  } catch (error) {
    console.error('Could not parse verification output as JSON.');
    console.error(result.stdout);
    process.exitCode = 1;
    return;
  }

  const summary = parsed.rows?.[0];
  if (!summary) {
    console.error('Verification query returned no summary row.');
    console.error(JSON.stringify(parsed, null, 2));
    process.exitCode = 1;
    return;
  }

  console.log(`\nResults: ${summary.passed_count}/${summary.total_count} passed.`);

  if (summary.failed_count > 0) {
    console.error(`\n${summary.failed_count} assertion(s) FAILED:`);
    for (const failure of summary.failures ?? []) {
      console.error(`  - ${failure.name}: ${failure.detail}`);
    }
    process.exitCode = 1;
    return;
  }

  console.log('✓ All Module 1 verification assertions passed.');
  process.exitCode = 0;
}

main();
