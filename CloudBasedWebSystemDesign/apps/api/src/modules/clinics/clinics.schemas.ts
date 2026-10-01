import { z } from 'zod';

export const createClinicSchema = z.object({
  code: z
    .string()
    .trim()
    .toUpperCase()
    .regex(/^[A-Z0-9-]{2,20}$/, 'Code must be 2-20 letters, digits or dashes'),
  name: z.string().trim().min(2).max(150),
  region: z.string().trim().min(2).max(80),
  district: z.string().trim().min(2).max(80),
});

export const updateClinicSchema = createClinicSchema.partial();
export type CreateClinicInput = z.infer<typeof createClinicSchema>;
export type UpdateClinicInput = z.infer<typeof updateClinicSchema>;
