// Date helpers kept in one place so the whole system uses the same
// definition of "a day" (24h wall-clock) and can be mocked easily.

export function addDays(date, days) {
  const d = new Date(date);
  d.setDate(d.getDate() + days);
  return d;
}

export function daysBetween(a, b) {
  const MS_PER_DAY = 24 * 60 * 60 * 1000;
  return Math.floor((b.getTime() - a.getTime()) / MS_PER_DAY);
}
