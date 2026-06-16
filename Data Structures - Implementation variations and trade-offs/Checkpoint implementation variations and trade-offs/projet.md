# Checkpoint: Implementation Variations and Trade-offs

## Objective
Build two variants of a **Queue** and two variants of a **Priority Queue** so
the trade-offs become explicit:

- **Queue**
  - Array-based, **fixed capacity**, circular buffer — O(1) on every op.
  - Singly-linked-list, **dynamic** — O(1) on every op, no capacity limit.
- **Priority Queue** (smaller priority = higher priority)
  - **Min-heap** — O(log n) insert / extractMin, O(1) peek.
  - **Ordered array** kept sorted descending — O(n) insert (binary search +
    shift), O(1) extractMin / peekMin.

Every structure handles the standard edge cases:

- `dequeue` / `extractMin` / `peek` on an empty structure throws a clear error.
- `enqueue` on a full array-based queue throws.

## Idea

1. **Array Queue** uses a circular buffer (`front`, `rear`, `size`). Without
   it, `dequeue` would either shift the whole array (O(n)) or leak space at
   the head. The circular buffer keeps every op O(1) at the cost of a
   capacity.
2. **Linked Queue** keeps a `head` and `tail`. `enqueue` writes to `tail`,
   `dequeue` reads from `head`, both O(1). No capacity, but each element
   costs a node object (extra pointer + GC overhead).
3. **Min-Heap** stores nodes in an array; parent of `i` is `(i-1) >> 1`,
   children are `2i+1` / `2i+2`. `insert` bubbles up, `extractMin` swaps the
   last leaf to the root and bubbles down — both O(log n).
4. **Ordered Array** is kept **descending** by priority so the minimum lives
   at the end. `peekMin` / `extractMin` are O(1) (`pop`), while `insert` does
   a binary search for the slot (O(log n)) followed by an `Array.splice`
   shift (O(n)). The dominant cost is the shift.

## JavaScript Implementation

```js
// Array-based Queue (circular buffer)
class ArrayQueue {
    constructor(capacity = 10) {
        this.capacity = capacity;
        this.data = new Array(capacity);
        this.front = 0;
        this.rear = 0;
        this.size = 0;
    }
    enqueue(x) {
        if (this.size === this.capacity) throw new Error("Queue is full");
        this.data[this.rear] = x;
        this.rear = (this.rear + 1) % this.capacity;
        this.size++;
    }
    dequeue() {
        if (this.isEmpty()) throw new Error("Queue is empty");
        const v = this.data[this.front];
        this.front = (this.front + 1) % this.capacity;
        this.size--;
        return v;
    }
    peek()    { if (this.isEmpty()) throw new Error("Queue is empty"); return this.data[this.front]; }
    isEmpty() { return this.size === 0; }
}

// Linked-list Queue
class Node { constructor(v) { this.value = v; this.next = null; } }
class LinkedQueue {
    constructor() { this.head = null; this.tail = null; this.size = 0; }
    enqueue(x) {
        const n = new Node(x);
        if (this.tail) this.tail.next = n; else this.head = n;
        this.tail = n; this.size++;
    }
    dequeue() {
        if (this.isEmpty()) throw new Error("Queue is empty");
        const v = this.head.value;
        this.head = this.head.next;
        if (!this.head) this.tail = null;
        this.size--; return v;
    }
    peek()    { if (this.isEmpty()) throw new Error("Queue is empty"); return this.head.value; }
    isEmpty() { return this.size === 0; }
}

// Min-Heap Priority Queue
class MinHeapPriorityQueue {
    constructor() { this.heap = []; }
    insert(value, priority) {
        this.heap.push({ value, priority });
        this._bubbleUp(this.heap.length - 1);
    }
    extractMin() {
        if (this.isEmpty()) throw new Error("Priority queue is empty");
        const min = this.heap[0];
        const last = this.heap.pop();
        if (this.heap.length) { this.heap[0] = last; this._bubbleDown(0); }
        return min;
    }
    peekMin() { if (this.isEmpty()) throw new Error("Priority queue is empty"); return this.heap[0]; }
    isEmpty() { return this.heap.length === 0; }

    _bubbleUp(i) {
        while (i > 0) {
            const p = (i - 1) >> 1;
            if (this.heap[i].priority >= this.heap[p].priority) break;
            [this.heap[i], this.heap[p]] = [this.heap[p], this.heap[i]];
            i = p;
        }
    }
    _bubbleDown(i) {
        const n = this.heap.length;
        while (true) {
            const l = 2 * i + 1, r = 2 * i + 2;
            let s = i;
            if (l < n && this.heap[l].priority < this.heap[s].priority) s = l;
            if (r < n && this.heap[r].priority < this.heap[s].priority) s = r;
            if (s === i) break;
            [this.heap[i], this.heap[s]] = [this.heap[s], this.heap[i]];
            i = s;
        }
    }
}

// Ordered-array Priority Queue (sorted descending; min at the end)
class OrderedArrayPriorityQueue {
    constructor() { this.data = []; }
    insert(value, priority) {
        let lo = 0, hi = this.data.length;
        while (lo < hi) {
            const mid = (lo + hi) >> 1;
            if (this.data[mid].priority < priority) hi = mid;
            else lo = mid + 1;
        }
        this.data.splice(lo, 0, { value, priority });
    }
    extractMin() { if (this.isEmpty()) throw new Error("Priority queue is empty"); return this.data.pop(); }
    peekMin()    { if (this.isEmpty()) throw new Error("Priority queue is empty"); return this.data[this.data.length - 1]; }
    isEmpty()    { return this.data.length === 0; }
}
```

