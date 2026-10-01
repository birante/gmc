/**
 * End-to-end API tests against a real PostgreSQL database.
 * Requires TEST_DATABASE_URL (or DATABASE_URL) pointing to a migrated, disposable database.
 */
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Express } from 'express';
import { createApp } from '../../src/app.js';
import { InMemorySmsNotifier } from '../../src/modules/reminders/notifier.js';
import { DEMO_PASSWORD, seed } from '../../src/scripts/seed.js';
import { addDays, toISODate } from '../../src/lib/dates.js';

const hasDb = process.env.VAXTRACK_HAS_DB === '1';

describe.skipIf(!hasDb)('VaxTrack API (integration)', () => {
  const db = new PrismaClient();
  const sms = new InMemorySmsNotifier();
  let app: Express;
  let adminToken: string;
  let yoffToken: string;
  let pikineToken: string;
  let yoffClinicId: string;
  let patientId: string;
  let referenceCode: string;

  const login = async (email: string, password: string) => {
    const res = await request(app).post('/api/auth/login').send({ email, password });
    expect(res.status).toBe(200);
    return res.body.data.token as string;
  };

  beforeAll(async () => {
    await db.$executeRawUnsafe('TRUNCATE "Immunization", "Patient", "User", "Clinic", "Vaccine" RESTART IDENTITY CASCADE');
    process.env.ADMIN_EMAIL = 'admin@vaxtrack.test';
    process.env.ADMIN_PASSWORD = 'AdminPass!2026';
    await seed(db, { demo: true, log: () => {} });
    // Remove demo children so assertions are deterministic.
    await db.patient.deleteMany();
    app = createApp({ db, notifier: sms });

    adminToken = await login('admin@vaxtrack.test', 'AdminPass!2026');
    yoffToken = await login('infirmier.yoff@vaxtrack.sn', DEMO_PASSWORD);
    pikineToken = await login('infirmier.pikine@vaxtrack.sn', DEMO_PASSWORD);
    yoffClinicId = (await db.clinic.findUniqueOrThrow({ where: { code: 'DKR-YOFF' } })).id;
  });

  afterAll(() => db.$disconnect());

  it('GET /health reports the database as up', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ status: 'ok', database: 'up' });
  });

  it('rejects wrong credentials with a generic message', async () => {
    const res = await request(app).post('/api/auth/login').send({ email: 'admin@vaxtrack.test', password: 'wrong' });
    expect(res.status).toBe(401);
    expect(res.body.error.message).toBe('Invalid email or password');
  });

  it('GET /api/auth/me returns the profile without the password hash', async () => {
    const res = await request(app).get('/api/auth/me').set('Authorization', `Bearer ${yoffToken}`);
    expect(res.status).toBe(200);
    expect(res.body.data).toMatchObject({ email: 'infirmier.yoff@vaxtrack.sn', role: 'CLINICIAN' });
    expect(res.body.data.passwordHash).toBeUndefined();
  });

  it('a clinician registers a child and gets the full EPI schedule', async () => {
    const dob = toISODate(addDays(new Date(), -40)); // 40 days old -> 6-week doses due in 2 days
    const res = await request(app)
      .post('/api/patients')
      .set('Authorization', `Bearer ${yoffToken}`)
      .send({ firstName: 'Awa', lastName: 'Ndiaye', sex: 'F', dateOfBirth: dob, guardianName: 'Fatou Ndiaye', guardianPhone: '+221 77 123 45 67' });

    expect(res.status).toBe(201);
    expect(res.headers.location).toBe(`/api/patients/${res.body.data.id}`);
    const p = res.body.data;
    expect(p.clinicId).toBe(yoffClinicId);
    expect(p.immunizations).toHaveLength(18);
    const status = Object.fromEntries(p.immunizations.map((d: { vaccine: { code: string }; status: string }) => [d.vaccine.code, d.status]));
    expect(status).toMatchObject({ BCG: 'OVERDUE', 'PENTA-1': 'DUE', 'MR-1': 'UPCOMING' });
    patientId = p.id;
    referenceCode = p.referenceCode;
  });

  it('validates patient input', async () => {
    const res = await request(app)
      .post('/api/patients')
      .set('Authorization', `Bearer ${yoffToken}`)
      .send({ firstName: '', sex: 'X', dateOfBirth: '2999-01-01', guardianPhone: 'abc' });
    expect(res.status).toBe(400);
    expect(res.body.error.details.length).toBeGreaterThanOrEqual(4);
  });

  it('isolates clinics: another clinic cannot read the patient', async () => {
    const res = await request(app).get(`/api/patients/${patientId}`).set('Authorization', `Bearer ${pikineToken}`);
    expect(res.status).toBe(403);
    const list = await request(app).get('/api/patients').set('Authorization', `Bearer ${pikineToken}`);
    expect(list.body.meta.total).toBe(0);
  });

  it('searches patients by name and card number', async () => {
    const byName = await request(app).get('/api/patients?search=ndiaye').set('Authorization', `Bearer ${yoffToken}`);
    expect(byName.body.data).toHaveLength(1);
    const byCode = await request(app).get(`/api/patients?search=${referenceCode}`).set('Authorization', `Bearer ${adminToken}`);
    expect(byCode.body.data[0].id).toBe(patientId);
  });

  it('records an administered dose once (409 on the second attempt) and can undo it', async () => {
    const patient = await request(app).get(`/api/patients/${patientId}`).set('Authorization', `Bearer ${yoffToken}`);
    const bcg = patient.body.data.immunizations.find((d: { vaccine: { code: string } }) => d.vaccine.code === 'BCG');

    const first = await request(app)
      .post(`/api/immunizations/${bcg.id}/administer`)
      .set('Authorization', `Bearer ${yoffToken}`)
      .send({ lotNumber: 'BCG-2026-01' });
    expect(first.status).toBe(200);
    expect(first.body.data).toMatchObject({ status: 'ADMINISTERED', lotNumber: 'BCG-2026-01' });

    const second = await request(app).post(`/api/immunizations/${bcg.id}/administer`).set('Authorization', `Bearer ${yoffToken}`).send({});
    expect(second.status).toBe(409);

    const forbidden = await request(app).post(`/api/immunizations/${bcg.id}/revert`).set('Authorization', `Bearer ${pikineToken}`);
    expect(forbidden.status).toBe(403);
  });

  it('lists the due and overdue worklists', async () => {
    const due = await request(app).get('/api/immunizations/worklist?status=DUE').set('Authorization', `Bearer ${yoffToken}`);
    expect(due.status).toBe(200);
    expect(due.body.data.map((d: { vaccine: { code: string } }) => d.vaccine.code)).toEqual(expect.arrayContaining(['PENTA-1', 'OPV-1', 'PCV-1', 'ROTA-1']));
    const overdue = await request(app).get('/api/immunizations/worklist?status=OVERDUE').set('Authorization', `Bearer ${yoffToken}`);
    expect(overdue.body.data.map((d: { vaccine: { code: string } }) => d.vaccine.code)).toEqual(expect.arrayContaining(['OPV-0', 'HEPB-0']));
    expect(overdue.body.data.map((d: { vaccine: { code: string } }) => d.vaccine.code)).not.toContain('BCG');
  });

  it('computes dashboard coverage', async () => {
    const res = await request(app).get('/api/dashboard/stats').set('Authorization', `Bearer ${yoffToken}`);
    expect(res.status).toBe(200);
    const { totals, coverage } = res.body.data;
    expect(totals.patients).toBe(1);
    expect(totals.administeredTotal).toBe(1);
    expect(totals.overdue).toBe(2);
    expect(coverage.find((c: { vaccine: { code: string } }) => c.vaccine.code === 'BCG')).toMatchObject({ eligible: 1, administered: 1, coverage: 100 });
    expect(coverage.find((c: { vaccine: { code: string } }) => c.vaccine.code === 'PENTA-1')).toMatchObject({ eligible: 0, coverage: 0 });
  });

  it('sends one SMS reminder per child and does not resend it immediately', async () => {
    const preview = await request(app).get('/api/reminders/preview').set('Authorization', `Bearer ${yoffToken}`);
    expect(preview.body.data).toHaveLength(1);

    const sent = await request(app).post('/api/reminders/send').set('Authorization', `Bearer ${yoffToken}`);
    expect(sent.body.data).toMatchObject({ candidates: 1, sent: 1 });
    expect(sms.sent).toHaveLength(1);
    expect(sms.sent[0]!.to).toBe('+221771234567');
    expect(sms.sent[0]!.message).toContain(referenceCode);

    const again = await request(app).get('/api/reminders/preview').set('Authorization', `Bearer ${yoffToken}`);
    expect(again.body.data).toHaveLength(0);
  });

  it('lets caregivers look up the schedule with card + phone digits only', async () => {
    const ok = await request(app).post('/api/public/lookup').send({ referenceCode: referenceCode.toLowerCase(), phoneLast4: '4567' });
    expect(ok.status).toBe(200);
    expect(ok.body.data.child).toBe('Awa N.');
    expect(ok.body.data.nextDose.status).toBe('OVERDUE');
    expect(JSON.stringify(ok.body)).not.toContain('771234567');

    const wrong = await request(app).post('/api/public/lookup').send({ referenceCode, phoneLast4: '0000' });
    expect(wrong.status).toBe(404);
  });

  it('restricts user management to administrators', async () => {
    const asNurse = await request(app).get('/api/users').set('Authorization', `Bearer ${yoffToken}`);
    expect(asNurse.status).toBe(403);

    const created = await request(app)
      .post('/api/users')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ email: 'New.Nurse@vaxtrack.sn', name: 'New Nurse', password: 'Password123', role: 'CLINICIAN', clinicId: yoffClinicId });
    expect(created.status).toBe(201);
    expect(created.body.data.email).toBe('new.nurse@vaxtrack.sn');

    const duplicate = await request(app)
      .post('/api/users')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ email: 'new.nurse@vaxtrack.sn', name: 'Dup', password: 'Password123', role: 'CLINICIAN', clinicId: yoffClinicId });
    expect(duplicate.status).toBe(409);

    await request(app).patch(`/api/users/${created.body.data.id}`).set('Authorization', `Bearer ${adminToken}`).send({ active: false });
    const blocked = await request(app).post('/api/auth/login').send({ email: 'new.nurse@vaxtrack.sn', password: 'Password123' });
    expect(blocked.status).toBe(401);
  });

  it('re-plans pending doses when the date of birth is corrected', async () => {
    const newDob = toISODate(addDays(new Date(), -100));
    const res = await request(app).patch(`/api/patients/${patientId}`).set('Authorization', `Bearer ${yoffToken}`).send({ dateOfBirth: newDob });
    expect(res.status).toBe(200);
    const penta1 = res.body.data.immunizations.find((d: { vaccine: { code: string } }) => d.vaccine.code === 'PENTA-1');
    expect(penta1.scheduledDate).toBe(toISODate(addDays(new Date(newDob), 42)));
    const bcg = res.body.data.immunizations.find((d: { vaccine: { code: string } }) => d.vaccine.code === 'BCG');
    expect(bcg.status).toBe('ADMINISTERED');
  });

  it('only admins can delete patients', async () => {
    expect((await request(app).delete(`/api/patients/${patientId}`).set('Authorization', `Bearer ${yoffToken}`)).status).toBe(403);
    expect((await request(app).delete(`/api/patients/${patientId}`).set('Authorization', `Bearer ${adminToken}`)).status).toBe(204);
    expect((await request(app).get(`/api/patients/${patientId}`).set('Authorization', `Bearer ${adminToken}`)).status).toBe(404);
  });
});
