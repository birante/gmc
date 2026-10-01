import type { Prisma, PrismaClient } from '@prisma/client';
import type { ScheduleItem } from '../../domain/immunization-status.js';

const detailInclude = {
  clinic: { select: { id: true, name: true, code: true, region: true, district: true } },
  immunizations: {
    include: {
      vaccine: true,
      administeredBy: { select: { id: true, name: true } },
    },
    orderBy: [{ scheduledDate: 'asc' }, { vaccine: { sortOrder: 'asc' } }],
  },
} satisfies Prisma.PatientInclude;

export type PatientWithSchedule = Prisma.PatientGetPayload<{ include: typeof detailInclude }>;

export interface PatientListFilter {
  clinicId?: string;
  search?: string;
  skip: number;
  take: number;
}

export class PatientsRepository {
  constructor(private readonly db: PrismaClient) {}

  async list({ clinicId, search, skip, take }: PatientListFilter) {
    const where: Prisma.PatientWhereInput = {
      ...(clinicId ? { clinicId } : {}),
      ...(search
        ? {
            OR: [
              { firstName: { contains: search, mode: 'insensitive' } },
              { lastName: { contains: search, mode: 'insensitive' } },
              { referenceCode: { contains: search, mode: 'insensitive' } },
              { guardianPhone: { contains: search } },
            ],
          }
        : {}),
    };
    const [items, total] = await this.db.$transaction([
      this.db.patient.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: { clinic: { select: { id: true, name: true } } },
      }),
      this.db.patient.count({ where }),
    ]);
    return { items, total };
  }

  findById(id: string): Promise<PatientWithSchedule | null> {
    return this.db.patient.findUnique({ where: { id }, include: detailInclude });
  }

  findByReferenceCode(referenceCode: string): Promise<PatientWithSchedule | null> {
    return this.db.patient.findUnique({ where: { referenceCode }, include: detailInclude });
  }

  async referenceCodeExists(referenceCode: string): Promise<boolean> {
    return (await this.db.patient.count({ where: { referenceCode } })) > 0;
  }

  /** Creates the patient and their full immunisation schedule atomically. */
  createWithSchedule(data: Prisma.PatientUncheckedCreateInput, schedule: ScheduleItem[]) {
    return this.db.patient.create({
      data: { ...data, immunizations: { createMany: { data: schedule } } },
      include: detailInclude,
    });
  }

  /** Adds doses that were introduced in the schedule after the patient was registered. */
  async addMissingDoses(patientId: string, schedule: ScheduleItem[]): Promise<number> {
    const result = await this.db.immunization.createMany({
      data: schedule.map((s) => ({ ...s, patientId })),
      skipDuplicates: true,
    });
    return result.count;
  }

  /** Updates demographics and, if the date of birth changed, re-plans doses not yet given. */
  update(id: string, data: Prisma.PatientUncheckedUpdateInput, reschedule?: ScheduleItem[]) {
    return this.db.$transaction(async (tx) => {
      await tx.patient.update({ where: { id }, data });
      for (const item of reschedule ?? []) {
        await tx.immunization.updateMany({
          where: { patientId: id, vaccineId: item.vaccineId, administeredDate: null },
          data: { scheduledDate: item.scheduledDate },
        });
      }
      return tx.patient.findUniqueOrThrow({ where: { id }, include: detailInclude });
    });
  }

  delete(id: string) {
    return this.db.patient.delete({ where: { id } });
  }
}
