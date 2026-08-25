import { describe, expect, it } from 'vitest';
import { lifecycleStatusSchema } from './lifecycle-status.schema';

describe('lifecycleStatusSchema', () => {
  it.each(['draft', 'active', 'inactive', 'suspended', 'archived'])('accepts %s', (value) => {
    expect(lifecycleStatusSchema.safeParse(value).success).toBe(true);
  });

  it('rejects an unknown status', () => {
    expect(lifecycleStatusSchema.safeParse('deleted').success).toBe(false);
  });
});
