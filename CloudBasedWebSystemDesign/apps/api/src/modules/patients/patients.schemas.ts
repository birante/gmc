import { z } from 'zod';

const phone = z
  .string()
  .trim()
  .regex(/^\+?[\d\s-]{8,20}$/, 'Phone number must contain 8 to 20 digits, optionally starting with +');

const isoDate = z.coerce
  .date()
  .refine((d) => d.getTime() <= Date.now(), 'Date of birth cannot be in the future')
  .refine((d) => d.getUTCFullYear() >= 1900, 'Date of birth is not plausible');

export const createPatientSchema = z.object({
  firstName: z.string().trim().min(1).max(80),
  lastName: z.string().trim().min(1).max(80),
  sex: z.enum(['F', 'M']),
  dateOfBirth: isoDate,
  guardianName: z.string().trim().min(2).max(120),
  guardianPhone: phone,
  address: z.string().trim().max(200).optional(),
  clinicId: z.string().min(1).optional(),
});

export const updatePatientSchema = createPatientSchema.omit({ clinicId: true }).partial();

export const listPatientsSchema = z.object({
  search: z.string().trim().max(80).optional(),
  clinicId: z.string().optional(),
  page: z.coerce.number().int().min(1).default(1),
  pageSize: z.coerce.number().int().min(1).max(100).default(20),
});

export type CreatePatientInput = z.infer<typeof createPatientSchema>;
export type UpdatePatientInput = z.infer<typeof updatePatientSchema>;
export type ListPatientsQuery = z.infer<typeof listPatientsSchema>;
