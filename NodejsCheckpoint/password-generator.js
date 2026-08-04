// Task 4 — random passwords via the `generate-password` npm package.
// See: https://www.npmjs.com/package/generate-password

const generator = require("generate-password");

function newPassword(length = 16) {
  return generator.generate({
    length,
    numbers: true,
    symbols: true,
    uppercase: true,
    lowercase: true,
    strict: true,      // guarantees at least one of each requested class
    excludeSimilarCharacters: true,   // avoid 0/O, 1/l/I confusion
  });
}

// Print a handful so it is obvious they are actually random.
console.log("--- 5 random passwords ---");
for (let i = 0; i < 5; i += 1) {
  console.log(`  ${newPassword()}`);
}
