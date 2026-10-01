/**
 * Idempotent seed: EPI schedule, admin account and (optionally) demo data.
 * Safe to run on every boot (SEED_ON_START=true) - existing rows are kept.
 *
 *   npm run db:seed            (development, via tsx)
 *   node dist/scripts/seed.js  (production build)
 */
import { pathToFileURL } from 'node:url';
import { PrismaClient, type Sex } from '@prisma/client';
import bcrypt from 'bcryptjs';
import { DEFAULT_EPI_SCHEDULE } from '../domain/epi-schedule.js';
import { buildSchedule } from '../domain/immunization-status.js';
import { generateReferenceCode } from '../domain/reference-code.js';
import { addDays, startOfDayUTC } from '../lib/dates.js';

export interface SeedOptions {
  demo?: boolean;
  log?: (msg: string) => void;
  today?: Date;
}

export const DEMO_PASSWORD = 'Demo!2026';
export const DEMO_REFERENCE_CODE = 'VX-DEMO-2026';

const DEMO_CLINICS = [
  { code: 'DKR-YOFF', name: 'Poste de Sante de Yoff', region: 'Dakar', district: 'Dakar Nord' },
  { code: 'DKR-PIKINE', name: 'Centre de Sante de Pikine', region: 'Dakar', district: 'Pikine' },
  { code: 'THS-NORD', name: 'Poste de Sante de Thies Nord', region: 'Thies', district: 'Thies' },
];
const FIRST = ['Awa', 'Fatou', 'Aminata', 'Mariama', 'Khady', 'Ndeye', 'Aissatou', 'Seynabou', 'Moussa', 'Mamadou', 'Ibrahima', 'Cheikh', 'Ousmane', 'Abdoulaye', 'Modou', 'Pape'];
const LAST = ['Diop', 'Ndiaye', 'Fall', 'Sow', 'Gueye', 'Ba', 'Faye', 'Sarr', 'Diallo', 'Cisse', 'Mbaye', 'Thiam'];

/** Small deterministic PRNG so demo data is reproducible across runs. */
function prng(seed: number) {
  let s = seed >>> 0;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return s / 2 ** 32;
  };
}

export async function seed(db: PrismaClient, options: SeedOptions = {}) {
  const log = options.log ?? ((m: string) => console.log(`[seed] ${m}`));
  const today = startOfDayUTC(options.today ?? new Date());

  // 1. Reference data: vaccination schedule.
  for (const [index, entry] of DEFAULT_EPI_SCHEDULE.entries()) {
    await db.vaccine.upsert({
      where: { code: entry.code },
      update: {},
      create: { ...entry, sortOrder: index },
    });
  }
  log(`schedule: ${DEFAULT_EPI_SCHEDULE.length} doses`);

  // 2. Administrator account.
  const adminEmail = (process.env.ADMIN_EMAIL ?? 'admin@vaxtrack.sn').toLowerCase();
  const adminPassword = process.env.ADMIN_PASSWORD ?? (process.env.NODE_ENV === 'production' ? undefined : 'ChangeMe!2026');
  if (adminPassword) {
    await db.user.upsert({
      where: { email: adminEmail },
      update: {},
      create: { email: adminEmail, name: 'System Administrator', role: 'ADMIN', passwordHash: await bcrypt.hash(adminPassword, 10) },
    });
    log(`admin: ${adminEmail}`);
  } else {
    log('admin: skipped (set ADMIN_PASSWORD to create it)');
  }

  if (!options.demo) return;

  // 3. Demo clinics and clinicians.
  const clinics = [];
  for (const c of DEMO_CLINICS) {
    clinics.push(await db.clinic.upsert({ where: { code: c.code }, update: {}, create: c }));
  }
  const demoHash = await bcrypt.hash(DEMO_PASSWORD, 10);
  for (const clinic of clinics) {
    const slug = clinic.code.toLowerCase().split('-')[1];
    await db.user.upsert({
      where: { email: `infirmier.${slug}@vaxtrack.sn` },
      update: {},
      create: {
        email: `infirmier.${slug}@vaxtrack.sn`,
        name: `Infirmier(e) ${clinic.name.replace(/^(Poste|Centre) de Sante de /, '')}`,
        role: 'CLINICIAN',
        clinicId: clinic.id,
        passwordHash: demoHash,
      },
    });
  }

  if ((await db.patient.count()) > 0) {
    log('demo patients: already present, skipping');
    return;
  }

  // 4. Demo patients with a realistic, slightly decaying completion pattern.
  const vaccines = await db.vaccine.findMany({ orderBy: [{ recommendedAgeDays: 'asc' }, { sortOrder: 'asc' }] });
  const nurse = await db.user.findFirst({ where: { role: 'CLINICIAN' } });
  const rand = prng(2026);
  const total = 60;
  for (let i = 0; i < total; i++) {
    const clinic = clinics[i % clinics.length]!;
    const ageDays = i === 0 ? 40 : Math.floor(rand() * 540); // 0-18 months; demo child is ~6 weeks old.
    const dateOfBirth = addDays(today, -ageDays);
    const sex: Sex = rand() < 0.5 ? 'F' : 'M';
    const firstName = FIRST[Math.floor(rand() * FIRST.length)]!;
    const lastName = LAST[Math.floor(rand() * LAST.length)]!;
    // Attendance is simulated per visit (all doses due at the same age are given together).
    // A family that misses a visit may drop out of the series, which produces a realistic
    // Penta1 -> Penta3 dropout instead of independent random doses.
    const compliance = 0.8 + rand() * 0.2;
    const visits = new Map<number, boolean>();
    let active = true;
    const schedule = buildSchedule(dateOfBirth, vaccines).map((dose, idx) => {
      const age = vaccines[idx]!.recommendedAgeDays;
      const isPast = dose.scheduledDate.getTime() <= today.getTime();
      if (!visits.has(age)) {
        const attended = isPast && active && rand() < compliance;
        if (isPast && !attended && rand() < 0.5) active = false;
        visits.set(age, attended);
      }
      const given = visits.get(age)!;
      const delay = Math.floor(rand() * 10);
      const administeredDate = given ? (addDays(dose.scheduledDate, delay) > today ? today : addDays(dose.scheduledDate, delay)) : null;
      return { ...dose, administeredDate, administeredById: given ? nurse?.id : null };
    });
    await db.patient.create({
      data: {
        referenceCode: i === 0 ? DEMO_REFERENCE_CODE : generateReferenceCode(),
        firstName: i === 0 ? 'Awa' : firstName,
        lastName: i === 0 ? 'Diop' : lastName,
        sex: i === 0 ? 'F' : sex,
        dateOfBirth,
        guardianName: i === 0 ? 'Fatou Diop' : `${FIRST[Math.floor(rand() * 8)]} ${lastName}`,
        guardianPhone: i === 0 ? '+221770004567' : `+22177${String(Math.floor(rand() * 1e7)).padStart(7, '0')}`,
        address: `${clinic.district}, ${clinic.region}`,
        clinicId: clinic.id,
        immunizations: { createMany: { data: schedule } },
      },
    });
  }
  log(`demo patients: ${total} (lookup card ${DEMO_REFERENCE_CODE} / phone last 4 digits 4567)`);
}

// CLI entry point
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const db = new PrismaClient();
  const demo = process.env.SEED_DEMO_DATA !== 'false';
  seed(db, { demo })
    .then(() => console.log('[seed] done'))
    .catch((err) => {
      console.error(err);
      process.exitCode = 1;
    })
    .finally(() => db.$disconnect());
}
