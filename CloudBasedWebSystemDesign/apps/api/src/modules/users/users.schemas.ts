import { z } from 'zod';

export const createUserSchema = z.object({
  email: z.email().max(200),
  name: z.string().trim().min(2).max(120),
  password: z.string().min(8).max(128),
  role: z.enum(['ADMIN', 'CLINICIAN']).default('CLINICIAN'),
  clinicId: z.string().min(1).nullable().optional(),
});

export const updateUserSchema = z
  .object({
    name: z.string().trim().min(2).max(120),
    password: z.string().min(8).max(128),
    role: z.enum(['ADMIN', 'CLINICIAN']),
    clinicId: z.string().min(1).nullable(),
    active: z.boolean(),
  })
  .partial();

export type CreateUserInput = z.infer<typeof createUserSchema>;
export type UpdateUserInput = z.infer<typeof updateUserSchema>;
