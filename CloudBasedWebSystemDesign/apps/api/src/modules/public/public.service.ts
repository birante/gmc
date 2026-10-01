import { computeDoseStatus, describeAge } from '../../domain/immunization-status.js';
import { normalizePhone } from '../../domain/reference-code.js';
import { toISODate } from '../../lib/dates.js';
import { notFound } from '../../lib/errors.js';
import type { PatientsRepository } from '../patients/patients.repository.js';

/**
 * Caregiver-facing lookup. It requires the card number AND the last four digits
 * of the guardian's phone, and returns the minimum data needed (first name,
 * initial, schedule) - no full name, phone or address (data minimisation).
 */
export class PublicService {
  constructor(private readonly patients: PatientsRepository) {}

  async lookup(referenceCode: string, phoneLast4: string, today = new Date()) {
    const patient = await this.patients.findByReferenceCode(referenceCode.trim().toUpperCase());
    // Same error for "unknown card" and "wrong phone" to avoid enumeration.
    if (!patient || !normalizePhone(patient.guardianPhone).endsWith(phoneLast4)) throw notFound('Vaccination card');

    const doses = patient.immunizations.map((i) => ({
      code: i.vaccine.code,
      name: i.vaccine.name,
      scheduledDate: toISODate(i.scheduledDate),
      administeredDate: i.administeredDate ? toISODate(i.administeredDate) : null,
      status: computeDoseStatus(i, today),
    }));
    const next = doses.find((d) => d.status !== 'ADMINISTERED') ?? null;
    return {
      referenceCode: patient.referenceCode,
      child: `${patient.firstName} ${patient.lastName.charAt(0)}.`,
      age: describeAge(patient.dateOfBirth, today),
      clinic: { name: patient.clinic.name, district: patient.clinic.district },
      nextDose: next,
      doses,
    };
  }
}
