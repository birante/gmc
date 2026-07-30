// palindrome.js
// Checkpoint: Recursion — "Is palindrome"
// A word is a palindrome iff it reads the same left-to-right and right-to-left.
// Examples: "gag", "kayak", "php", "radar".
//
// Processing:
//   - compare the two ends of the word
//   - equal  -> recurse on the rest of the word
//   - unequal -> not a palindrome, stop
// Base case:
//   - a word of length 0 or 1 is a palindrome.
//
// This file contains:
//   1) a recursive implementation (the checkpoint's main requirement)
//   2) an iterative implementation with a counter (for comparison)
//   3) a demo block at the bottom

// ---------------------------------------------------------------------------
// Optional normalization
// ---------------------------------------------------------------------------
// The brief speaks about a "word" so pure recursion on the raw string is
// sufficient. This helper is used only for the extended demo cases like
// "A man, a plan, a canal: Panama" where punctuation and case should be
// ignored — it is NOT called from isPalindromeRecursive itself.
function normalize(word) {
  return word.toLowerCase().replace(/[^a-z0-9]/g, "");
}

// ---------------------------------------------------------------------------
// 1) Recursive implementation — the main deliverable
// ---------------------------------------------------------------------------
// Compare the first and last characters:
//   - if they differ  -> not a palindrome
//   - if they are equal -> recurse on the substring stripped of both ends
// Base case: length <= 1 -> palindrome.
function isPalindromeRecursive(word) {
  if (word.length <= 1) return true;                    // base case
  if (word[0] !== word[word.length - 1]) return false;  // ends differ
  return isPalindromeRecursive(word.slice(1, -1));      // recurse on middle
}

// ---------------------------------------------------------------------------
// 2) Iterative implementation with two counters
// ---------------------------------------------------------------------------
// Same idea, but using a while loop and two indices that walk toward each
// other from the ends of the string.
function isPalindromeIterative(word) {
  let left = 0;
  let right = word.length - 1;
  while (left < right) {
    if (word[left] !== word[right]) return false;
    left++;
    right--;
  }
  return true;
}

// ---------------------------------------------------------------------------
// Demo
// ---------------------------------------------------------------------------
const cases = [
  "gag",
  "kayak",
  "php",
  "radar",
  "hello",
  "",         // empty -> true
  "a",        // single char -> true
  "ab",       // false
  "abba",     // true
  "abcba",    // true
];

console.log("=== Recursive ===");
for (const w of cases) {
  console.log(`  "${w}" -> ${isPalindromeRecursive(w)}`);
}

console.log("\n=== Iterative (with counters) ===");
for (const w of cases) {
  console.log(`  "${w}" -> ${isPalindromeIterative(w)}`);
}

console.log("\n=== With normalization (case + punctuation ignored) ===");
const extended = [
  "Kayak",
  "Radar",
  "A man, a plan, a canal: Panama",
  "No lemon, no melon",
  "Not a palindrome",
];
for (const w of extended) {
  const n = normalize(w);
  console.log(`  "${w}" -> ${isPalindromeRecursive(n)}`);
}

// Export for reuse / testing
export { isPalindromeRecursive, isPalindromeIterative, normalize };
