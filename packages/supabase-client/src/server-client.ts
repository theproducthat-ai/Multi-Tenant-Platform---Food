import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '@platform/database-types';

export interface ServerSupabaseConfig {
  url: string;
  /**
   * Server-side key: the publishable/anon key for RLS-respecting calls, or the
   * secret/service-role key for privileged operations that must bypass RLS.
   * Whichever is passed, this client must only ever be constructed in a
   * trusted server context (apps/api) — never shipped to a browser bundle.
   */
  key: string;
}

/**
 * Client for use in trusted server-side code only (apps/api). May be given
 * either the publishable key or the secret/service-role key depending on the
 * operation's privilege level — the caller decides, this factory does not.
 */
export function createServerSupabaseClient({ url, key }: ServerSupabaseConfig): SupabaseClient<Database> {
  if ('window' in globalThis) {
    throw new Error('createServerSupabaseClient must not be called in a browser context.');
  }

  return createClient<Database>(url, key, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}
