// decisionsAndRecursion.js
// Checkpoint: Decision Making (if-else / switch) and Recursion.
// All six tasks from the brief, each with a small demo block.

// ===========================================================================
// PART 1 — Decision Making
// ===========================================================================

// ---------------------------------------------------------------------------
// 1.1 Leap Year Checker
// A year is a leap year iff:
//   - divisible by 4 AND not divisible by 100, OR
//   - divisible by 400.
// ---------------------------------------------------------------------------
function isLeapYear(year) {
	if (!Number.isInteger(year)) return false;
	if (year % 400 === 0) return true;
	if (year % 100 === 0) return false;
	if (year % 4 === 0) return true;
	return false;
}

// ---------------------------------------------------------------------------
// 1.2 Ticket Pricing
// Children (<=12): $10  |  Teens (13-17): $15  |  Adults (>=18): $20
// Implemented with a switch on the age bucket — switch is the right tool when
// branching on a small fixed set of categories.
// ---------------------------------------------------------------------------
function ticketPrice(age) {
	if (!Number.isInteger(age) || age < 0) return null; // invalid input

	let bucket;
	if (age <= 12) bucket = "child";
	else if (age <= 17) bucket = "teen";
	else bucket = "adult";

	switch (bucket) {
		case "child": return 10;
		case "teen":  return 15;
		case "adult": return 20;
	}
}

// ---------------------------------------------------------------------------
// 1.3 Weather Clothing Adviser
// Inputs:  temperatureC (number, Celsius), raining (boolean)
// Output:  short clothing recommendation string.
// ---------------------------------------------------------------------------
function clothingAdvice(temperatureC, raining) {
	let base;
	if (temperatureC < 0)       base = "Heavy coat, hat and gloves";
	else if (temperatureC < 10) base = "Warm jacket and a scarf";
	else if (temperatureC < 18) base = "Light jacket or sweater";
	else if (temperatureC < 26) base = "T-shirt and jeans";
	else                        base = "Shorts and a light t-shirt";

	return raining ? `${base}, plus an umbrella and waterproof shoes` : base;
}

// ===========================================================================
// PART 2 — Recursion
// ===========================================================================

// ---------------------------------------------------------------------------
// 2.1 Fibonacci Sequence (recursive)
// fib(0) = 0, fib(1) = 1, fib(n) = fib(n-1) + fib(n-2)
// The plain recursion is O(2^n) — fine for small n, dramatic for n > 35.
// A memoised version (same recursion, cached results) is O(n) and is what
// we'd ship; we provide both for the checkpoint.
// ---------------------------------------------------------------------------
function fibonacci(n) {
	if (n < 0) return null;
	if (n < 2) return n;
	return fibonacci(n - 1) + fibonacci(n - 2);
}

function fibonacciMemo(n, cache = new Map()) {
	if (n < 0) return null;
	if (n < 2) return n;
	if (cache.has(n)) return cache.get(n);
	const value = fibonacciMemo(n - 1, cache) + fibonacciMemo(n - 2, cache);
	cache.set(n, value);
	return value;
}

// ---------------------------------------------------------------------------
// 2.2 Palindrome Checker (recursive)
// Strips non-alphanumerics, lower-cases, then compares first/last and
// recurses on the inside.
// ---------------------------------------------------------------------------
function isPalindrome(input) {
	const cleaned = String(input).toLowerCase().replace(/[^a-z0-9]/g, "");
	return checkPalindrome(cleaned, 0, cleaned.length - 1);
}

function checkPalindrome(s, left, right) {
	if (left >= right) return true;                 // base case: met in the middle
	if (s[left] !== s[right]) return false;         // mismatch at the ends
	return checkPalindrome(s, left + 1, right - 1); // recurse inward
}

// ---------------------------------------------------------------------------
// 2.3 Power Function (recursive)
// power(b, 0) = 1
// power(b, n) = b * power(b, n-1)              for n > 0
// power(b, n) = 1 / power(b, -n)               for n < 0
// Also expose a fast-exponentiation variant — O(log n) — to show off the
// classic recursive trick used in real numeric libraries.
// ---------------------------------------------------------------------------
function power(base, exponent) {
	if (exponent === 0) return 1;
	if (exponent < 0) return 1 / power(base, -exponent);
	return base * power(base, exponent - 1);
}

function fastPower(base, exponent) {
	if (exponent === 0) return 1;
	if (exponent < 0) return 1 / fastPower(base, -exponent);
	const half = fastPower(base, Math.floor(exponent / 2));
	return exponent % 2 === 0 ? half * half : half * half * base;
}

// ===========================================================================
// PART 3 — Demo
// ===========================================================================

console.log("=== 1.1 Leap Year Checker ===");
for (const y of [1600, 1700, 1900, 2000, 2024, 2025, 2100, 2400]) {
	console.log(`  ${y} → ${isLeapYear(y) ? "leap year" : "not a leap year"}`);
}

console.log("\n=== 1.2 Ticket Pricing ===");
for (const age of [5, 12, 13, 17, 18, 40, 99]) {
	console.log(`  age ${String(age).padStart(2)} → $${ticketPrice(age)}`);
}

console.log("\n=== 1.3 Weather Clothing Adviser ===");
const weatherSamples = [
	[-5, false], [-5, true],
	[5, false],  [15, true],
	[22, false], [30, true],
];
for (const [t, rain] of weatherSamples) {
	console.log(`  ${String(t).padStart(3)}°C, ${rain ? "raining " : "dry     "} → ${clothingAdvice(t, rain)}`);
}

console.log("\n=== 2.1 Fibonacci ===");
for (const n of [0, 1, 5, 10, 15, 20]) {
	console.log(`  fib(${String(n).padStart(2)}) = ${fibonacci(n)}`);
}
console.log(`  fibonacciMemo(50) = ${fibonacciMemo(50)}   (plain recursion would take minutes)`);

console.log("\n=== 2.2 Palindrome Checker ===");
const palindromeSamples = [
	"racecar",
	"hello",
	"A man, a plan, a canal: Panama",
	"No 'x' in Nixon",
	"Was it a car or a cat I saw?",
	"definitely not",
	"",
];
for (const s of palindromeSamples) {
	console.log(`  ${isPalindrome(s) ? "YES" : "NO "} — "${s}"`);
}

console.log("\n=== 2.3 Power Function ===");
const powerSamples = [
	[2, 10],   // 1024
	[3, 5],    // 243
	[5, 0],    // 1
	[2, -3],   // 0.125
	[1.5, 4],  // 5.0625
];
for (const [b, e] of powerSamples) {
	console.log(`  power(${b}, ${e})     = ${power(b, e)}`);
	console.log(`  fastPower(${b}, ${e}) = ${fastPower(b, e)}`);
}
