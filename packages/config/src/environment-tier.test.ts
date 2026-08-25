import { describe, expect, it } from 'vitest';
import { getSupabaseEnv } from './environment-tier';

describe('getSupabaseEnv', () => {
  it('accepts a valid tier', () => {
    expect(getSupabaseEnv({ SUPABASE_ENV: 'staging' })).toBe('staging');
  });

  it('rejects a missing or invalid tier', () => {
    expect(() => getSupabaseEnv({})).toThrow();
    expect(() => getSupabaseEnv({ SUPABASE_ENV: 'prod' })).toThrow();
  });
});
