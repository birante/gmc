# Network Cable Optimization

This is a module/checkpoint folder.
It stores files used for this part of the repository.

## Overview
Two implementations of the Minimum Spanning Tree problem in JavaScript —
**Kruskal's algorithm** (`O(E log E)`, Union-Find for cycle detection) and
**Prim's algorithm** (`O(E log V)`, min-heap for picking the next cheapest
edge) — applied to laying out network cables across an office. The file
includes a 6-computer demo, a dynamic-extension bonus that adds nodes at
runtime, a benchmark on a 500-vertex / 12 500-edge random graph, and edge
cases (single node, disconnected graph, parallel edges, equal-weight cycle).

## Contents
- networkCable.js — runnable JavaScript implementation, benchmark, and stress tests.
- projet.md — full description, code walkthrough, measurements, and comparison.

## How to Run
```bash
node networkCable.js
```

## Notes
Keep this folder aligned with project naming and structure rules.
