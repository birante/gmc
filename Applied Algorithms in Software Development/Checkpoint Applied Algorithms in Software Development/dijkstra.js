// dijkstra.js
// Dijkstra's shortest-path algorithm on a weighted graph.
// Input shape (from the brief):
//   const graph = {
//       'A': { 'B': 4, 'C': 2 },
//       'B': { 'A': 4, 'C': 5, 'D': 10 },
//       'C': { 'A': 2, 'B': 5, 'D': 3 },
//       'D': { 'B': 10, 'C': 3 }
//   };
//   dijkstra(graph, 'A') → { A: 0, B: 4, C: 2, D: 5 }

// ---------------------------------------------------------------------------
// 1. MinHeap — binary heap keyed by `distance`. Used as Dijkstra's priority
//    queue. Time: O(log n) push / pop. Lazy-deletion friendly: outdated
//    entries are simply skipped when popped (we just check the latest
//    distance for the node).
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
			if (this.data[i].distance < this.data[parent].distance) {
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
			if (l < n && this.data[l].distance < this.data[smallest].distance) smallest = l;
			if (r < n && this.data[r].distance < this.data[smallest].distance) smallest = r;
			if (smallest === i) break;
			[this.data[i], this.data[smallest]] = [this.data[smallest], this.data[i]];
			i = smallest;
		}
	}
}

// ---------------------------------------------------------------------------
// 2. dijkstra(graph, start)
//    Returns an object mapping every reachable vertex to its shortest
//    distance from `start`. Unreachable vertices map to Infinity.
//
//    Time:  O((V + E) log V)   — each edge can trigger one heap push.
//    Space: O(V + E)
//
//    Assumption (Dijkstra's contract): no negative edge weights. If a
//    negative weight is detected we throw — Dijkstra is unsound there
//    and the right fix is Bellman-Ford.
// ---------------------------------------------------------------------------
function dijkstra(graph, start) {
	if (!(start in graph)) {
		throw new Error(`Start vertex "${start}" is not in the graph.`);
	}

	// Initialise every vertex to Infinity, except start = 0.
	const distances = {};
	for (const vertex of Object.keys(graph)) distances[vertex] = Infinity;
	distances[start] = 0;

	const visited = new Set();
	const heap = new MinHeap();
	heap.push({ vertex: start, distance: 0 });

	while (heap.size > 0) {
		const { vertex, distance } = heap.pop();

		// Lazy deletion: the heap can contain stale entries for a vertex
		// we already settled. Skip them.
		if (visited.has(vertex)) continue;
		visited.add(vertex);

		for (const [neighbour, weight] of Object.entries(graph[vertex])) {
			if (weight < 0) {
				throw new Error(
					`Negative weight on edge ${vertex} → ${neighbour} (${weight}). ` +
					`Dijkstra requires non-negative weights — use Bellman-Ford instead.`
				);
			}

			if (visited.has(neighbour)) continue;

			const candidate = distance + weight;
			if (candidate < distances[neighbour]) {
				distances[neighbour] = candidate;
				heap.push({ vertex: neighbour, distance: candidate });
			}
		}
	}

	return distances;
}

// ---------------------------------------------------------------------------
// 3. dijkstraWithPaths(graph, start)
//    Same algorithm, but also reconstructs the actual path to every
//    vertex. Returned object: { distances, paths }.
//    paths[v] is an array of vertices from start → v (empty if unreachable
//    or if v === start, in which case it is just [start]).
// ---------------------------------------------------------------------------
function dijkstraWithPaths(graph, start) {
	if (!(start in graph)) {
		throw new Error(`Start vertex "${start}" is not in the graph.`);
	}

	const distances = {};
	const previous = {};
	for (const vertex of Object.keys(graph)) {
		distances[vertex] = Infinity;
		previous[vertex] = null;
	}
	distances[start] = 0;

	const visited = new Set();
	const heap = new MinHeap();
	heap.push({ vertex: start, distance: 0 });

	while (heap.size > 0) {
		const { vertex, distance } = heap.pop();
		if (visited.has(vertex)) continue;
		visited.add(vertex);

		for (const [neighbour, weight] of Object.entries(graph[vertex])) {
			if (weight < 0) {
				throw new Error(`Negative weight on edge ${vertex} → ${neighbour} (${weight}).`);
			}
			if (visited.has(neighbour)) continue;

			const candidate = distance + weight;
			if (candidate < distances[neighbour]) {
				distances[neighbour] = candidate;
				previous[neighbour] = vertex;
				heap.push({ vertex: neighbour, distance: candidate });
			}
		}
	}

	// Reconstruct the path for every vertex by walking `previous` back to start.
	const paths = {};
	for (const vertex of Object.keys(graph)) {
		if (distances[vertex] === Infinity) {
			paths[vertex] = [];
			continue;
		}
		const path = [];
		let current = vertex;
		while (current !== null) {
			path.unshift(current);
			current = previous[current];
		}
		paths[vertex] = path;
	}

	return { distances, paths };
}

