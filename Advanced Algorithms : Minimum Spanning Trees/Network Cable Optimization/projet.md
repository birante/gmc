# Checkpoint: Network Cable Optimization

## Objective
Wire every computer in the office together with the **least total cable
length** and **no loops**. The set of computers + candidate cable runs is a
weighted undirected graph; the answer is a **Minimum Spanning Tree (MST)**.
Compare the two classical MST algorithms and pick one for the production
layout tool:

- **Kruskal** — sort all edges by weight, add the cheapest that doesn't
  create a cycle. Cycles are detected with a **Disjoint Set (Union-Find)**.
- **Prim** — start from any computer, repeatedly extend the connected tree
  with the cheapest edge that reaches an unvisited node. The next cheapest
  edge is pulled from a **min-heap (priority queue)**.

Each operation is annotated with **Big O** for both time and space.

## Idea

1. Represent the office as a `Graph` with an adjacency list (`adj[]`) for
   Prim and a flat edge list (`edges[]`) for Kruskal.
2. Implement both algorithms in the same file so we can validate that they
   return the **same total cost** on every input.
3. Print the picked edges and the total cost on the 6-computer office
   layout from the brief.
4. **Bonus** — add PC7 and PC8 (plus their cables) dynamically at runtime
   and rebuild the MST, showing that the data structure supports operator
   edits without rebuilding the graph from scratch.
5. Benchmark both algorithms on a dense random graph (V = 500, E ≈ 12 500)
   with `process.hrtime.bigint()`.
6. Stress-test on four edge cases: **single node**, **disconnected graph**,
   **parallel edges of different weight**, **equal-weight cycle**.

## JavaScript Implementation

```js
// Kruskal — O(E log E) time, O(V + E) space
function kruskalMST(graph) {
    const sorted = [...graph.edges].sort((a, b) => a.weight - b.weight);
    const dsu = new DisjointSet(graph.size);
    const picked = [];
    let total = 0;

    for (const edge of sorted) {
        if (dsu.union(edge.u, edge.v)) {       // false → would create a cycle
            picked.push(edge);
            total += edge.weight;
            if (picked.length === graph.size - 1) break;
        }
    }

    const connected = picked.length === graph.size - 1;
    return { edges: picked, total, connected };
}

// Prim — O(E log V) time, O(V + E) space
function primMST(graph, startName) {
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
        if (visited[to]) continue;             // skip — would create a cycle

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
```

The full file (`networkCable.js`) also includes the `DisjointSet`, the
binary `MinHeap`, the `Graph` class with `addNode` / `addEdge`, a random
graph generator, a timing helper, and the edge-case stress tests.

## How to Run

```bash
node networkCable.js
```

## Sample Validation

Office layout from the brief (6 computers, 9 candidate cables):

```js
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
```

Both algorithms return the **same total cost of 13** (same tree, just
discovered in different orders):

```
Kruskal:                      Prim (start = PC1):
  PC2 -- PC3   (cost 1)         PC1 -- PC3   (cost 3)
  PC2 -- PC4   (cost 2)         PC3 -- PC2   (cost 1)
  PC5 -- PC6   (cost 2)         PC2 -- PC4   (cost 2)
  PC1 -- PC3   (cost 3)         PC3 -- PC5   (cost 5)
  PC3 -- PC5   (cost 5)         PC5 -- PC6   (cost 2)
  Total cost: 13                Total cost: 13
```

## Bonus — Dynamic Extension

The operator adds **PC7** and **PC8** plus four new cables at runtime:

```js
office.addEdge("PC6", "PC7", 3);
office.addEdge("PC5", "PC7", 4);
office.addEdge("PC7", "PC8", 1);
office.addEdge("PC4", "PC8", 9);
```

Rebuilding the MST returns:

```
PC2 -- PC3 (1)   PC7 -- PC8 (1)   PC2 -- PC4 (2)   PC5 -- PC6 (2)
PC1 -- PC3 (3)   PC6 -- PC7 (3)   PC3 -- PC5 (5)   Total cost: 17
```

`Graph.addNode` / `Graph.addEdge` keep the adjacency list and edge list in
sync, so adding new computers does not require rebuilding the graph from
scratch.

## Measured Benchmark

