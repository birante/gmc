# Checkpoint: Optimizing Task Scheduling System

## Objective
Build a lightweight task scheduler in JavaScript that combines:

- A **task model** (`name`, `start`, `end`, `priority`).
- **Efficient sorting** of tasks by start time.
- **Grouping by priority** using a hash map.
- **Overlap detection** using the interval scheduling pattern.
- A **text menu** to interact with the system in the terminal.
- An **optional memory estimate** based on the number of tasks.

Each operation is analyzed with **Big O** notation for both time and space.

## Idea

1. Represent each task as a small object with four fields.
2. Store tasks in a plain array — random access in O(1) and easy iteration.
3. Sort with `Array.prototype.sort()` and a custom comparator — V8 uses
   TimSort, giving O(n log n) time.
4. Group by priority with a `Map<priority, Task[]>` — O(1) lookup, O(n)
   to build.
5. For overlaps, **sort by start time first**, then for each task only
   look at the tasks that follow it and **break** as soon as one starts at
   or after the current task ends (classic interval-scheduling shortcut).
6. The menu loops with `readline` and dispatches on the chosen option.

## JavaScript Implementation

```js
// taskScheduler.js
const readline = require("readline");

// 1. Task model
class Task {
	constructor(name, start, end, priority) {
		this.name = name;
		this.start = start;
		this.end = end;
		this.priority = priority;
	}
}

// 2. Scheduler
class TaskScheduler {
	constructor() {
		this.tasks = [];
	}

	add(task) {
		this.tasks.push(task); // O(1) amortized
	}

	// 3. Sort by start time — O(n log n) time, O(n) space (returns a copy)
	sortByStart() {
		return [...this.tasks].sort((a, b) => a.start - b.start);
	}

	// 4. Group by priority — O(n) time, O(n) space
	groupByPriority() {
		const groups = new Map();
		for (const t of this.tasks) {
			if (!groups.has(t.priority)) groups.set(t.priority, []);
			groups.get(t.priority).push(t);
		}
		return groups;
	}

	// 5. Detect overlaps — O(n log n) time (sort dominates), O(n) space
	findOverlaps() {
		const sorted = this.sortByStart();
		const overlaps = [];
		for (let i = 0; i < sorted.length - 1; i++) {
			for (let j = i + 1; j < sorted.length; j++) {
				// sorted by start, so any task starting after i ends
				// cannot overlap with i — early break keeps the inner
				// loop short in the typical case.
				if (sorted[j].start >= sorted[i].end) break;
				overlaps.push([sorted[i], sorted[j]]);
			}
		}
		return overlaps;
	}

	// 6. Optional memory estimate (bytes)
	estimateMemory() {
		const perTask =
			(8) +                                       // start (Number)
			(8) +                                       // end (Number)
			(this.tasks[0]?.name.length || 0) * 2 +     // utf-16 chars
			(this.tasks[0]?.priority.length || 0) * 2;  // utf-16 chars
		return this.tasks.length * perTask;
	}
}

// 7. Text menu
const fmt = (t) => `${t.name} [${t.start}-${t.end}] (${t.priority})`;

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
			scheduler.sortByStart().forEach((t) => console.log(fmt(t)));
		} else if (option === "3") {
			for (const [p, list] of scheduler.groupByPriority()) {
				console.log(`--- ${p} ---`);
				list.forEach((t) => console.log(fmt(t)));
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
```

## How to Run

```bash
node taskScheduler.js
```

## Example Session

Using these four tasks:

| Name    | Start | End | Priority |
|---------|-------|-----|----------|
| Email   | 9     | 10  | Low      |
| Meeting | 9     | 11  | High     |
| Lunch   | 12    | 13  | Medium   |
| Report  | 10    | 12  | High     |

```text
1. Add Task
2. Sort by Start Time
3. Group by Priority
4. Detect Overlaps
5. Estimate Memory
6. Exit

Enter option: 1
Name: Email
Start time (number): 9
End time (number): 10
Priority (High/Medium/Low): Low
Task added.

... (add the other three) ...

Enter option: 2
Email   [9-10]  (Low)
Meeting [9-11]  (High)
Report  [10-12] (High)
Lunch   [12-13] (Medium)

Enter option: 3
--- Low ---
Email [9-10] (Low)
--- High ---
Meeting [9-11] (High)
Report  [10-12] (High)
--- Medium ---
Lunch [12-13] (Medium)

Enter option: 4
Overlap: Email   [9-10]  (Low)   <->  Meeting [9-11]  (High)
Overlap: Meeting [9-11]  (High)  <->  Report  [10-12] (High)
```

## Why This Matches the Instructions

1. **Task list** with `name`, `start`, `end`, `priority` — modeled by `Task`.
2. **Sort by start time** — built-in TimSort with a custom comparator.
3. **Group by priority** — `Map<priority, Task[]>` for O(1) lookup.
4. **Detect overlaps** — sort once, then scan with an early-break inner
   loop (interval-scheduling pattern).
5. **Complexity analysis** is in every method comment and in the table
   below.
6. **Optional memory estimate** — `estimateMemory()` returns a rough byte
   count based on the number of tasks.
7. **JavaScript** implementation, single runnable file via `node`.

## Complexity

| Operation             | Structure / Algorithm     | Time        | Space   |
|-----------------------|---------------------------|-------------|---------|
| Add task              | Array push                | O(1) amort. | O(1)    |
| Sort by start         | TimSort (`Array.sort`)    | O(n log n)  | O(n)    |
| Group by priority     | Hash map (`Map`)          | O(n)        | O(n)    |
| Detect overlaps       | Sort + early-break scan   | O(n log n) *| O(n)    |
| Estimate memory       | Constant per-task math    | O(1)        | O(1)    |

`*` Worst case (everything overlaps everything) the overlap scan degrades to
O(n²) — but with sorted starts and the early `break`, real schedules stay
close to O(n log n + k) where `k` is the number of overlapping pairs.

### Optimization Notes

- **Sort once, reuse.** `findOverlaps` calls `sortByStart` and then walks
  the array; we don't re-sort inside the inner loop.
- **Early break.** Because the array is sorted by start time, once
  `sorted[j].start >= sorted[i].end` no later `j` can overlap `i` either —
  we exit the inner loop right away.
- **Hash map for grouping.** Looking up a bucket by priority is O(1),
  versus O(n) per insert if we scanned an array of `{priority, tasks}`.
- **Return a copy from `sortByStart`.** Sorting in place would mutate the
  insertion order, breaking any caller that expects the original layout.
