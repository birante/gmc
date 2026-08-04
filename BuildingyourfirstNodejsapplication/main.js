// Task 2 — consumer of the local module.
// Loads reportGenerator.js and prints two reports.

const { generateReport } = require("./reportGenerator");

console.log(generateReport("Alice Diop", [12, 14, 8, 16, 11]));
console.log();
console.log(generateReport("Bob Ndiaye", [8, 6, 9, 11, 5]));
