import type { Prisma, PrismaClient } from '@prisma/client';

export interface WorklistFilter {
  clinicId?: string;
  from?: Date;
  to?: Date;
  limit: number;
}

export class ImmunizationsRepository {
  constructor(private readonly db: PrismaClient) {}

  findById(id: string) {
    return this.db.immunization.findUnique({
      where: { id },
      include: { patient: { select: { id: true, clinicId: true, dateOfBirth: true } }, vaccine: true },
    });
  }

  update(id: string, data: Prisma.ImmunizationUncheckedUpdateInput) {
    return this.db.immunization.update({ where: { id }, data, include: { vaccine: true } });
  }

  /** Pending (not administered) doses scheduled in [from, to). */
  pending({ clinicId, from, to, limit }: WorklistFilter) {
    return this.db.immunization.findMany({
      where: {
        administeredDate: null,
        scheduledDate: { ...(from ? { gte: from } : {}), ...(to ? { lt: to } : {}) },
        ...(clinicId ? { patient: { clinicId } } : {}),
      },
      include: {
        vaccine: { select: { id: true, code: true, name: true } },
        patient: {
          select: {
            id: true,
            referenceCode: true,
            firstName: true,
            lastName: true,
            dateOfBirth: true,
            guardianName: true,
            guardianPhone: true,
            clinic: { select: { id: true, name: true } },
          },
        },
      },
      orderBy: [{ scheduledDate: 'asc' }, { patientId: 'asc' }],
      take: limit,
    });
  }

  markReminderSent(ids: string[], at: Date) {
    return this.db.immunization.updateMany({ where: { id: { in: ids } }, data: { reminderSentAt: at } });
  }
}
