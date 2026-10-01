import { computeDoseStatus, describeAge } from '../../domain/immunization-status.js';
import { toISODate } from '../../lib/dates.js';
import type { PatientWithSchedule } from './patients.repository.js';

/** Shapes a patient aggregate for the API: ISO dates + computed dose status. */
export function toPatientDetail(patient: PatientWithSchedule, today = new Date()) {
  const { immunizations, ...rest } = patient;
  const doses = immunizations.map((i) => ({
    id: i.id,
    vaccine: {
      id: i.vaccine.id,
      code: i.vaccine.code,
      name: i.vaccine.name,
      antigen: i.vaccine.antigen,
      doseNumber: i.vaccine.doseNumber,
    },
    scheduledDate: toISODate(i.scheduledDate),
    administeredDate: i.administeredDate ? toISODate(i.administeredDate) : null,
    administeredBy: i.administeredBy,
    lotNumber: i.lotNumber,
    notes: i.notes,
    reminderSentAt: i.reminderSentAt,
    status: computeDoseStatus(i, today),
  }));
  const summary = {
    total: doses.length,
    administered: doses.filter((d) => d.status === 'ADMINISTERED').length,
    overdue: doses.filter((d) => d.status === 'OVERDUE').length,
    due: doses.filter((d) => d.status === 'DUE').length,
  };
  return {
    ...rest,
    dateOfBirth: toISODate(patient.dateOfBirth),
    age: describeAge(patient.dateOfBirth, today),
    summary,
    immunizations: doses,
  };
}
