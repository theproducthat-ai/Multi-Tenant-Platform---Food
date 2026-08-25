import { z } from 'zod';

/**
 * The three tiers a Supabase-connected environment can be. Any script capable of
 * destructive or privileged database activity must check this (via `getSupabaseEnv`)
 * before running, rather than assuming a linked project is safe.
 */
export const environmentTierSchema = z.enum(['development', 'staging', 'production']);

export type EnvironmentTier = z.infer<typeof environmentTierSchema>;

export function getSupabaseEnv(source: Record<string, string | undefined> = process.env): EnvironmentTier {
  return environmentTierSchema.parse(source.SUPABASE_ENV);
}
