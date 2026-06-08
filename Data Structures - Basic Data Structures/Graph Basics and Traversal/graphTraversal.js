const readline = require("readline");

class Graph {
	constructor(directed = false) {
		this.directed = directed;
		this.adj = new Map();
	}

	addVertex(v) {
		if (!this.adj.has(v)) this.adj.set(v, new Set());
	}

	addEdge(u, v) {
		this.addVertex(u);
		this.addVertex(v);
		this.adj.get(u).add(v);
		if (!this.directed) this.adj.get(v).add(u);
	}

	removeEdge(u, v) {
		if (this.adj.has(u)) this.adj.get(u).delete(v);
		if (!this.directed && this.adj.has(v)) this.adj.get(v).delete(u);
	}

	hasEdge(u, v) {
		return this.adj.has(u) && this.adj.get(u).has(v);
	}

	print() {
		if (this.adj.size === 0) {
			console.log("(empty graph)");
			return;
		}
		for (const [v, neighbors] of this.adj) {
			console.log(`${v} -> ${[...neighbors].join(", ") || "(none)"}`);
		}
	}

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
