# Checkpoint: Graph Basics and Traversal

## Objective
Build a simple graph in JavaScript that combines:

- An **adjacency list** (`Map` of `Set`) to store vertices and edges.
- **Edge operations**: add, remove, check, print.
- **BFS** (Breadth-First Search) and **DFS** (Depth-First Search) traversals.
- Support for both **directed** and **undirected** graphs.
- A **text menu** to interact with the system in the terminal.

## Idea

1. Define a `Graph` class with a `directed` flag and an `adj` map.
2. Each key in `adj` is a vertex; the value is a `Set` of neighbors.
   - `Set` prevents duplicate edges and gives O(1) edge checks.
3. When the graph is **undirected**, every edge is stored in both directions.
4. BFS uses a **queue** and visits neighbors level by level.
5. DFS uses **recursion** and goes as deep as possible before backtracking.
6. The menu loops with `readline` and dispatches on the chosen option.

## JavaScript Implementation

```js
// graphTraversal.js
const readline = require("readline");

// 1. Graph class (adjacency list)
class Graph {
	constructor(directed = false) {
		this.directed = directed;
		this.adj = new Map(); // vertex -> Set of neighbors
	}

	addVertex(v) {
		if (!this.adj.has(v)) this.adj.set(v, new Set());
	}

	// 2. Add edge (handles directed / undirected)
	addEdge(u, v) {
		this.addVertex(u);
		this.addVertex(v);
		this.adj.get(u).add(v);
		if (!this.directed) this.adj.get(v).add(u);
	}

	// 3. Remove edge
	removeEdge(u, v) {
		if (this.adj.has(u)) this.adj.get(u).delete(v);
		if (!this.directed && this.adj.has(v)) this.adj.get(v).delete(u);
	}

	// 4. Check edge
	hasEdge(u, v) {
		return this.adj.has(u) && this.adj.get(u).has(v);
	}

	// 5. Print graph (adjacency list)
	print() {
		if (this.adj.size === 0) {
			console.log("(empty graph)");
			return;
		}
		for (const [v, neighbors] of this.adj) {
			console.log(`${v} -> ${[...neighbors].join(", ") || "(none)"}`);
		}
	}

	// 6. BFS traversal
	bfs(start) {
		if (!this.adj.has(start)) {
			console.log(`Vertex "${start}" is not in the graph.`);
			return [];
		}
		const visited = new Set([start]);
		const queue = [start];
		const order = [];
		while (queue.length) {
			const v = queue.shift();
			order.push(v);
			for (const n of this.adj.get(v)) {
				if (!visited.has(n)) {
					visited.add(n);
					queue.push(n);
				}
			}
		}
		return order;
	}

	// 7. DFS traversal (recursive)
	dfs(start) {
		if (!this.adj.has(start)) {
			console.log(`Vertex "${start}" is not in the graph.`);
			return [];
		}
		const visited = new Set();
		const order = [];
		const walk = (v) => {
			visited.add(v);
			order.push(v);
			for (const n of this.adj.get(v)) {
				if (!visited.has(n)) walk(n);
			}
		};
		walk(start);
		return order;
	}
}

// 8. Text menu
const rl = readline.createInterface({
	input: process.stdin,
	output: process.stdout,
});

const ask = (q) => new Promise((resolve) => rl.question(q, resolve));

async function main() {
	const mode = (await ask("Directed graph? (y/N): ")).trim().toLowerCase();
	const graph = new Graph(mode === "y");

	while (true) {
		console.log(`
1. Add Edge
2. Remove Edge
3. Check Edge
4. Print Graph
5. BFS Traversal
6. DFS Traversal
7. Exit
`);
		const option = (await ask("Enter option: ")).trim();

		if (option === "1") {
			const u = (await ask("From vertex: ")).trim();
			const v = (await ask("To vertex: ")).trim();
			graph.addEdge(u, v);
			console.log(`Edge ${u} -> ${v} added.`);
		} else if (option === "2") {
			const u = (await ask("From vertex: ")).trim();
			const v = (await ask("To vertex: ")).trim();
			graph.removeEdge(u, v);
			console.log(`Edge ${u} -> ${v} removed.`);
		} else if (option === "3") {
			const u = (await ask("From vertex: ")).trim();
			const v = (await ask("To vertex: ")).trim();
			console.log(graph.hasEdge(u, v) ? "Edge exists." : "No edge.");
		} else if (option === "4") {
			graph.print();
		} else if (option === "5") {
			const start = (await ask("Start vertex: ")).trim();
			const order = graph.bfs(start);
			if (order.length) console.log(`BFS: ${order.join(" -> ")}`);
		} else if (option === "6") {
			const start = (await ask("Start vertex: ")).trim();
			const order = graph.dfs(start);
			if (order.length) console.log(`DFS: ${order.join(" -> ")}`);
		} else if (option === "7") {
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
node graphTraversal.js
```

## Example Session

Using the undirected graph below (4 vertices, edges `A-B`, `A-C`, `B-D`,
`C-D`):

```text
    A --- B
    |     |
    C --- D
```

```text
Directed graph? (y/N): n

1. Add Edge
2. Remove Edge
3. Check Edge
4. Print Graph
5. BFS Traversal
6. DFS Traversal
7. Exit

Enter option: 1
From vertex: A
To vertex: B
Edge A -> B added.

Enter option: 1
From vertex: A
To vertex: C
Edge A -> C added.

Enter option: 1
From vertex: B
To vertex: D
Edge B -> D added.

Enter option: 1
From vertex: C
To vertex: D
Edge C -> D added.

Enter option: 4
A -> B, C
B -> A, D
C -> A, D
D -> B, C

Enter option: 5
Start vertex: A
BFS: A -> B -> C -> D

Enter option: 6
Start vertex: A
DFS: A -> B -> D -> C
```

## Why This Matches the Instructions

1. **Graph class** with `addEdge`, `removeEdge`, `hasEdge`, and `print` —
   defined on the adjacency-list representation.
2. **DFS and BFS** traversals are implemented and return the visit order,
   which is printed by the menu.
3. **Directed and undirected** graphs are both supported via the `directed`
   flag, which decides whether the reverse edge is also stored.
4. **Tested with more than 3 vertices** (4 above), and both traversals start
   from the same vertex so results are easy to compare.
5. **JavaScript** implementation, single runnable file via `node`.

## Complexity

| Operation        | Structure used     | Time          |
|------------------|--------------------|---------------|
| Add edge         | Map + Set          | O(1)          |
| Remove edge      | Map + Set          | O(1)          |
| Check edge       | Map + Set          | O(1)          |
| Print graph      | Map iteration      | O(V + E)      |
| BFS traversal    | Queue + visited    | O(V + E)      |
| DFS traversal    | Recursion + Set    | O(V + E)      |

Where `V` is the number of vertices and `E` the number of edges.
