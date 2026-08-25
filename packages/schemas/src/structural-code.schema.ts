import { z } from 'zod';

/**
 * Business-facing code format shared by organisations, sites, site areas, service locations,
 * properties, and portfolios. Codes are immutable business identifiers, distinct from the UUID
 * primary key, and are never used as relational identifiers themselves. See
 * docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md, Section K.
 */
export const structuralCodeSchema = z
  .string()
  .min(1)
  .max(64)
  .regex(/^[A-Z0-9][A-Z0-9_-]*$/, 'must be uppercase letters, digits, underscores, or hyphens');

export type StructuralCode = z.infer<typeof structuralCodeSchema>;
