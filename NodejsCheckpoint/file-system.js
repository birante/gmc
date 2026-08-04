// Task 3 — file system.
//   1) create welcome.txt with one line "Hello Node"
//   2) read welcome.txt back and console.log its content
//
// The brief mentions "hello.txt" in the read step but the file created
// two lines above is welcome.txt — treating it as a typo and reading
// the file we just wrote.

const fs   = require("fs");
const path = require("path");

const FILE = path.join(__dirname, "welcome.txt");

// 1) write
fs.writeFileSync(FILE, "Hello Node\n", "utf8");
console.log(`Wrote ${FILE}`);

// 2) read back
const content = fs.readFileSync(FILE, "utf8");
console.log("File content:");
console.log(content);