| Input                              | Kruskal | Prim    |
|------------------------------------|---------|---------|
| Office (V = 6, E = 9)              | < 1 ms  | < 1 ms  |
| Random dense graph (V = 500, E ≈ 12500) | ~3.7 ms | ~13.3 ms |

Both algorithms return the **same total cost (1489)** on the random graph,
which is the cross-check we expect — Kruskal and Prim must always agree on
the MST weight, even when they pick different equally-good edges.

On this dense graph Kruskal is faster because its hot path is a single
`Array.sort` (V8 TimSort, very well optimised) followed by linear-time
Union-Find. Prim spends most of its time on heap operations, and a binary
heap pays `O(log V)` per `push` / `pop` even when the next edge would have
been cheap to find.

## Edge Cases

| Case                          | Kruskal cost | Prim cost | Notes                                        |
|-------------------------------|--------------|-----------|----------------------------------------------|
| Single node                   | 0            | 0         | No edges needed; trivially a spanning tree.  |
| Disconnected graph            | n/a          | n/a       | Both flag `connected: false` — no MST exists. |
| Parallel edges (9, 2, 5)      | 2            | 2         | Both pick the cheapest of the parallels.     |
| Equal-weight triangle (5,5,5) | 10           | 10        | Any 2 of the 3 edges are a valid MST.        |

`connected: false` is the important contract: if the input graph is split
into islands, there is no spanning tree, and both algorithms report that
explicitly instead of silently returning a forest.

## Comparison

**Which is faster for the office problem and why?**
For the 6-computer brief, the answer is "either" — both finish in
microseconds. The picture changes with graph density:

- **Sparse graphs** (`E ≈ V`): Prim with a binary heap is `O(E log V) ≈ O(V log V)`,
  which can edge out Kruskal because Kruskal still has to sort the full
  edge list up front.
- **Dense graphs** (`E ≈ V²`, our benchmark): Kruskal wins. Sorting 12 500
  edges with V8's built-in sort is faster than 12 500 heap pushes plus
  12 500 heap pops in JS-land.

**Which is easier to maintain and extend?**
Kruskal. The whole algorithm is "sort the edges, walk the list, ask
Union-Find before adding". Prim needs a heap *and* a visited-set *and*
careful "skip if already visited" handling on every pop, because the same
node can be inserted into the heap multiple times before it is finally
picked.

Kruskal also generalises well: as soon as you need things like "merge two
already-connected sub-networks", Union-Find is already the right primitive.

**Memory trade-offs.**
- Kruskal: O(E) for the sorted copy + O(V) for Union-Find.
- Prim: O(V) for `visited` + O(E) worst-case in the heap (each edge can be
  pushed once from each endpoint).

In practice both are O(V + E); neither is a winner here.

**Where does each shine?**
- Kruskal — when edges are already (or easily) sorted, when the graph is
  given as an edge list, or when you also need cycle / connectivity
  queries (Union-Find gives them for free).
- Prim — when the graph is given as an adjacency list, when V is small but
  E is huge (a Fibonacci-heap implementation drops Prim to `O(E + V log V)`),
  or when you want to grow the tree incrementally from a specific root.

## Recommendation

**Use Kruskal as the default for the office cable planner.**

The cable layout is naturally an **edge list** — "cable from PC2 to PC3
costs 1 m" — which is exactly Kruskal's input format. Union-Find also
answers the operator's most common follow-up question for free: *"are
these two computers already on the same sub-network?"* — a single `find()`
call.

Keep Prim available for two narrow situations:
- **Very dense graphs with small V** — a Fibonacci-heap Prim is
  asymptotically faster than Kruskal, and worth the extra complexity if
  the office ever grows to "every pair of computers is a candidate cable".
- **Incremental planning** — Prim grows the tree from a chosen root, so
  it's natural for "start from the server room and add the next-cheapest
  reachable computer one at a time" UX.

In both algorithms the connectivity check matters: if the graph is split
into islands, no MST exists, so the API returns `connected: false` rather
than a misleading partial result.

## Complexity Summary

| Algorithm | Time          | Space   | Cycle detection | Optimal? |
|-----------|---------------|---------|-----------------|----------|
| Kruskal   | O(E log E)    | O(V+E)  | Union-Find      | Yes      |
| Prim      | O(E log V)    | O(V+E)  | Visited set     | Yes      |
