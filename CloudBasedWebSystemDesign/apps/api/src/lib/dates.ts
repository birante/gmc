const DAY_MS = 24 * 60 * 60 * 1000;

/** Returns a new Date at 00:00:00 UTC of the given day. All schedule maths is done in UTC dates. */
export function startOfDayUTC(date: Date): Date {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

export function addDays(date: Date, days: number): Date {
  return new Date(startOfDayUTC(date).getTime() + days * DAY_MS);
}

export function diffInDays(later: Date, earlier: Date): number {
  return Math.round((startOfDayUTC(later).getTime() - startOfDayUTC(earlier).getTime()) / DAY_MS);
}

export function toISODate(date: Date): string {
  return startOfDayUTC(date).toISOString().slice(0, 10);
}
