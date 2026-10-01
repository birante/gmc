import { coveragePercent, DUE_WINDOW_DAYS, dropoutRate } from '../../domain/immunization-status.js';
import { addDays, startOfDayUTC } from '../../lib/dates.js';
import type { AuthUser } from '../../lib/jwt.js';
import { resolveClinicScope } from '../../middleware/access.js';
import type { DashboardRepository } from './dashboard.repository.js';

export class DashboardService {
  constructor(private readonly repo: DashboardRepository) {}

  async stats(user: AuthUser, requestedClinicId?: string, now = new Date()) {
    const clinicId = resolveClinicScope(user, requestedClinicId);
    const today = startOfDayUTC(now);

    const [patients, administeredTotal, administeredLast30Days, dueThisWeek, overdue, coverageRows, monthly] =
      await Promise.all([
        this.repo.countPatients(clinicId),
        this.repo.countDoses({ administeredDate: { not: null } }, clinicId),
        this.repo.countDoses({ administeredDate: { gte: addDays(today, -30) } }, clinicId),
        this.repo.countDoses(
          { administeredDate: null, scheduledDate: { gte: today, lt: addDays(today, DUE_WINDOW_DAYS + 1) } },
          clinicId,
        ),
        this.repo.countDoses({ administeredDate: null, scheduledDate: { lt: today } }, clinicId),
        this.repo.coverageByVaccine(today, clinicId),
        this.repo.monthlyAdministered(addDays(today, -365), clinicId),
      ]);

    const coverage = coverageRows.map((r) => ({ ...r, coverage: coveragePercent(r.administered, r.eligible) }));
    const byCode = (code: string) => coverage.find((c) => c.vaccine.code === code)?.administered ?? 0;

    return {
      clinicId: clinicId ?? null,
      generatedAt: now.toISOString(),
      totals: { patients, administeredTotal, administeredLast30Days, dueThisWeek, overdue },
      indicators: {
        penta1To3Dropout: dropoutRate(byCode('PENTA-1'), byCode('PENTA-3')),
        penta3Coverage: coverage.find((c) => c.vaccine.code === 'PENTA-3')?.coverage ?? 0,
        mr1Coverage: coverage.find((c) => c.vaccine.code === 'MR-1')?.coverage ?? 0,
      },
      coverage,
      monthly,
    };
  }
}
