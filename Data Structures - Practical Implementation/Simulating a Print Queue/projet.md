# Checkpoint: Simulating a Print Queue

## Objective

Model a shared office printer that processes jobs in **First-In-First-Out**
order. The model has two layers:

1. A generic **`Queue`** class — a reusable FIFO container.
2. A domain **`PrinterQueue`** class — wraps a `Queue` and exposes
   printer-specific operations (`addJob`, `processJob`, `processAll`,
   `printQueue`).

Keeping these two responsibilities separated means the `Queue` could be
reused for any other FIFO scenario (request queue, message buffer,
breadth-first search) without dragging printer-specific code along.

## Idea

1. Build a `Queue` backed by a plain JS array — `push` to enqueue, `shift`
   to dequeue. Both operations are simple; for the volumes a single
   printer sees in real life, the `O(n)` cost of `shift` is irrelevant
   compared to the readability win.
2. Add a tiny `PrintJob` value object so the queue stores typed jobs
   (name + page count) instead of bare objects.
3. Wrap the queue in `PrinterQueue` and expose printer verbs (`addJob`,
   `processJob`, etc.). Each verb logs a short line so the simulation
   reads like a printer status feed.
4. Write a scenario that exercises every method: add a batch of jobs,
   process some, add another job mid-stream, drain the rest, and try
   processing from an empty queue.
5. Finish with `console.assert` self-checks that lock in the `Queue`
   contract (empty behaviour, FIFO order, `peek` vs `dequeue`).

## How to Run

```bash
node printerQueue.js
```

## Queue Class

```js
class Queue {
    constructor() { this.items = []; }

    enqueue(item) { this.items.push(item); }
    dequeue()     { return this.isEmpty() ? undefined : this.items.shift(); }
    peek()        { return this.items[0]; }
    isEmpty()     { return this.items.length === 0; }

    get size()    { return this.items.length; }
    toArray()     { return [...this.items]; }   // safe copy for printing
}
```

| Method     | Returns          | Time |
|------------|------------------|------|
| `enqueue`  | (nothing)        | O(1) |
| `dequeue`  | item / undefined | O(n) — shift reindexes |
| `peek`     | item / undefined | O(1) |
| `isEmpty`  | boolean          | O(1) |
| `size`     | number           | O(1) |
| `toArray`  | shallow copy     | O(n) |

If we ever needed strict O(1) dequeue, the swap is a head-pointer trick or
a linked-list backing — but the API would stay identical.

## PrintJob (value object)

```js
class PrintJob {
    constructor(name, pages) {
        this.name = name;
        this.pages = pages;
    }
    toString() {
        return `"${this.name}" (${this.pages} page${this.pages === 1 ? "" : "s"})`;
    }
}
```

## PrinterQueue Class

```js
class PrinterQueue {
    constructor() { this.queue = new Queue(); }

    addJob(name, pages) {
        if (typeof name !== "string" || name.length === 0)
            throw new Error("Job name must be a non-empty string.");
        if (!Number.isInteger(pages) || pages <= 0)
            throw new Error("Page count must be a positive integer.");
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
        if (this.queue.isEmpty()) { console.log("  (empty)"); return; }
        this.queue.toArray().forEach((job, i) => {
            const tag = i === 0 ? "  [next] " : "          ";
            console.log(`${tag}${i + 1}. ${job}`);
        });
    }
}
```

Input validation lives in `addJob` rather than in `Queue.enqueue` so the
generic queue stays type-agnostic — it would be wrong for the queue to
care whether a job has a positive page count.

## Test Scenario

The scenario in `printerQueue.js` covers the everyday flow plus the two
boundary conditions (empty queue, late arrival):

1. **Add** 5 jobs — Alice, Bob, Carol, Dan, Eve.
2. **Print the queue** — confirms FIFO order and marks the next job.
3. **Process two jobs** — Alice then Bob leave the queue.
4. **Add Frank** mid-stream — goes to the back, as FIFO requires.
5. **`processAll()`** — drains Carol, Dan, Eve, Frank in order.
6. **Process again** on the now-empty queue — handled cleanly with a
   message instead of an error.

## Sample Output

```
=== Office printer simulation ===

+ Added   "Alice — Q3 report" (12 pages)
+ Added   "Bob — invoice" (1 page)
+ Added   "Carol — slides" (45 pages)
+ Added   "Dan — contract" (8 pages)
+ Added   "Eve — boarding pass" (1 page)

Queue (5 jobs):
  [next] 1. "Alice — Q3 report" (12 pages)
          2. "Bob — invoice" (1 page)
          3. "Carol — slides" (45 pages)
          4. "Dan — contract" (8 pages)
          5. "Eve — boarding pass" (1 page)

--- Process two jobs ---
> Printing "Alice — Q3 report" (12 pages)
> Printing "Bob — invoice" (1 page)

Queue (3 jobs):
  [next] 1. "Carol — slides" (45 pages)
          2. "Dan — contract" (8 pages)
          3. "Eve — boarding pass" (1 page)

--- New job arrives ---
+ Added   "Frank — receipts" (3 pages)

Queue (4 jobs):
  [next] 1. "Carol — slides" (45 pages)
          2. "Dan — contract" (8 pages)
          3. "Eve — boarding pass" (1 page)
          4. "Frank — receipts" (3 pages)

--- Draining the queue ---
> Printing "Carol — slides" (45 pages)
> Printing "Dan — contract" (8 pages)
> Printing "Eve — boarding pass" (1 page)
> Printing "Frank — receipts" (3 pages)
--- All jobs printed ---

Queue (0 jobs):
  (empty)
- No jobs to process. Queue is empty.

=== Queue self-checks ===
All assertions passed.
```

## Why FIFO is the right structure here

A printer that respected priority would need a heap; one that allowed
cancellations from the middle would need a doubly-linked list. The brief
specifies plain FIFO, which is exactly what a queue guarantees in O(1)
amortised time per operation. Reaching for a more complex structure would
be premature — the simplest tool that satisfies the contract is the
right one.
