import { describe, expect, it, vi } from 'vitest';
import type { ClinicsRepository } from '../../src/modules/clinics/clinics.repository.js';
import type { ImmunizationsRepository } from '../../src/modules/immunizations/immunizations.repository.js';
import { ImmunizationsService } from '../../src/modules/immunizations/immunizations.service.js';
import type { PatientsRepository } from '../../src/modules/patients/patients.repository.js';
import { PatientsService } from '../../src/modules/patients/patients.service.js';
import { InMemorySmsNotifier } from '../../src/modules/reminders/notifier.js';
import { buildReminderMessage, RemindersService } from '../../src/modules/reminders/reminders.service.js';
import type { VaccinesRepository } from '../../src/modules/vaccines/vaccines.repository.js';

// Services depend on repository *shapes*; plain objects with vi.fn() are enough to test business rules.
const fake = <T>(impl: Partial<Record<keyof T, unknown>>) => impl as unknown as T;

const admin = { id: 'admin', role: 'ADMIN' as const, clinicId: null };
const nurse = { id: 'nurse', role: 'CLINICIAN' as const, clinicId: 'c1' };
const vaccines = [
  { id: 'v-bcg', code: 'BCG', recommendedAgeDays: 0 },
  { id: 'v-penta1', code: 'PENTA-1', recommendedAgeDays: 42 },
];

function patientsService(overrides: Partial<Record<keyof PatientsRepository, unknown>> = {}) {
  const patients = fake<PatientsRepository>({
    referenceCodeExists: vi.fn().mockResolvedValue(false),
    createWithSchedule: vi.fn().mockImplementation(async (data, schedule) => ({
      ...data,
      id: 'p1',
      clinic: { id: data.clinicId, name: 'Yoff', code: 'Y', region: 'Dakar', district: 'Dakar Nord' },
      immunizations: schedule.map((s: { vaccineId: string; scheduledDate: Date }, i: number) => ({
        id: `i${i}`,
        ...s,
        administeredDate: null,
        administeredBy: null,
        lotNumber: null,
        notes: null,
        reminderSentAt: null,
        vaccine: { id: s.vaccineId, code: s.vaccineId, name: s.vaccineId, antigen: 'x', doseNumber: 1 },
      })),
    })),
    ...overrides,
  });
  const vaccinesRepo = fake<VaccinesRepository>({ list: vi.fn().mockResolvedValue(vaccines) });
  const clinics = fake<ClinicsRepository>({ findById: vi.fn().mockResolvedValue({ id: 'c1' }) });
  return { service: new PatientsService(patients, vaccinesRepo, clinics), patients };
}

const input = {
  firstName: 'Awa',
  lastName: 'Diop',
  sex: 'F' as const,
  dateOfBirth: new Date('2026-08-01'),
  guardianName: 'Fatou Diop',
  guardianPhone: '+221 77 000 45 67',
};

describe('PatientsService.create', () => {
  it('assigns clinicians\' patients to their own clinic and generates the schedule', async () => {
    const { service, patients } = patientsService();
    const result = await service.create(nurse, { ...input, clinicId: 'other-clinic-ignored' });
    expect(result.clinicId).toBe('c1');
    expect(result.guardianPhone).toBe('+221770004567');
    expect(result.referenceCode).toMatch(/^VX-/);
    expect(result.immunizations.map((d) => d.scheduledDate)).toEqual(['2026-08-01', '2026-09-12']);
    expect(patients.createWithSchedule).toHaveBeenCalledOnce();
  });

  it('requires admins to choose a clinic', async () => {
    const { service } = patientsService();
    await expect(service.create(admin, input)).rejects.toMatchObject({ statusCode: 400 });
  });

  it('retries when a generated reference code already exists', async () => {
    const exists = vi.fn().mockResolvedValueOnce(true).mockResolvedValueOnce(false);
    const { service } = patientsService({ referenceCodeExists: exists });
    await service.create(nurse, input);
    expect(exists).toHaveBeenCalledTimes(2);
  });

  it('forbids reading a patient from another clinic', async () => {
    const { service } = patientsService({ findById: vi.fn().mockResolvedValue({ id: 'p9', clinicId: 'c2' }) });
    await expect(service.getById(nurse, 'p9')).rejects.toMatchObject({ statusCode: 403 });
  });
});

