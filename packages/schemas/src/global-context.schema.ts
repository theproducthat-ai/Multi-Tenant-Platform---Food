import { z } from 'zod';

/**
 * Global operating-context format validators (country/currency/timezone/locale). Format-checked
 * only — no canonical ISO/IANA list is maintained in this repo; a value that matches the shape
 * but doesn't correspond to a real code is not rejected here. See
 * docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md, Section G and Section L (decision #5).
 */

/** ISO 3166-1 alpha-2 country code, e.g. "IN". */
export const countryCodeSchema = z.string().regex(/^[A-Z]{2}$/, 'must be an ISO 3166-1 alpha-2 code');

/** ISO 4217 currency code, e.g. "INR". */
export const currencyCodeSchema = z.string().regex(/^[A-Z]{3}$/, 'must be an ISO 4217 currency code');

/** IANA timezone identifier, e.g. "Asia/Kolkata". */
export const timezoneSchema = z
  .string()
  .min(1)
  .regex(/^[A-Za-z_]+(\/[A-Za-z0-9_+-]+)+$/, 'must be an IANA timezone identifier, e.g. Asia/Kolkata');

/** BCP 47 locale identifier, e.g. "en-IN". */
export const localeSchema = z
  .string()
  .regex(/^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$/, 'must be a BCP 47 locale identifier, e.g. en-IN');
