// networkCable.js
// Connect every computer in the office with the minimum total cable length.
// Two MST implementations + benchmark + edge-case stress tests + a tiny
// interactive demo of dynamically added nodes/edges.

// ---------------------------------------------------------------------------
// 1. Disjoint Set (Union-Find) with path compression + union by rank.
//    Used by Kruskal to detect cycles.
//    Time: ~O(alpha(n)) per op   Space: O(n)
// ---------------------------------------------------------------------------
class DisjointSet {
	constructor(n) {
		this.parent = Array.from({ length: n }, (_, i) => i);
		this.rank = new Array(n).fill(0);
	}

	find(x) {
		// Path compression — flattens the tree as we look up.
		if (this.parent[x] !== x) this.parent[x] = this.find(this.parent[x]);
		return this.parent[x];
	}

	union(a, b) {
		const ra = this.find(a);
		const rb = this.find(b);
		if (ra === rb) return false; // already connected → would create a cycle

		// Union by rank — attach the shorter tree under the taller one.
		if (this.rank[ra] < this.rank[rb]) this.parent[ra] = rb;
		else if (this.rank[ra] > this.rank[rb]) this.parent[rb] = ra;
		else {
			this.parent[rb] = ra;
			this.rank[ra]++;
		}
		return true;
	}
}

// ---------------------------------------------------------------------------
// 2. Min-Heap (binary heap) keyed by edge weight. Used by Prim.
//    Time: O(log n) push/pop   Space: O(n)
// ---------------------------------------------------------------------------
class MinHeap {
	constructor() {
		this.data = [];
	}

	push(item) {
		this.data.push(item);
		this._bubbleUp(this.data.length - 1);
	}

	pop() {
		if (this.data.length === 0) return undefined;
		const top = this.data[0];
		const last = this.data.pop();
		if (this.data.length > 0) {
			this.data[0] = last;
			this._sinkDown(0);
		}
		return top;
	}

	get size() {
		return this.data.length;
	}

	_bubbleUp(i) {
		while (i > 0) {
			const parent = (i - 1) >> 1;
			if (this.data[i].weight < this.data[parent].weight) {
				[this.data[i], this.data[parent]] = [this.data[parent], this.data[i]];
				i = parent;
			} else break;
		}
	}

	_sinkDown(i) {
		const n = this.data.length;
		while (true) {
			const l = i * 2 + 1;
			const r = i * 2 + 2;
			let smallest = i;
			if (l < n && this.data[l].weight < this.data[smallest].weight) smallest = l;
			if (r < n && this.data[r].weight < this.data[smallest].weight) smallest = r;
			if (smallest === i) break;
			[this.data[i], this.data[smallest]] = [this.data[smallest], this.data[i]];
			i = smallest;
		}
	}
}

// ---------------------------------------------------------------------------
// 3. Graph — supports adding nodes and weighted edges dynamically.
// ---------------------------------------------------------------------------
class Graph {
	constructor() {
		this.nodes = new Map();   // name → index
		this.names = [];          // index → name
		this.adj = [];            // adjacency list: adj[i] = [{ to, weight }, ...]
		this.edges = [];          // edge list:      [{ u, v, weight }, ...]
	}

	addNode(name) {
		if (this.nodes.has(name)) return this.nodes.get(name);
		const idx = this.names.length;
		this.nodes.set(name, idx);
		this.names.push(name);
		this.adj.push([]);
		return idx;
	}

	addEdge(a, b, weight) {
		const u = this.addNode(a);
		const v = this.addNode(b);
		this.adj[u].push({ to: v, weight });
		this.adj[v].push({ to: u, weight });
		this.edges.push({ u, v, weight });
	}

	get size() {
		return this.names.length;
	}
}

// ---------------------------------------------------------------------------
// 4. Kruskal's algorithm — sort all edges, add the cheapest that doesn't
//    create a cycle (checked with Union-Find). Stops at n-1 edges.
//    Time:  O(E log E)   Space: O(V + E)
// ---------------------------------------------------------------------------
function kruskalMST(graph) {
	const sorted = [...graph.edges].sort((a, b) => a.weight - b.weight);
	const dsu = new DisjointSet(graph.size);
	const picked = [];
	let total = 0;

	for (const edge of sorted) {
		if (dsu.union(edge.u, edge.v)) {
			picked.push(edge);
			total += edge.weight;
			if (picked.length === graph.size - 1) break;
		}
	}

	// If the graph is disconnected we cannot span every computer.
	const connected = picked.length === graph.size - 1;
	return { edges: picked, total, connected };
}

// ---------------------------------------------------------------------------
// 5. Prim's algorithm — start from any node, repeatedly grow the tree by
//    pulling the cheapest edge that reaches an unvisited node from a
//    min-heap.
//    Time:  O(E log V)   Space: O(V + E)
// ---------------------------------------------------------------------------
function primMST(graph, startName) {
	if (graph.size === 0) return { edges: [], total: 0, connected: true };

	const start = startName !== undefined ? graph.nodes.get(startName) : 0;
	const visited = new Array(graph.size).fill(false);
	const heap = new MinHeap();
	const picked = [];
	let total = 0;

	visited[start] = true;
	for (const { to, weight } of graph.adj[start]) {
		heap.push({ from: start, to, weight });
	}

	while (heap.size > 0 && picked.length < graph.size - 1) {
		const { from, to, weight } = heap.pop();
		if (visited[to]) continue; // skip — would create a cycle

		visited[to] = true;
		picked.push({ u: from, v: to, weight });
		total += weight;

		for (const next of graph.adj[to]) {
			if (!visited[next.to]) heap.push({ from: to, to: next.to, weight: next.weight });
		}
	}

	const connected = picked.length === graph.size - 1;
	return { edges: picked, total, connected };
}