The full file (`queueAndPriorityQueue.js`) also runs a demo that exercises
every operation and triggers each edge case.

## How to Run

```bash
node queueAndPriorityQueue.js
```

## Example Output (abridged)

```
=== Array-based Queue (capacity 3) ===
dequeue on empty: threw -> Queue is empty
peek: A
enqueue when full: threw -> Queue is full
...

=== Min-Heap Priority Queue ===
extractMin on empty: threw -> Priority queue is empty
peekMin: { value: 'task-y', priority: 0 }
extractMin: { value: 'task-y', priority: 0 }
extractMin: { value: 'task-a', priority: 1 }
extractMin: { value: 'task-b', priority: 2 }
...

=== Ordered-Array Priority Queue ===
peekMin on empty: threw -> Priority queue is empty
peekMin: { value: 'retry', priority: 1 }
extractMin: { value: 'retry', priority: 1 }
extractMin: { value: 'pay', priority: 1 }
...
```

## Edge Cases Covered

| Case                                | Behaviour                            |
|-------------------------------------|--------------------------------------|
| `dequeue` on empty queue            | throws `Queue is empty`              |
| `peek` on empty queue               | throws `Queue is empty`              |
| `enqueue` on full ArrayQueue        | throws `Queue is full`               |
| `enqueue` after wrap-around         | works (circular index)               |
| `extractMin` on empty priority queue| throws `Priority queue is empty`     |
| `peekMin` on empty priority queue   | throws `Priority queue is empty`     |
| Equal priorities                    | both are returned, order is stable enough for FIFO-style use |

## Complexity

### Queue

| Operation | Array (fixed) | Linked list |
|-----------|---------------|-------------|
| `enqueue` | O(1)          | O(1)        |
| `dequeue` | O(1)          | O(1)        |
| `peek`    | O(1)          | O(1)        |
| `isEmpty` | O(1)          | O(1)        |
| Space     | O(capacity)   | O(n)        |

### Priority Queue

| Operation    | Min-Heap   | Ordered Array |
|--------------|------------|---------------|
| `insert`     | O(log n)   | O(n)          |
| `extractMin` | O(log n)   | O(1)          |
| `peekMin`    | O(1)       | O(1)          |
| `isEmpty`    | O(1)       | O(1)          |
| Space        | O(n)       | O(n)          |

## Trade-offs

**Array vs. Linked Queue.**
The array version is cache-friendly and allocates a single contiguous buffer
up front — fastest in practice when you know the upper bound. The cost is a
hard ceiling: once full, `enqueue` throws. The linked version grows on
demand but pays for one allocation per `enqueue` and walks pointers (worse
cache behaviour). Choose the array when capacity is known and traffic is
high; choose the linked list when sizes are open-ended.

**Min-Heap vs. Ordered Array Priority Queue.**
The heap is the standard answer because it balances both operations at
O(log n) and tolerates millions of items. The ordered array wins **only**
when reads heavily dominate writes: every `extractMin` / `peekMin` is O(1),
and the binary-search insert is fine on small queues. Once inserts become
frequent, the `splice` shift makes it strictly worse than the heap.

## Recommendation

For a generic backend queue, use the **linked-list queue** — the small
per-node overhead beats the risk of overflow.  Promote to the array
version when you have measured a hot path and a known maximum size.

For a generic priority queue, use the **min-heap** — predictable
`O(log n)` behaviour at every size.  Keep the ordered array in mind only
for **tiny, read-heavy** queues (typically < ~100 elements).
