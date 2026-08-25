import { describe, expect, it } from 'vitest';
import { loadEnv } from './env.schema';

describe('loadEnv', () => {
  it('defaults NODE_ENV to development when unset', () => {
    const env = loadEnv({});
    expect(env.NODE_ENV).toBe('development');
  });

  it('accepts a valid NODE_ENV value', () => {
    const env = loadEnv({ NODE_ENV: 'test' });
    expect(env.NODE_ENV).toBe('test');
  });

  it('rejects an invalid NODE_ENV value', () => {
    expect(() => loadEnv({ NODE_ENV: 'bogus' })).toThrow();
  });
});
