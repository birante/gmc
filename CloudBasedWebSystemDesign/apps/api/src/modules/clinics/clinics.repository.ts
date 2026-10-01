import type { Prisma, PrismaClient } from '@prisma/client';

export class ClinicsRepository {
  constructor(private readonly db: PrismaClient) {}

  list() {
    return this.db.clinic.findMany({
      orderBy: [{ region: 'asc' }, { name: 'asc' }],
      include: { _count: { select: { patients: true, users: true } } },
    });
  }

  findById(id: string) {
    return this.db.clinic.findUnique({ where: { id } });
  }

  create(data: Prisma.ClinicCreateInput) {
    return this.db.clinic.create({ data });
  }

  update(id: string, data: Prisma.ClinicUpdateInput) {
    return this.db.clinic.update({ where: { id }, data });
  }
}
