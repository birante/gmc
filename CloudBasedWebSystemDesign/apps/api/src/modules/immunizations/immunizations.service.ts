import { computeDoseStatus, DUE_WINDOW_DAYS } from '../../domain/immunization-status.js';
import { addDays, diffInDays, startOfDayUTC, toISODate } from '../../lib/dates.js';
import { badRequest, conflict, notFound } from '../../lib/errors.js';
import type { AuthUser } from '../../lib/jwt.js';
import { assertClinicAccess, resolveClinicScope } from '../../middleware/access.js';
import type { ImmunizationsRepository } from './immunizations.repository.js';
import type { AdministerInput, WorklistQuery } from './immunizations.schemas.js';

export class ImmunizationsService {
  constructor(private readonly immunizations: ImmunizationsRepository) {}

  /** Records that a dose was given. Idempotency is enforced: a dose can only be recorded once. */
  async administer(user: AuthUser, id: string, input: AdministerInput) {
    const dose = await this.immunizations.findById(id);
    if (!dose) throw notFound('Immunization');
    assertClinicAccess(user, dose.patient.clinicId);
    if (dose.administeredDate) throw conflict('This dose has already been recorded');

    const administeredDate = startOfDayUTC(input.administeredDate ?? new Date());
    if (diffInDays(administeredDate, dose.patient.dateOfBirth) < 0) {
      throw badRequest('Administration date is before the date of birth');
    }

    const updated = await this.immunizations.update(id, {
      administeredDate,
      administeredById: user.id,
      lotNumber: input.lotNumber,
      notes: input.notes,
    });
    return this.serialize(updated);
  }

  /** Reverts a dose recorded by mistake. */
  async revert(user: AuthUser, id: string) {
    const dose = await this.immunizations.findById(id);
    if (!dose) throw notFound('Immunization');
    assertClinicAccess(user, dose.patient.clinicId);
    if (!dose.administeredDate) throw conflict('This dose has not been recorded');
    const updated = await this.immunizations.update(id, {
      administeredDate: null,
      administeredById: null,
      lotNumber: null,
    });
    return this.serialize(updated);
  }

  /** Daily worklist: doses due in the coming week, or overdue doses to trace. */
  async worklist(user: AuthUser, query: WorklistQuery, today = new Date()) {
    const clinicId = resolveClinicScope(user, query.clinicId);
    const start = startOfDayUTC(today);
    const range =
      query.status === 'DUE' ? { from: start, to: addDays(start, DUE_WINDOW_DAYS + 1) } : { to: start };
    const rows = await this.immunizations.pending({ clinicId, limit: query.limit, ...range });
    return rows.map((r) => ({
      id: r.id,
      scheduledDate: toISODate(r.scheduledDate),
      daysFromToday: diffInDays(r.scheduledDate, today),
      status: computeDoseStatus(r, today),
      vaccine: r.vaccine,
      patient: { ...r.patient, dateOfBirth: toISODate(r.patient.dateOfBirth) },
      reminderSentAt: r.reminderSentAt,
    }));
  }

  private serialize<T extends { scheduledDate: Date; administeredDate: Date | null }>(dose: T) {
    return {
      ...dose,
      scheduledDate: toISODate(dose.scheduledDate),
      administeredDate: dose.administeredDate ? toISODate(dose.administeredDate) : null,
      status: computeDoseStatus(dose),
    };
  }
}
