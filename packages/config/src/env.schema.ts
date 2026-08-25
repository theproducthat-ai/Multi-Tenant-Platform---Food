import { z } from 'zod';

/**
 * Base env schema for Module 0 verification only.
 * Domain-specific env vars (Supabase, API URLs, etc.) will extend this
 * as each app/module is built.
 */
export const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
});

export type Env = z.infer<typeof envSchema>;

export function loadEnv(source: Record<string, string | undefined> = process.env): Env {
  return envSchema.parse(source);
}
