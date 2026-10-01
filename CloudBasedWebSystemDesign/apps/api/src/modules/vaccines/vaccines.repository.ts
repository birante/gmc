import type { PrismaClient } from '@prisma/client';

export class VaccinesRepository {
  constructor(private readonly db: PrismaClient) {}

  list() {
    return this.db.vaccine.findMany({ orderBy: [{ recommendedAgeDays: 'asc' }, { sortOrder: 'asc' }] });
  }
}
