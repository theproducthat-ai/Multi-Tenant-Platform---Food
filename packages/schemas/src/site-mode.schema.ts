import { z } from 'zod';

/**
 * Physical/virtual/hybrid trichotomy for sites — a stable, non-extensible concept (unlike
 * site_types, which is a platform reference registry). See
 * docs/MODULE_1A_ARCHITECTURE_PROPOSAL.md, Section C and Section B (`sites` table).
 */
export const siteModeSchema = z.enum(['physical', 'virtual', 'hybrid']);

export type SiteMode = z.infer<typeof siteModeSchema>;
