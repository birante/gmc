// printerQueue.js
// Simulate a shared office printer using a FIFO queue.
// - Queue class:        enqueue, dequeue, peek, isEmpty, size, toArray.
// - PrinterQueue class: addJob, processJob, processAll, printQueue.

// ---------------------------------------------------------------------------
// 1. Queue — generic FIFO container.
//    Backed by a plain array. Using .push() to enqueue is O(1); .shift()
//    to dequeue is technically O(n) but the constant is tiny and the
//    intent is crystal clear, which matters more in this exercise than
//    shaving microseconds off shift().
// ---------------------------------------------------------------------------
class Queue {
	constructor() {
		this.items = [];
	}

	enqueue(item) {
		this.items.push(item);
	}

	dequeue() {
		if (this.isEmpty()) return undefined;
		return this.items.shift();
	}

	peek() {
		return this.items[0];
	}

	isEmpty() {
		return this.items.length === 0;
	}

	get size() {
		return this.items.length;
	}

	toArray() {
		return [...this.items];
	}
}

// ---------------------------------------------------------------------------
// 2. PrintJob — small value object so the queue holds typed jobs instead
//    of loose objects.
// ---------------------------------------------------------------------------
class PrintJob {
	constructor(name, pages) {
		this.name = name;
		this.pages = pages;
	}

	toString() {
		return `"${this.name}" (${this.pages} page${this.pages === 1 ? "" : "s"})`;
	}
}

// ---------------------------------------------------------------------------
// 3. PrinterQueue — domain wrapper around Queue.
//    - addJob(name, pages)  → enqueue a new PrintJob.
//    - processJob()         → dequeue the next job and "print" it.
//    - processAll()         → drain the queue, printing every job in order.
//    - printQueue()         → display the queue without modifying it.
// ---------------------------------------------------------------------------
class PrinterQueue {
	constructor() {
		this.queue = new Queue();
	}

	addJob(name, pages) {
		if (typeof name !== "string" || name.length === 0) {
			throw new Error("Job name must be a non-empty string.");
		}
		if (!Number.isInteger(pages) || pages <= 0) {
			throw new Error("Page count must be a positive integer.");
		}
		const job = new PrintJob(name, pages);
		this.queue.enqueue(job);
		console.log(`+ Added   ${job}`);
	}

	processJob() {
		if (this.queue.isEmpty()) {
			console.log("- No jobs to process. Queue is empty.");
			return null;
		}
		const job = this.queue.dequeue();
		console.log(`> Printing ${job}`);
		return job;
	}

	processAll() {
		if (this.queue.isEmpty()) {
			console.log("- No jobs to process. Queue is empty.");
			return;
		}
		console.log("\n--- Draining the queue ---");
		while (!this.queue.isEmpty()) this.processJob();
		console.log("--- All jobs printed ---");
	}

	printQueue() {
		console.log(`\nQueue (${this.queue.size} job${this.queue.size === 1 ? "" : "s"}):`);
		if (this.queue.isEmpty()) {
			console.log("  (empty)");
			return;
		}
		this.queue.toArray().forEach((job, i) => {
			const tag = i === 0 ? "  [next] " : "          ";
			console.log(`${tag}${i + 1}. ${job}`);
		});
	}
}

// ---------------------------------------------------------------------------
// 4. Test scenario.
// ---------------------------------------------------------------------------
console.log("=== Office printer simulation ===\n");

const printer = new PrinterQueue();

// Several employees submit jobs in order.
printer.addJob("Alice — Q3 report",   12);
printer.addJob("Bob — invoice",        1);
printer.addJob("Carol — slides",      45);
printer.addJob("Dan — contract",       8);
printer.addJob("Eve — boarding pass",  1);

printer.printQueue();

// Process the first two jobs.
console.log("\n--- Process two jobs ---");
printer.processJob();
printer.processJob();

printer.printQueue();

// A new job arrives mid-queue.
console.log("\n--- New job arrives ---");
printer.addJob("Frank — receipts", 3);

printer.printQueue();

// Drain the rest.
printer.processAll();

printer.printQueue();

// Trying to process from an empty queue is harmless.
printer.processJob();

// ---------------------------------------------------------------------------
// 5. Lightweight self-checks — proves the Queue contract.
// ---------------------------------------------------------------------------
console.log("\n=== Queue self-checks ===");
const q = new Queue();
console.assert(q.isEmpty(),                     "new queue must be empty");
console.assert(q.size === 0,                    "new queue size must be 0");
console.assert(q.peek() === undefined,          "peek on empty must be undefined");
console.assert(q.dequeue() === undefined,       "dequeue on empty must be undefined");

q.enqueue("a"); q.enqueue("b"); q.enqueue("c");
console.assert(q.size === 3,                    "size after 3 enqueues must be 3");
console.assert(q.peek() === "a",                "peek must return the front item");
console.assert(q.dequeue() === "a",             "dequeue must follow FIFO order");
console.assert(q.dequeue() === "b",             "dequeue must follow FIFO order");
console.assert(q.peek() === "c",                "peek must reflect new front");
console.assert(!q.isEmpty(),                    "queue with 1 item is not empty");
console.assert(q.dequeue() === "c",             "last dequeue returns last item");
console.assert(q.isEmpty(),                     "queue must be empty again");
console.log("All assertions passed.");
