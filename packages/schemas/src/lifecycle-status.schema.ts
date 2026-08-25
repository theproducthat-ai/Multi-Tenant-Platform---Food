import { z } from 'zod';

/**
 * Shared lifecycle values for structural entities (organisations, sites, site areas, service
 * locations, properties, portfolios, organisation units). See
 * docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md, Section I.
 */
export const lifecycleStatusSchema = z.enum(['draft', 'active', 'inactive', 'suspended', 'archived']);

export type LifecycleStatus = z.infer<typeof lifecycleStatusSchema>;
