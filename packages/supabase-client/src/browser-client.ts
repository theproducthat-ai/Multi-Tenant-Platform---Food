import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '@platform/database-types';

export interface BrowserSupabaseConfig {
  url: string;
  /** The browser-safe publishable key (`sb_publishable_...`) or legacy anon key. Never a secret/service-role key. */
  publishableKey: string;
}

/**
 * Client for use in browser/client-component code (Consumer, Admin, POS UIs).
 * Only ever holds RLS-respecting, browser-safe credentials.
 */
export function createBrowserSupabaseClient({
  url,
  publishableKey,
}: BrowserSupabaseConfig): SupabaseClient<Database> {
  if (publishableKey.startsWith('sb_secret_')) {
    throw new Error(
      'createBrowserSupabaseClient received a secret key. The secret/service-role key must never be used in browser code.',
    );
  }

  return createClient<Database>(url, publishableKey);
}
