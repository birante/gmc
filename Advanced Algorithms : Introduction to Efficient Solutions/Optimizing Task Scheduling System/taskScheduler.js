const readline = require("readline");

class Task {
	constructor(name, start, end, priority) {
		this.name = name;
		this.start = start;
		this.end = end;
		this.priority = priority;
	}
}

class TaskScheduler {
	constructor() {
		this.tasks = [];
	}

	add(task) {
		this.tasks.push(task);
	}

	// O(n log n) time, O(1) extra space (in-place sort)
	sortByStart() {
		return [...this.tasks].sort((a, b) => a.start - b.start);
	}

	// O(n) time, O(n) space
	groupByPriority() {
		const groups = new Map();
		for (const t of this.tasks) {
			if (!groups.has(t.priority)) groups.set(t.priority, []);
			groups.get(t.priority).push(t);
		}
		return groups;
	}

	// O(n log n) time (dominated by sort), O(n) space
	findOverlaps() {
		const sorted = this.sortByStart();
		const overlaps = [];
		for (let i = 0; i < sorted.length - 1; i++) {
			for (let j = i + 1; j < sorted.length; j++) {
				if (sorted[j].start >= sorted[i].end) break;
				overlaps.push([sorted[i], sorted[j]]);
			}
		}
		return overlaps;
	}

	// Rough memory estimate in bytes (optional feature)
	estimateMemory() {
		const perTask =
			(8) +                                // start
			(8) +                                // end
			(this.tasks[0]?.name.length || 0) * 2 + // utf-16 chars
			(this.tasks[0]?.priority.length || 0) * 2;
		return this.tasks.length * perTask;
	}
}

const fmt = (t) =>
	`${t.name} [${t.start}-${t.end}] (${t.priority})`;

const rl = readline.createInterface({
	input: process.stdin,
	output: process.stdout,
});

const ask = (q) => new Promise((resolve) => rl.question(q, resolve));

async function main() {
	const scheduler = new TaskScheduler();

	while (true) {
		console.log(`
1. Add Task
2. Sort by Start Time
3. Group by Priority
4. Detect Overlaps
5. Estimate Memory
6. Exit
`);
		const option = (await ask("Enter option: ")).trim();

		if (option === "1") {
			const name = (await ask("Name: ")).trim();
			const start = Number((await ask("Start time (number): ")).trim());
			const end = Number((await ask("End time (number): ")).trim());
			const priority = (await ask("Priority (High/Medium/Low): ")).trim();
			scheduler.add(new Task(name, start, end, priority));
			console.log("Task added.");
		} else if (option === "2") {
			const sorted = scheduler.sortByStart();
			if (!sorted.length) console.log("(no tasks)");
			else sorted.forEach((t) => console.log(fmt(t)));
		} else if (option === "3") {
			const groups = scheduler.groupByPriority();
			if (!groups.size) console.log("(no tasks)");
			else {
				for (const [p, list] of groups) {
					console.log(`--- ${p} ---`);
					list.forEach((t) => console.log(fmt(t)));
				}
			}
		} else if (option === "4") {
			const overlaps = scheduler.findOverlaps();
			if (!overlaps.length) console.log("No overlapping tasks.");
			else
				overlaps.forEach(([a, b]) =>
					console.log(`Overlap: ${fmt(a)}  <->  ${fmt(b)}`)
				);
		} else if (option === "5") {
			console.log(`Estimated memory: ~${scheduler.estimateMemory()} bytes`);
		} else if (option === "6") {
			rl.close();
			break;
		} else {
			console.log("Invalid option.");
		}
	}
}

main();
