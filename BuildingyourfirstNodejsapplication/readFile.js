// Task 1 — using the built-in `fs` module.
// Reads message.txt synchronously and prints its content.

const fs = require("fs");
const path = require("path");

// path.join keeps the script working no matter what the caller's cwd is.
const filePath = path.join(__dirname, "message.txt");

const content = fs.readFileSync(filePath, "utf8");
console.log(content);
