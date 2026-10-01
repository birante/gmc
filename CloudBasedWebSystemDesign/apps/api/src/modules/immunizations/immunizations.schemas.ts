import { z } from 'zod';

export const administerSchema = z.object({
  administeredDate: z.coerce
    .date()
    .refine((d) => d.getTime() <= Date.now() + 24 * 3600 * 1000, 'Administration date cannot be in the future')
    .optional(),
  lotNumber: z.string().trim().max(50).optional(),
  notes: z.string().trim().max(500).optional(),
});

export const worklistSchema = z.object({
  status: z.enum(['DUE', 'OVERDUE']).default('DUE'),
  clinicId: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(500).default(100),
});

export type AdministerInput = z.infer<typeof administerSchema>;
export type WorklistQuery = z.infer<typeof worklistSchema>;
