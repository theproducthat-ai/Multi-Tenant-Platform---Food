import { describe, expect, it } from 'vitest';
import { siteModeSchema } from './site-mode.schema';

describe('siteModeSchema', () => {
  it.each(['physical', 'virtual', 'hybrid'])('accepts %s', (value) => {
    expect(siteModeSchema.safeParse(value).success).toBe(true);
  });

  it('rejects an unknown mode', () => {
    expect(siteModeSchema.safeParse('remote').success).toBe(false);
  });
});
