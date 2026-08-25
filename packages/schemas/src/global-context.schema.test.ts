import { describe, expect, it } from 'vitest';
import { countryCodeSchema, currencyCodeSchema, localeSchema, timezoneSchema } from './global-context.schema';

describe('countryCodeSchema', () => {
  it.each(['IN', 'SG', 'US'])('accepts %s', (value) => {
    expect(countryCodeSchema.safeParse(value).success).toBe(true);
  });

  it('rejects a 3-letter code', () => {
    expect(countryCodeSchema.safeParse('IND').success).toBe(false);
  });

  it('rejects lowercase', () => {
    expect(countryCodeSchema.safeParse('in').success).toBe(false);
  });
});

describe('currencyCodeSchema', () => {
  it.each(['INR', 'SGD', 'USD'])('accepts %s', (value) => {
    expect(currencyCodeSchema.safeParse(value).success).toBe(true);
  });

  it('rejects a 2-letter code', () => {
    expect(currencyCodeSchema.safeParse('IN').success).toBe(false);
  });
});

describe('timezoneSchema', () => {
  it.each(['Asia/Kolkata', 'Asia/Singapore', 'America/New_York', 'Etc/UTC'])('accepts %s', (value) => {
    expect(timezoneSchema.safeParse(value).success).toBe(true);
  });

  it('rejects a bare offset', () => {
    expect(timezoneSchema.safeParse('UTC+5:30').success).toBe(false);
  });
});

describe('localeSchema', () => {
  it.each(['en-IN', 'en-US', 'en-SG', 'fr'])('accepts %s', (value) => {
    expect(localeSchema.safeParse(value).success).toBe(true);
  });

  it('rejects an underscore-separated locale', () => {
    expect(localeSchema.safeParse('en_IN').success).toBe(false);
  });
});
