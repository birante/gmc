// Task 2 — a local module.
// Exports a single function that formats a student report.
//   - takes (name, scores)
//   - returns a printable string with the average and PASS/FAIL status
//   - passing threshold: average >= 10  (French /20 grading)

function generateReport(name, scores) {
  if (typeof name !== "string" || name.trim() === "") {
    throw new Error("generateReport: name must be a non-empty string");
  }
  if (!Array.isArray(scores) || scores.length === 0) {
    throw new Error("generateReport: scores must be a non-empty array of numbers");
  }
  if (!scores.every(n => typeof n === "number" && Number.isFinite(n))) {
    throw new Error("generateReport: every score must be a finite number");
  }

  const total   = scores.reduce((sum, n) => sum + n, 0);
  const average = total / scores.length;
  const status  = average >= 10 ? "PASS" : "FAIL";

  const lines = [
    "-------- STUDENT REPORT --------",
    `Name    : ${name}`,
    `Scores  : ${scores.join(", ")}`,
    `Total   : ${total}`,
    `Average : ${average.toFixed(2)} / 20`,
    `Status  : ${status}`,
    "--------------------------------",
  ];
  return lines.join("\n");
}

module.exports = { generateReport };