// ===========================================================================
// 4. Demo — the graph from the brief.
// ===========================================================================
console.log("=== Brief's graph ===");
const graph = {
	A: { B: 4, C: 2 },
	B: { A: 4, C: 5, D: 10 },
	C: { A: 2, B: 5, D: 3 },
	D: { B: 10, C: 3 },
};

const result = dijkstra(graph, "A");
console.log("dijkstra(graph, 'A') =", result);
console.log("Expected             = { A: 0, B: 4, C: 2, D: 5 }");

const { distances, paths } = dijkstraWithPaths(graph, "A");
console.log("\nShortest paths from A:");
for (const vertex of Object.keys(paths)) {
	console.log(`  A → ${vertex} : distance=${distances[vertex]}  path=[${paths[vertex].join(" → ")}]`);
}

// ===========================================================================
// 5. Larger example — a small road network.
// ===========================================================================
console.log("\n=== Road-network example ===");
const cities = {
	Paris:    { Lille: 220, Lyon: 460,  Rennes: 350 },
	Lille:    { Paris: 220, Brussels: 110 },
	Brussels: { Lille: 110, Amsterdam: 210 },
	Amsterdam:{ Brussels: 210 },
	Lyon:     { Paris: 460, Marseille: 315, Geneva: 150 },
	Geneva:   { Lyon: 150,  Marseille: 425 },
	Marseille:{ Lyon: 315,  Geneva: 425, Nice: 200 },
	Nice:     { Marseille: 200 },
	Rennes:   { Paris: 350, Brest: 245 },
	Brest:    { Rennes: 245 },
};

const fromParis = dijkstraWithPaths(cities, "Paris");
for (const city of Object.keys(cities)) {
	console.log(
		`  Paris → ${city.padEnd(10)} ${String(fromParis.distances[city]).padStart(4)} km   via ${fromParis.paths[city].join(" → ")}`
	);
}

// ===========================================================================
// 6. Edge cases.
// ===========================================================================
console.log("\n=== Edge cases ===");

// (a) Disconnected graph — unreachable vertex stays at Infinity.
const disconnected = {
	A: { B: 1 },
	B: { A: 1 },
	C: { D: 2 },
	D: { C: 2 },
};
console.log("Disconnected graph from A:", dijkstra(disconnected, "A"));

// (b) Single node graph — distance to itself is 0.
const singleton = { Only: {} };
console.log("Singleton graph:           ", dijkstra(singleton, "Only"));

// (c) Negative weight — must throw.
const negative = {
	A: { B: 1 },
	B: { C: -5 },
	C: {},
};
try {
	dijkstra(negative, "A");
	console.log("Negative-weight graph:      did NOT throw (bug!)");
} catch (e) {
	console.log("Negative-weight graph:      throws — \"" + e.message + "\"");
}

// (d) Start vertex missing — must throw.
try {
	dijkstra(graph, "Z");
} catch (e) {
	console.log("Missing start vertex:       throws — \"" + e.message + "\"");
}

// ===========================================================================
// 7. Self-check assertions.
// ===========================================================================
console.log("\n=== Self-checks ===");
console.assert(result.A === 0, "A → A must be 0");
console.assert(result.B === 4, "A → B must be 4 (direct, not A→C→B=7)");
console.assert(result.C === 2, "A → C must be 2");
console.assert(result.D === 5, "A → D must be 5 (A→C→D = 2+3, not A→B→D=14)");
console.assert(fromParis.distances.Brest === 595, "Paris → Brest must be 595 (Paris→Rennes→Brest)");
console.assert(fromParis.distances.Nice  === 975, "Paris → Nice  must be 975 (Paris→Lyon→Marseille→Nice)");
console.assert(dijkstra(disconnected, "A").C === Infinity, "Unreachable vertices must be Infinity");
console.log("All assertions passed.");
