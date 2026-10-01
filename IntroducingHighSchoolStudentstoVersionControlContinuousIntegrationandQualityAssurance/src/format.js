/**
 * Turns a gradebook report (see Gradebook#report) into a printable text table.
 * @param {ReturnType<import('./gradebook.js').Gradebook['report']>} report
 * @returns {string}
 */
export function formatReport(report) {
  const lines = [];
  lines.push(`Class: ${report.className}`);
  lines.push(`Students: ${report.studentCount}`);
  lines.push(`Class average: ${report.classAverage ?? 'n/a'}`);
  lines.push(`Pass rate: ${report.passRate === null ? 'n/a' : `${report.passRate}%`}`);
  lines.push('');

  if (report.rows.length === 0) {
    lines.push('No scores recorded yet.');
    return lines.join('\n');
  }

  const nameWidth = Math.max(4, ...report.rows.map((row) => row.name.length));
  lines.push(`${'#'.padEnd(3)} ${'Name'.padEnd(nameWidth)}  Avg     Grade  Status`);
  lines.push('-'.repeat(nameWidth + 30));
  for (const row of report.rows) {
    const status = row.passing ? 'PASS' : 'FAIL';
    lines.push(
      `${String(row.rank).padEnd(3)} ${row.name.padEnd(nameWidth)}  ${row.average.toFixed(2).padStart(6)}  ${row.letter.padEnd(5)}  ${status}`,
    );
  }
  return lines.join('\n');
}
