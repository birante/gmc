// queueAndPriorityQueue.js
// Two Queue variants + two Priority Queue variants, with a runnable demo.

// ---------------------------------------------------------------------------
// 1. Array-based Queue (fixed size, circular buffer).
//    enqueue/dequeue/peek/isEmpty are all O(1).  Throws when full or empty.
// ---------------------------------------------------------------------------
class ArrayQueue {
	constructor(capacity = 10) {
		if (capacity <= 0) throw new Error("Capacity must be > 0");
		this.capacity = capacity;
		this.data = new Array(capacity);
		this.front = 0;
		this.rear = 0;
		this.size = 0;
	}

	enqueue(element) {
		if (this.size === this.capacity) throw new Error("Queue is full");
		this.data[this.rear] = element;
		this.rear = (this.rear + 1) % this.capacity;
		this.size++;
	}

	dequeue() {
		if (this.isEmpty()) throw new Error("Queue is empty");
		const value = this.data[this.front];
		this.data[this.front] = undefined; // help GC
		this.front = (this.front + 1) % this.capacity;
		this.size--;
		return value;
	}

	peek() {
		if (this.isEmpty()) throw new Error("Queue is empty");
		return this.data[this.front];
	}

	isEmpty() {
		return this.size === 0;
	}
}

// ---------------------------------------------------------------------------
// 2. Linked-List-based Queue (dynamic size).
//    enqueue/dequeue/peek/isEmpty all O(1).  Grows with available memory.
// ---------------------------------------------------------------------------
class Node {
	constructor(value) {
		this.value = value;
		this.next = null;
	}
}

class LinkedQueue {
	constructor() {
		this.head = null;
		this.tail = null;
		this.size = 0;
	}

	enqueue(element) {
		const node = new Node(element);
		if (this.tail) this.tail.next = node;
		else this.head = node;
		this.tail = node;
		this.size++;
	}

	dequeue() {
		if (this.isEmpty()) throw new Error("Queue is empty");
		const value = this.head.value;
		this.head = this.head.next;
		if (!this.head) this.tail = null;
		this.size--;
		return value;
	}

	peek() {
		if (this.isEmpty()) throw new Error("Queue is empty");
		return this.head.value;
	}

	isEmpty() {
		return this.size === 0;
	}
}

// ---------------------------------------------------------------------------
// 3. Min-Heap Priority Queue.
//    insert / extractMin: O(log n).  peekMin / isEmpty: O(1).
//    Each entry is { value, priority }; smaller priority = higher priority.
// ---------------------------------------------------------------------------
class MinHeapPriorityQueue {
	constructor() {
		this.heap = [];
	}

	insert(value, priority) {
		this.heap.push({ value, priority });
		this._bubbleUp(this.heap.length - 1);
	}

	extractMin() {
		if (this.isEmpty()) throw new Error("Priority queue is empty");
		const min = this.heap[0];
		const last = this.heap.pop();
		if (this.heap.length > 0) {
			this.heap[0] = last;
			this._bubbleDown(0);
		}
		return min;
	}

	peekMin() {
		if (this.isEmpty()) throw new Error("Priority queue is empty");
		return this.heap[0];
	}

	isEmpty() {
		return this.heap.length === 0;
	}

	_bubbleUp(i) {
		while (i > 0) {
			const parent = (i - 1) >> 1;
			if (this.heap[i].priority >= this.heap[parent].priority) break;
			[this.heap[i], this.heap[parent]] = [this.heap[parent], this.heap[i]];
			i = parent;
		}
	}

	_bubbleDown(i) {
		const n = this.heap.length;
		while (true) {
			const left = 2 * i + 1;
			const right = 2 * i + 2;
			let smallest = i;
			if (left < n && this.heap[left].priority < this.heap[smallest].priority) smallest = left;
			if (right < n && this.heap[right].priority < this.heap[smallest].priority) smallest = right;
			if (smallest === i) break;
			[this.heap[i], this.heap[smallest]] = [this.heap[smallest], this.heap[i]];
			i = smallest;
		}
	}
}

// ---------------------------------------------------------------------------
// 4. Ordered-Array Priority Queue.
//    Array kept sorted DESCENDING by priority, so the minimum is always at
//    the end.  extractMin / peekMin: O(1).  insert: O(n) (binary search to
//    find the slot + array shift to make room).
// ---------------------------------------------------------------------------
class OrderedArrayPriorityQueue {
	constructor() {
		this.data = []; // sorted descending by priority -> min at the end
	}

