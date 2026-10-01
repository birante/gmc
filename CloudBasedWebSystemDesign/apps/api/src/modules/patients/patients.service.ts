import { buildSchedule } from '../../domain/immunization-status.js';
import { generateReferenceCode, normalizePhone } from '../../domain/reference-code.js';
import { badRequest, notFound } from '../../lib/errors.js';
import type { AuthUser } from '../../lib/jwt.js';
import { assertClinicAccess, resolveClinicScope } from '../../middleware/access.js';
import type { ClinicsRepository } from '../clinics/clinics.repository.js';
import type { VaccinesRepository } from '../vaccines/vaccines.repository.js';
import { toPatientDetail } from './patients.mapper.js';
import type { PatientsRepository } from './patients.repository.js';
import type { CreatePatientInput, ListPatientsQuery, UpdatePatientInput } from './patients.schemas.js';

export class PatientsService {
  constructor(
    private readonly patients: PatientsRepository,
    private readonly vaccines: VaccinesRepository,
    private readonly clinics: ClinicsRepository,
  ) {}

  async list(user: AuthUser, query: ListPatientsQuery) {
    const clinicId = resolveClinicScope(user, query.clinicId);
    const { items, total } = await this.patients.list({
      clinicId,
      search: query.search,
      skip: (query.page - 1) * query.pageSize,
      take: query.pageSize,
    });
    return {
      data: items,
      meta: { page: query.page, pageSize: query.pageSize, total, totalPages: Math.ceil(total / query.pageSize) },
    };
  }

  async getById(user: AuthUser, id: string) {
    let patient = await this.patients.findById(id);
    if (!patient) throw notFound('Patient');
    assertClinicAccess(user, patient.clinicId);

    // Self-healing: if the schedule gained new doses since registration, plan them now.
    const vaccines = await this.vaccines.list();
    if (patient.immunizations.length < vaccines.length) {
      const added = await this.patients.addMissingDoses(patient.id, buildSchedule(patient.dateOfBirth, vaccines));
      if (added > 0) patient = (await this.patients.findById(id))!;
    }
    return toPatientDetail(patient);
  }

  async create(user: AuthUser, input: CreatePatientInput) {
    const clinicId = user.role === 'ADMIN' ? input.clinicId : user.clinicId;
    if (!clinicId) throw badRequest('clinicId is required');
    resolveClinicScope(user, clinicId);
    if (!(await this.clinics.findById(clinicId))) throw badRequest('Unknown clinic');

    const vaccines = await this.vaccines.list();
    const referenceCode = await this.uniqueReferenceCode();
    const { clinicId: _ignored, ...demographics } = input;
    const patient = await this.patients.createWithSchedule(
      { ...demographics, guardianPhone: normalizePhone(input.guardianPhone), clinicId, referenceCode },
      buildSchedule(input.dateOfBirth, vaccines),
    );
    return toPatientDetail(patient);
  }

  async update(user: AuthUser, id: string, input: UpdatePatientInput) {
    const existing = await this.patients.findById(id);
    if (!existing) throw notFound('Patient');
    assertClinicAccess(user, existing.clinicId);

    const reschedule = input.dateOfBirth ? buildSchedule(input.dateOfBirth, await this.vaccines.list()) : undefined;
    const data = input.guardianPhone ? { ...input, guardianPhone: normalizePhone(input.guardianPhone) } : input;
    return toPatientDetail(await this.patients.update(id, data, reschedule));
  }

  async remove(user: AuthUser, id: string) {
    const existing = await this.patients.findById(id);
    if (!existing) throw notFound('Patient');
    assertClinicAccess(user, existing.clinicId);
    await this.patients.delete(id);
  }

  private async uniqueReferenceCode(): Promise<string> {
    for (let attempt = 0; attempt < 5; attempt++) {
      const code = generateReferenceCode();
      if (!(await this.patients.referenceCodeExists(code))) return code;
    }
    throw new Error('Could not generate a unique reference code');
  }
}