describe('ImmunizationsService.administer', () => {
  const dose = (administeredDate: Date | null) => ({
    id: 'i1',
    scheduledDate: new Date('2026-09-12'),
    administeredDate,
    patient: { id: 'p1', clinicId: 'c1', dateOfBirth: new Date('2026-08-01') },
    vaccine: {},
  });

  it('records the dose with the current user', async () => {
    const update = vi.fn().mockImplementation(async (_id, data) => ({ ...dose(null), ...data }));
    const service = new ImmunizationsService(fake<ImmunizationsRepository>({ findById: vi.fn().mockResolvedValue(dose(null)), update }));
    const result = await service.administer(nurse, 'i1', { administeredDate: new Date('2026-09-14'), lotNumber: 'L42' });
    expect(update).toHaveBeenCalledWith('i1', expect.objectContaining({ administeredById: 'nurse', lotNumber: 'L42' }));
    expect(result.status).toBe('ADMINISTERED');
    expect(result.administeredDate).toBe('2026-09-14');
  });

  it('refuses to record the same dose twice', async () => {
    const service = new ImmunizationsService(fake<ImmunizationsRepository>({ findById: vi.fn().mockResolvedValue(dose(new Date())) }));
    await expect(service.administer(nurse, 'i1', {})).rejects.toMatchObject({ statusCode: 409 });
  });

  it('refuses an administration date before birth', async () => {
    const service = new ImmunizationsService(fake<ImmunizationsRepository>({ findById: vi.fn().mockResolvedValue(dose(null)) }));
    await expect(service.administer(nurse, 'i1', { administeredDate: new Date('2026-07-01') })).rejects.toMatchObject({ statusCode: 400 });
  });
});

describe('RemindersService', () => {
  const now = new Date('2026-10-01T08:00:00Z');
  const row = (id: string, patientId: string, scheduled: string, reminderSentAt: Date | null = null) => ({
    id,
    scheduledDate: new Date(scheduled),
    administeredDate: null,
    reminderSentAt,
    vaccine: { id: `v-${id}`, code: id.toUpperCase(), name: id },
    patient: {
      id: patientId,
      referenceCode: `VX-${patientId}`,
      firstName: 'Awa',
      lastName: 'Diop',
      dateOfBirth: new Date('2026-08-20'),
      guardianName: 'Fatou',
      guardianPhone: '+221770004567',
      clinic: { id: 'c1', name: 'PS Yoff' },
    },
  });

  it('groups doses per child into a single French SMS and marks them as sent', async () => {
    const markReminderSent = vi.fn().mockResolvedValue({ count: 2 });
    const repo = fake<ImmunizationsRepository>({
      pending: vi.fn().mockResolvedValue([row('penta-1', 'p1', '2026-10-02'), row('opv-1', 'p1', '2026-10-02'), row('pcv-1', 'p2', '2026-10-03', new Date('2026-09-30'))]),
      markReminderSent,
    });
    const sms = new InMemorySmsNotifier();
    const service = new RemindersService(repo, sms, 3);

    const result = await service.send(nurse, undefined, now);

    expect(result).toEqual({ candidates: 1, sent: 1, failed: [] }); // p2 was reminded yesterday
    expect(sms.sent[0]!.message).toContain('PENTA-1, OPV-1 le 02/10/2026 au PS Yoff');
    expect(markReminderSent).toHaveBeenCalledWith(['penta-1', 'opv-1'], now);
  });

  it('builds a short message', () => {
    const msg = buildReminderMessage({ guardianName: 'Fatou', childFirstName: 'Awa', vaccineCodes: ['MR-1', 'YF'], date: '2026-10-05', clinicName: 'PS Yoff', referenceCode: 'VX-AAAA-BBBB' });
    expect(msg).toBe('VaxTrack: Bonjour Fatou, Awa doit recevoir MR-1, YF le 05/10/2026 au PS Yoff. Carte VX-AAAA-BBBB.');
    expect(msg.length).toBeLessThanOrEqual(160);
  });
});