	insert(value, priority) {
		// Binary search for the leftmost index whose priority is < the new one.
		let lo = 0, hi = this.data.length;
		while (lo < hi) {
			const mid = (lo + hi) >> 1;
			if (this.data[mid].priority < priority) hi = mid;
			else lo = mid + 1;
		}
		this.data.splice(lo, 0, { value, priority });
	}

	extractMin() {
		if (this.isEmpty()) throw new Error("Priority queue is empty");
		return this.data.pop();
	}

	peekMin() {
		if (this.isEmpty()) throw new Error("Priority queue is empty");
		return this.data[this.data.length - 1];
	}

	isEmpty() {
		return this.data.length === 0;
	}
}

// ---------------------------------------------------------------------------
// 5. Demo + edge-case checks.
// ---------------------------------------------------------------------------
function section(title) {
	console.log(`\n=== ${title} ===`);
}

function safe(label, fn) {
	try {
		const result = fn();
		console.log(`${label}:`, result);
	} catch (e) {
		console.log(`${label}: threw -> ${e.message}`);
	}
}

// ---- Array-based Queue ----
section("Array-based Queue (capacity 3)");
const aq = new ArrayQueue(3);
console.log("isEmpty:", aq.isEmpty()); // true
safe("dequeue on empty", () => aq.dequeue());
aq.enqueue("A");
aq.enqueue("B");
aq.enqueue("C");
console.log("peek:", aq.peek());          // A
safe("enqueue when full", () => aq.enqueue("D"));
console.log("dequeue:", aq.dequeue());    // A
aq.enqueue("D");                          // wraps around to former front slot
console.log("dequeue:", aq.dequeue());    // B
console.log("dequeue:", aq.dequeue());    // C
console.log("dequeue:", aq.dequeue());    // D
console.log("isEmpty:", aq.isEmpty());    // true

// ---- Linked-List Queue ----
section("Linked-List Queue");
const lq = new LinkedQueue();
safe("peek on empty", () => lq.peek());
lq.enqueue(1);
lq.enqueue(2);
lq.enqueue(3);
console.log("peek:", lq.peek());          // 1
console.log("dequeue:", lq.dequeue());    // 1
console.log("dequeue:", lq.dequeue());    // 2
console.log("dequeue:", lq.dequeue());    // 3
console.log("isEmpty:", lq.isEmpty());    // true
safe("dequeue on empty", () => lq.dequeue());

// ---- Min-Heap Priority Queue ----
section("Min-Heap Priority Queue");
const hpq = new MinHeapPriorityQueue();
safe("extractMin on empty", () => hpq.extractMin());
hpq.insert("task-c", 3);
hpq.insert("task-a", 1);
hpq.insert("task-b", 2);
hpq.insert("task-z", 10);
hpq.insert("task-y", 0);
console.log("peekMin:", hpq.peekMin());      // priority 0
console.log("extractMin:", hpq.extractMin()); // priority 0
console.log("extractMin:", hpq.extractMin()); // priority 1
console.log("extractMin:", hpq.extractMin()); // priority 2
console.log("extractMin:", hpq.extractMin()); // priority 3
console.log("extractMin:", hpq.extractMin()); // priority 10
console.log("isEmpty:", hpq.isEmpty());      // true

// ---- Ordered-Array Priority Queue ----
section("Ordered-Array Priority Queue");
const opq = new OrderedArrayPriorityQueue();
safe("peekMin on empty", () => opq.peekMin());
opq.insert("ship", 5);
opq.insert("pay", 1);
opq.insert("notify", 3);
opq.insert("audit", 7);
opq.insert("retry", 1); // tie with "pay"
console.log("peekMin:", opq.peekMin());       // priority 1
console.log("extractMin:", opq.extractMin()); // priority 1
console.log("extractMin:", opq.extractMin()); // priority 1
console.log("extractMin:", opq.extractMin()); // priority 3
console.log("extractMin:", opq.extractMin()); // priority 5
console.log("extractMin:", opq.extractMin()); // priority 7
console.log("isEmpty:", opq.isEmpty());       // true
safe("extractMin on empty", () => opq.extractMin());