// ---------------------------------------------------------------------------
// 6. Pretty-printer for the MST result.
// ---------------------------------------------------------------------------
function printResult(label, graph, result) {
	console.log(`\n--- ${label} ---`);
	if (!result.connected) {
		console.log("Graph is NOT fully connected — no spanning tree exists.");
		return;
	}
	for (const e of result.edges) {
		console.log(`  ${graph.names[e.u]} -- ${graph.names[e.v]}   (cost ${e.weight})`);
	}
	console.log(`  Total cost: ${result.total}`);
}

// ---------------------------------------------------------------------------
// 7. Timing helper.
// ---------------------------------------------------------------------------
function time(label, fn) {
	const t0 = process.hrtime.bigint();
	const result = fn();
	const t1 = process.hrtime.bigint();
	const ms = Number(t1 - t0) / 1e6;
	console.log(`${label.padEnd(34)} cost=${String(result.total).padStart(7)}   in  ${ms.toFixed(3)} ms`);
	return result;
}

// ---------------------------------------------------------------------------
// 8. Demo — office layout from the brief.
//    6 computers, 9 candidate cable runs.
// ---------------------------------------------------------------------------
const office = new Graph();
const officeEdges = [
	["PC1", "PC2", 4],
	["PC1", "PC3", 3],
	["PC2", "PC3", 1],
	["PC2", "PC4", 2],
	["PC3", "PC4", 4],
	["PC3", "PC5", 5],
	["PC4", "PC5", 7],
	["PC4", "PC6", 6],
	["PC5", "PC6", 2],
];
for (const [a, b, w] of officeEdges) office.addEdge(a, b, w);

console.log("=== Office network (6 computers, 9 candidate cables) ===");
const kOffice = kruskalMST(office);
const pOffice = primMST(office, "PC1");
printResult("Kruskal MST", office, kOffice);
printResult("Prim MST (start = PC1)", office, pOffice);
console.log(
	"\nSame total cost?",
	kOffice.total === pOffice.total ? "YES" : "NO",
	`(kruskal=${kOffice.total}, prim=${pOffice.total})`
);

// ---------------------------------------------------------------------------
// 9. Bonus — dynamic node/edge addition.
//    Simulates an operator extending the office network at runtime.
// ---------------------------------------------------------------------------
console.log("\n=== Dynamic extension — adding PC7 and PC8 ===");
office.addEdge("PC6", "PC7", 3);
office.addEdge("PC5", "PC7", 4);
office.addEdge("PC7", "PC8", 1);
office.addEdge("PC4", "PC8", 9);

const kExtended = kruskalMST(office);
const pExtended = primMST(office, "PC1");
printResult("Kruskal MST (extended)", office, kExtended);
printResult("Prim MST (extended)", office, pExtended);

// ---------------------------------------------------------------------------
// 10. Benchmark — a dense random graph (V = 500, ~12 500 edges).
// ---------------------------------------------------------------------------
console.log("\n=== Benchmark — random graph V=500, E≈12500 ===");

function randomGraph(v, e) {
	const g = new Graph();
	for (let i = 0; i < v; i++) g.addNode(`N${i}`);
	// Spine to guarantee the graph is connected.
	for (let i = 1; i < v; i++) g.addEdge(`N${i - 1}`, `N${i}`, 1 + Math.floor(Math.random() * 100));
	let extra = e - (v - 1);
	while (extra-- > 0) {
		const a = Math.floor(Math.random() * v);
		let b = Math.floor(Math.random() * v);
		if (a === b) b = (b + 1) % v;
		g.addEdge(`N${a}`, `N${b}`, 1 + Math.floor(Math.random() * 100));
	}
	return g;
}

const big = randomGraph(500, 12500);
time("Kruskal (V=500, E=12500)", () => kruskalMST(big));
time("Prim    (V=500, E=12500)", () => primMST(big));

// ---------------------------------------------------------------------------
// 11. Edge cases.
// ---------------------------------------------------------------------------
console.log("\n=== Edge cases ===");

// (a) Single node — MST cost should be 0, no edges.
const single = new Graph();
single.addNode("only");
console.log("Single node          kruskal:", kruskalMST(single));
console.log("Single node          prim:   ", primMST(single, "only"));

// (b) Disconnected graph — no spanning tree exists.
const disjoint = new Graph();
disjoint.addEdge("A", "B", 1);
disjoint.addEdge("C", "D", 2);
console.log("Disconnected         kruskal:", kruskalMST(disjoint));
console.log("Disconnected         prim:   ", primMST(disjoint, "A"));

// (c) Parallel edges with different weights — MST must pick the cheapest.
const parallel = new Graph();
parallel.addEdge("X", "Y", 9);
parallel.addEdge("X", "Y", 2);
parallel.addEdge("X", "Y", 5);
console.log("Parallel edges       kruskal:", kruskalMST(parallel));
console.log("Parallel edges       prim:   ", primMST(parallel, "X"));

// (d) Equal-weight cycle — any 2 of the 3 edges form a valid MST; total must match.
const cycle = new Graph();
cycle.addEdge("A", "B", 5);
cycle.addEdge("B", "C", 5);
cycle.addEdge("C", "A", 5);
const kCycle = kruskalMST(cycle);
const pCycle = primMST(cycle, "A");
console.log("Equal-weight cycle   kruskal total:", kCycle.total, " prim total:", pCycle.total);
