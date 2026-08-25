import { describe, expect, it } from 'vitest';
import { healthCheckSchema } from './health-check.schema';

describe('healthCheckSchema', () => {
  it('accepts a valid health payload', () => {
    const result = healthCheckSchema.safeParse({
      status: 'ok',
      timestamp: new Date().toISOString(),
    });

    expect(result.success).toBe(true);
  });

  it('rejects an invalid status', () => {
    const result = healthCheckSchema.safeParse({
      status: 'down',
      timestamp: new Date().toISOString(),
    });

    expect(result.success).toBe(false);
  });
});
