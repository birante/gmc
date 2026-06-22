# Checkpoint: Implementing Dijkstra's Algorithm in JavaScript

## Objective

Implement **Dijkstra's algorithm** in JavaScript to compute the shortest
path from a chosen start vertex to every other vertex of a weighted graph
with **non-negative** edge weights.

The brief specifies:

- Input shape: a plain object where each key is a vertex and the value is
  an object `{ neighbour: weight, ... }`.
- Function signature: `dijkstra(graph, start)`.
- Output shape: `{ vertex: shortestDistance, ... }`.

The classic four-city example from the brief must return:

```js
dijkstra({
   A: { B: 4, C: 2 },
   B: { A: 4, C: 5, D: 10 },
   C: { A: 2, B: 5, D: 3 },
   D: { B: 10, C: 3 }
}, 'A')
// → { A: 0, B: 4, C: 2, D: 5 }
```

## Idea

Dijkstra is a **greedy** algorithm. It maintains:

- A distance estimate for every vertex (`Infinity` initially, except the
  start which is `0`).
- A "settled" set of vertices whose shortest distance is now final.
- A priority queue (min-heap) of `(vertex, distance)` candidates.

At each step it pops the cheapest unsettled candidate, marks it settled,
and **relaxes** every outgoing edge — i.e. checks whether going through
this vertex gives a shorter route to a neighbour. If so, the neighbour's
distance is updated and a fresh entry is pushed onto the heap.

The greedy choice is sound because **edge weights are non-negative**:
once a vertex is popped with the smallest known distance, no later path
could be cheaper (any other route would have to detour through already-
known longer distances, then add a non-negative edge).

If a negative weight is encountered the algorithm is unsound — the right
tool is **Bellman-Ford**. This implementation **throws** in that case
rather than returning silently wrong distances.

## How to Run

```bash
node dijkstra.js
```

## JavaScript Implementation

```js
function dijkstra(graph, start) {
    if (!(start in graph)) {
        throw new Error(`Start vertex "${start}" is not in the graph.`);
    }

    const distances = {};
    for (const vertex of Object.keys(graph)) distances[vertex] = Infinity;
    distances[start] = 0;

    const visited = new Set();
    const heap = new MinHeap();
    heap.push({ vertex: start, distance: 0 });

    while (heap.size > 0) {
        const { vertex, distance } = heap.pop();

        // Lazy deletion: the heap may contain stale entries.
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
```

A separate `dijkstraWithPaths(graph, start)` adds a `previous` map so the
actual shortest path to each vertex can be reconstructed. The full
`MinHeap` (binary heap, `O(log n)` push/pop) is in `dijkstra.js`.

### About "lazy deletion"

A binary heap has no efficient `decrease-key` operation, so when a
shorter route to a vertex is found we simply **push a new entry** with
the better distance instead of updating the old one. When the old, stale
entry later bubbles to the top we recognise it (`visited.has(vertex)`)
and skip it. This keeps the code small without sacrificing correctness.

## Complexity

| Aspect            | Cost                          |
|-------------------|-------------------------------|
| Time              | `O((V + E) log V)`            |
| Space             | `O(V + E)`                    |
| Negative weights  | Not supported (throws)        |
| Best alternative  | Bellman-Ford for negatives    |

Every edge can trigger at most one heap push, and each push/pop is
`O(log V)`. The dominant cost is the relaxation step.

## Sample Validation — Brief's Graph

```
dijkstra(graph, 'A') = { A: 0, B: 4, C: 2, D: 5 }
Expected             = { A: 0, B: 4, C: 2, D: 5 }
```

`dijkstraWithPaths(graph, 'A')` confirms how each distance is reached:

```
A → A : distance=0  path=[A]
A → B : distance=4  path=[A → B]
A → C : distance=2  path=[A → C]
A → D : distance=5  path=[A → C → D]
```

Note `A → D = 5`, not `10`: Dijkstra correctly prefers the indirect
route `A → C → D (2 + 3)` over the direct edge `A → B → D (4 + 10)`.

## Real-World Example — Road Network

Ten cities, weighted by approximate driving distance (km). Starting from
Paris, the algorithm finds the shortest route to every other city:

```
Paris → Paris        0 km   via Paris
Paris → Lille      220 km   via Paris → Lille
Paris → Brussels   330 km   via Paris → Lille → Brussels
Paris → Amsterdam  540 km   via Paris → Lille → Brussels → Amsterdam
Paris → Lyon       460 km   via Paris → Lyon
Paris → Geneva     610 km   via Paris → Lyon → Geneva
Paris → Marseille  775 km   via Paris → Lyon → Marseille
Paris → Nice       975 km   via Paris → Lyon → Marseille → Nice
Paris → Rennes     350 km   via Paris → Rennes
Paris → Brest      595 km   via Paris → Rennes → Brest
```

`Paris → Geneva` correctly prefers `Lyon` over the direct
`Marseille → Geneva` edge (610 vs 1200 km), illustrating why a greedy
single-edge choice would fail and why Dijkstra has to relax through every
intermediate vertex.

## Edge Cases

| Case                                  | Behaviour                                                |
|---------------------------------------|----------------------------------------------------------|
| Disconnected vertex                   | Distance stays at `Infinity`                             |
| Singleton graph                       | `{ start: 0 }`                                           |
| Negative edge weight                  | **Throws** — Dijkstra is unsound; suggests Bellman-Ford  |
| Start vertex absent from graph        | **Throws** with a clear message                          |
| Multiple equal-length shortest paths  | Returns one of them (whichever the heap pops first)      |

## Why a Min-Heap (and not a plain array scan)?

The textbook "find the unvisited vertex with the smallest tentative
distance" can be done by linearly scanning the distance array — that's
`O(V)` per step, `O(V²)` overall. For dense graphs (`E ≈ V²`) that's fine
and even slightly faster than the heap-based version.

For **sparse** graphs (`E ≈ V`), which is the common case in road maps
and network topologies, a binary heap drops the total cost to
`O((V + E) log V)` — a meaningful win once `V` grows past a few hundred.

A Fibonacci heap would push this to `O(E + V log V)` theoretically, but
its constant factors are large enough that real implementations rarely
use it in JavaScript.

## Summary

| Function                       | Returns                                  | Use it for                                |
|--------------------------------|------------------------------------------|-------------------------------------------|
| `dijkstra(graph, start)`       | `{ vertex: distance, ... }`              | The exact shape the brief asks for        |
| `dijkstraWithPaths(graph, ...)`| `{ distances, paths }`                   | When the *route* matters, not just length |
