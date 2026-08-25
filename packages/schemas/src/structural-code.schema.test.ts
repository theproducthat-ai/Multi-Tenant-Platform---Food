import { describe, expect, it } from 'vitest';
import { structuralCodeSchema } from './structural-code.schema';

describe('structuralCodeSchema', () => {
  it.each(['ORG-A1', 'SITE_A_IN', 'CAFE1'])('accepts %s', (value) => {
    expect(structuralCodeSchema.safeParse(value).success).toBe(true);
  });

  it('rejects lowercase codes', () => {
    expect(structuralCodeSchema.safeParse('org-a1').success).toBe(false);
  });

  it('rejects a code starting with a separator', () => {
    expect(structuralCodeSchema.safeParse('-ORG').success).toBe(false);
  });

  it('rejects an empty string', () => {
    expect(structuralCodeSchema.safeParse('').success).toBe(false);
  });
});
