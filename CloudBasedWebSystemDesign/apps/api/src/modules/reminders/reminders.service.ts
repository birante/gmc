import { addDays, startOfDayUTC, toISODate } from '../../lib/dates.js';
import type { AuthUser } from '../../lib/jwt.js';
import { resolveClinicScope } from '../../middleware/access.js';
import type { ImmunizationsRepository } from '../immunizations/immunizations.repository.js';
import type { SmsNotifier } from './notifier.js';

/** Do not remind the same family about overdue doses more than once a week. */
const RESEND_AFTER_DAYS = 7;
/** Overdue doses older than this are left to community health workers for active tracing. */
const OVERDUE_LOOKBACK_DAYS = 30;

export interface ReminderMessage {
  patientId: string;
  to: string;
  message: string;
  immunizationIds: string[];
}

function formatDate(iso: string): string {
  const [y, m, d] = iso.split('-');
  return `${d}/${m}/${y}`;
}

/** Builds one French SMS (<= ~160 chars when possible) per child listing the doses due. */
export function buildReminderMessage(input: {
  guardianName: string;
  childFirstName: string;
  vaccineCodes: string[];
  date: string;
  clinicName: string;
  referenceCode: string;
}): string {
  return (
    `VaxTrack: Bonjour ${input.guardianName}, ${input.childFirstName} doit recevoir ` +
    `${input.vaccineCodes.join(', ')} le ${formatDate(input.date)} au ${input.clinicName}. ` +
    `Carte ${input.referenceCode}.`
  );
}

export class RemindersService {
  constructor(
    private readonly immunizations: ImmunizationsRepository,
    private readonly notifier: SmsNotifier,
    private readonly windowDays: number,
  ) {}

  /** Computes the reminders that would be sent now, grouped by child. */
  async preview(user: AuthUser, requestedClinicId?: string, now = new Date()): Promise<ReminderMessage[]> {
    const clinicId = resolveClinicScope(user, requestedClinicId);
    const today = startOfDayUTC(now);
    const resendBefore = addDays(today, -RESEND_AFTER_DAYS);
    const rows = await this.immunizations.pending({
      clinicId,
      from: addDays(today, -OVERDUE_LOOKBACK_DAYS),
      to: addDays(today, this.windowDays + 1),
      limit: 1000,
    });

    const byPatient = new Map<string, typeof rows>();
    for (const row of rows) {
      if (row.reminderSentAt && row.reminderSentAt > resendBefore) continue;
      const list = byPatient.get(row.patient.id) ?? [];
      list.push(row);
      byPatient.set(row.patient.id, list);
    }

    return [...byPatient.values()].map((doses) => {
      const { patient } = doses[0]!;
      const nextDate = doses.reduce((min, d) => (d.scheduledDate < min ? d.scheduledDate : min), doses[0]!.scheduledDate);
      const date = toISODate(nextDate < today ? today : nextDate);
      return {
        patientId: patient.id,
        to: patient.guardianPhone,
        immunizationIds: doses.map((d) => d.id),
        message: buildReminderMessage({
          guardianName: patient.guardianName,
          childFirstName: patient.firstName,
          vaccineCodes: doses.map((d) => d.vaccine.code),
          date,
          clinicName: patient.clinic.name,
          referenceCode: patient.referenceCode,
        }),
      };
    });
  }

  /** Sends the reminders and records `reminderSentAt` so they are not repeated. */
  async send(user: AuthUser, requestedClinicId?: string, now = new Date()) {
    const messages = await this.preview(user, requestedClinicId, now);
    let sent = 0;
    const failed: string[] = [];
    for (const m of messages) {
      try {
        await this.notifier.send(m.to, m.message);
        await this.immunizations.markReminderSent(m.immunizationIds, now);
        sent++;
      } catch {
        failed.push(m.patientId);
      }
    }
    return { candidates: messages.length, sent, failed };
  }
}
