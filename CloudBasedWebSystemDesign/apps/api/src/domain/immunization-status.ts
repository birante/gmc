import { addDays, diffInDays, startOfDayUTC } from '../lib/dates.js';

export type DoseStatus = 'ADMINISTERED' | 'OVERDUE' | 'DUE' | 'UPCOMING';

/** Number of days before the scheduled date during which a dose is considered "due". */
export const DUE_WINDOW_DAYS = 7;

export interface DoseLike {
  scheduledDate: Date;
  administeredDate: Date | null;
}

/**
 * Derives the clinical status of a dose. Status is computed (never stored) so
 * that it is always consistent with "today" without background jobs.
 *
 *  - ADMINISTERED: a date of administration was recorded
 *  - OVERDUE:      scheduled date is in the past and the dose was not given
 *  - DUE:          scheduled today or within the next DUE_WINDOW_DAYS days
 *  - UPCOMING:     scheduled later than that
 */
export function computeDoseStatus(dose: DoseLike, today: Date = new Date()): DoseStatus {
  if (dose.administeredDate) return 'ADMINISTERED';
  const days = diffInDays(dose.scheduledDate, today);
  if (days < 0) return 'OVERDUE';
  if (days <= DUE_WINDOW_DAYS) return 'DUE';
  return 'UPCOMING';
}

export interface ScheduleItem {
  vaccineId: string;
  scheduledDate: Date;
}

/** Builds the list of doses a patient should receive from their date of birth. */
export function buildSchedule(
  dateOfBirth: Date,
  vaccines: ReadonlyArray<{ id: string; recommendedAgeDays: number }>,
): ScheduleItem[] {
  const dob = startOfDayUTC(dateOfBirth);
  return vaccines.map((v) => ({ vaccineId: v.id, scheduledDate: addDays(dob, v.recommendedAgeDays) }));
}

/** Age in completed days/weeks/months, used for display ("7 weeks"). */
export function describeAge(dateOfBirth: Date, today: Date = new Date()): string {
  const days = diffInDays(today, dateOfBirth);
  if (days < 0) return 'not born';
  if (days < 7 * 8) return `${Math.floor(days / 7)} week(s)`;
  if (days < 365 * 2) return `${Math.floor(days / 30.44)} month(s)`;
  return `${Math.floor(days / 365.25)} year(s)`;
}

/**
 * Coverage of a dose = administered / eligible, where eligible children are
 * those old enough to have received it. Returns a percentage with one decimal.
 */
export function coveragePercent(administered: number, eligible: number): number {
  if (eligible <= 0) return 0;
  return Math.round((administered / eligible) * 1000) / 10;
}

/**
 * Classic EPI programme indicator: share of children who started a series
 * (e.g. Penta1) but did not complete it (Penta3). WHO considers > 10% a
 * signal of an access/utilisation problem.
 */
export function dropoutRate(firstDose: number, lastDose: number): number {
  if (firstDose <= 0) return 0;
  return Math.round(((firstDose - lastDose) / firstDose) * 1000) / 10;
}

export function isWithinReminderWindow(scheduledDate: Date, windowDays: number, today: Date = new Date()): boolean {
  const days = diffInDays(scheduledDate, today);
  return days >= 0 && days <= windowDays;
}
