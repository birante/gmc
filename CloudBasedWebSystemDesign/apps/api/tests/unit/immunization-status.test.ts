import { describe, expect, it } from 'vitest';
import {
  buildSchedule, computeDoseStatus, coveragePercent, describeAge, dropoutRate, isWithinReminderWindow,
} from '../../src/domain/immunization-status.js';
import { DEFAULT_EPI_SCHEDULE } from '../../src/domain/epi-schedule.js';
import { addDays, diffInDays, toISODate } from '../../src/lib/dates.js';

const today = new Date('2026-10-01T10:30:00Z');

describe('computeDoseStatus', () => {
  it('is ADMINISTERED whenever an administration date exists, even if late', () => {
    expect(computeDoseStatus({ scheduledDate: new Date('2026-01-01'), administeredDate: new Date('2026-03-01') }, today)).toBe('ADMINISTERED');
  });

  it('is OVERDUE when the scheduled date has passed', () => {
    expect(computeDoseStatus({ scheduledDate: new Date('2026-09-30'), administeredDate: null }, today)).toBe('OVERDUE');
  });

  it('is DUE today and up to 7 days ahead', () => {
    expect(computeDoseStatus({ scheduledDate: new Date('2026-10-01'), administeredDate: null }, today)).toBe('DUE');
    expect(computeDoseStatus({ scheduledDate: new Date('2026-10-08'), administeredDate: null }, today)).toBe('DUE');
  });

  it('is UPCOMING beyond the due window', () => {
    expect(computeDoseStatus({ scheduledDate: new Date('2026-10-09'), administeredDate: null }, today)).toBe('UPCOMING');
  });
});

describe('buildSchedule', () => {
  it('plans every dose from the date of birth at UTC midnight', () => {
    const vaccines = [
      { id: 'bcg', recommendedAgeDays: 0 },
      { id: 'penta1', recommendedAgeDays: 42 },
    ];
    const schedule = buildSchedule(new Date('2026-08-01T23:15:00Z'), vaccines);
    expect(schedule.map((s) => [s.vaccineId, toISODate(s.scheduledDate)])).toEqual([
      ['bcg', '2026-08-01'],
      ['penta1', '2026-09-12'],
    ]);
  });

  it('produces one dose per entry of the default EPI schedule', () => {
    const vaccines = DEFAULT_EPI_SCHEDULE.map((e) => ({ id: e.code, recommendedAgeDays: e.recommendedAgeDays }));
    const schedule = buildSchedule(new Date('2026-01-01'), vaccines);
    expect(schedule).toHaveLength(DEFAULT_EPI_SCHEDULE.length);
    expect(new Set(DEFAULT_EPI_SCHEDULE.map((e) => e.code)).size).toBe(DEFAULT_EPI_SCHEDULE.length);
  });
});

describe('indicators', () => {
  it('computes coverage with one decimal and handles empty denominators', () => {
    expect(coveragePercent(35, 40)).toBe(87.5);
    expect(coveragePercent(1, 3)).toBe(33.3);
    expect(coveragePercent(0, 0)).toBe(0);
  });

  it('computes the Penta1-Penta3 dropout rate', () => {
    expect(dropoutRate(100, 88)).toBe(12);
    expect(dropoutRate(0, 0)).toBe(0);
  });
});

describe('helpers', () => {
  it('describes age in weeks, months or years', () => {
    expect(describeAge(addDays(today, -20), today)).toBe('2 week(s)');
    expect(describeAge(addDays(today, -200), today)).toBe('6 month(s)');
    expect(describeAge(addDays(today, -1000), today)).toBe('2 year(s)');
  });

  it('detects the reminder window', () => {
    expect(isWithinReminderWindow(addDays(today, 3), 3, today)).toBe(true);
    expect(isWithinReminderWindow(addDays(today, 4), 3, today)).toBe(false);
    expect(isWithinReminderWindow(addDays(today, -1), 3, today)).toBe(false);
  });

  it('computes day differences across DST-free UTC dates', () => {
    expect(diffInDays(new Date('2026-03-01'), new Date('2026-02-01'))).toBe(28);
  });
});
