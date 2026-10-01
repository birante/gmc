import type { Prisma, PrismaClient } from '@prisma/client';

export class DashboardRepository {
  constructor(private readonly db: PrismaClient) {}

  private scope(clinicId?: string): Prisma.ImmunizationWhereInput {
    return clinicId ? { patient: { clinicId } } : {};
  }

  countPatients(clinicId?: string) {
    return this.db.patient.count({ where: clinicId ? { clinicId } : {} });
  }

  countDoses(where: Prisma.ImmunizationWhereInput, clinicId?: string) {
    return this.db.immunization.count({ where: { ...where, ...this.scope(clinicId) } });
  }

  /** Eligible (scheduled on or before `asOf`) and administered dose counts, grouped by vaccine. */
  async coverageByVaccine(asOf: Date, clinicId?: string) {
    const base: Prisma.ImmunizationWhereInput = { scheduledDate: { lte: asOf }, ...this.scope(clinicId) };
    const [eligible, administered, vaccines] = await Promise.all([
      this.db.immunization.groupBy({ by: ['vaccineId'], where: base, _count: { _all: true } }),
      this.db.immunization.groupBy({
        by: ['vaccineId'],
        where: { ...base, administeredDate: { not: null } },
        _count: { _all: true },
      }),
      this.db.vaccine.findMany({ orderBy: [{ recommendedAgeDays: 'asc' }, { sortOrder: 'asc' }] }),
    ]);
    const eligibleMap = new Map(eligible.map((e) => [e.vaccineId, e._count._all]));
    const administeredMap = new Map(administered.map((a) => [a.vaccineId, a._count._all]));
    return vaccines.map((v) => ({
      vaccine: { id: v.id, code: v.code, name: v.name, antigen: v.antigen },
      eligible: eligibleMap.get(v.id) ?? 0,
      administered: administeredMap.get(v.id) ?? 0,
    }));
  }

  /** Doses administered per month since `since` (YYYY-MM buckets). */
  monthlyAdministered(since: Date, clinicId?: string) {
    return this.db.$queryRaw<Array<{ month: string; count: number }>>`
      SELECT to_char(date_trunc('month', i."administeredDate"), 'YYYY-MM') AS month,
             COUNT(*)::int AS count
      FROM "Immunization" i
      JOIN "Patient" p ON p.id = i."patientId"
      WHERE i."administeredDate" >= ${since}
        AND (${clinicId ?? null}::text IS NULL OR p."clinicId" = ${clinicId ?? null})
      GROUP BY 1
      ORDER BY 1`;
  }
}
