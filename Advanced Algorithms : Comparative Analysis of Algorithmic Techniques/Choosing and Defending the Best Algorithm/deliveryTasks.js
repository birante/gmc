// deliveryTasks.js
// Maximum number of non-overlapping delivery tasks.
// Two implementations + benchmark + stress tests.

// ---------------------------------------------------------------------------
// 1. Brute-force: try every subset, keep the largest non-overlapping one.
//    Time:  O(2^n * n)   Space: O(n)
// ---------------------------------------------------------------------------
function bruteForceMaxTasks(tasks) {
	const n = tasks.length;
	let best = [];

	// Enumerate every subset using a bitmask.
	for (let mask = 0; mask < 1 << n; mask++) {
		const subset = [];
		for (let i = 0; i < n; i++) {
			if (mask & (1 << i)) subset.push(tasks[i]);
		}

		// Sort by start time and check for overlap.
		subset.sort((a, b) => a.start - b.start);
		let ok = true;
		for (let i = 1; i < subset.length; i++) {
			if (subset[i].start < subset[i - 1].end) {
				ok = false;
				break;
			}
		}

		if (ok && subset.length > best.length) best = subset;
	}

	return best;
}

// ---------------------------------------------------------------------------
// 2. Greedy: sort by earliest end time, then pick every task whose start is
//    >= the end of the last picked one.  Classic interval-scheduling proof.
//    Time:  O(n log n)   Space: O(n) for the sorted copy
// ---------------------------------------------------------------------------
function greedyMaxTasks(tasks) {
	const sorted = [...tasks].sort((a, b) => a.end - b.end);
	const picked = [];
	let lastEnd = -Infinity;

	for (const t of sorted) {
		if (t.start >= lastEnd) {
			picked.push(t);
			lastEnd = t.end;
		}
	}

	return picked;
}

// ---------------------------------------------------------------------------
// 3. Helpers: random generator + timer.
// ---------------------------------------------------------------------------
function randomTasks(n, maxTime = 100000) {
	const out = [];
	for (let i = 0; i < n; i++) {
		const start = Math.floor(Math.random() * maxTime);
		const end = start + 1 + Math.floor(Math.random() * 50);
		out.push({ start, end });
	}
	return out;
}

function time(label, fn) {
	const t0 = process.hrtime.bigint();
	const result = fn();
	const t1 = process.hrtime.bigint();
	const ms = Number(t1 - t0) / 1e6;
	console.log(`${label.padEnd(28)} ${result.length.toString().padStart(6)} tasks  in  ${ms.toFixed(3)} ms`);
	return result;
}

// ---------------------------------------------------------------------------
// 4. Validate correctness on the sample input.
// ---------------------------------------------------------------------------
const sample = [
	{ start: 1, end: 3 },
	{ start: 2, end: 5 },
	{ start: 4, end: 6 },
	{ start: 6, end: 7 },
	{ start: 5, end: 9 },
	{ start: 8, end: 10 },
];

console.log("=== Sample input ===");
const bSample = bruteForceMaxTasks(sample);
const gSample = greedyMaxTasks(sample);
console.log("Brute-force picks:", bSample);
console.log("Greedy picks:     ", gSample);
console.log(
	"Same count?",
	bSample.length === gSample.length ? "YES" : "NO",
	`(brute=${bSample.length}, greedy=${gSample.length})`
);

// ---------------------------------------------------------------------------
// 5. Benchmark.
//    Brute-force is exponential, so we only run it on a tiny slice (n=20).
//    Greedy handles ~10,000 tasks easily.
// ---------------------------------------------------------------------------
console.log("\n=== Benchmark ===");

const small = randomTasks(20);
time("Brute-force (n=20)", () => bruteForceMaxTasks(small));
time("Greedy     (n=20)", () => greedyMaxTasks(small));

const large = randomTasks(10000);
time("Greedy     (n=10000)", () => greedyMaxTasks(large));
console.log("Brute-force (n=10000)       SKIPPED — 2^10000 subsets is intractable.");

// ---------------------------------------------------------------------------
// 6. Bonus: stress tests on edge cases.
// ---------------------------------------------------------------------------
console.log("\n=== Edge cases ===");

// (a) All tasks overlap — answer must be 1.
const allOverlap = Array.from({ length: 15 }, (_, i) => ({ start: i, end: 100 }));
console.log(
	"All-overlap        ",
	"brute=", bruteForceMaxTasks(allOverlap).length,
	" greedy=", greedyMaxTasks(allOverlap).length
);

// (b) All tasks non-overlapping — answer must be n.
const allDisjoint = Array.from({ length: 15 }, (_, i) => ({ start: i * 2, end: i * 2 + 1 }));
console.log(
	"All-disjoint       ",
	"brute=", bruteForceMaxTasks(allDisjoint).length,
	" greedy=", greedyMaxTasks(allDisjoint).length
);

// (c) Same start time — tie-breaking matters; greedy still finds the optimum.
const sameStart = [
	{ start: 0, end: 2 },
	{ start: 0, end: 5 },
	{ start: 0, end: 10 },
	{ start: 2, end: 3 },
	{ start: 3, end: 4 },
];
console.log(
	"Same-start         ",
	"brute=", bruteForceMaxTasks(sameStart).length,
	" greedy=", greedyMaxTasks(sameStart).length
);

// (d) Same end time — only one of them can be chosen.
const sameEnd = [
	{ start: 0, end: 5 },
	{ start: 1, end: 5 },
	{ start: 2, end: 5 },
	{ start: 5, end: 9 },
];
console.log(
	"Same-end           ",
	"brute=", bruteForceMaxTasks(sameEnd).length,
	" greedy=", greedyMaxTasks(sameEnd).length
);

// (e) Greedy at scale on a pathological "all overlap" input.
const bigOverlap = Array.from({ length: 10000 }, (_, i) => ({ start: i, end: 100000 }));
time("Greedy on 10000 overlapping", () => greedyMaxTasks(bigOverlap));
