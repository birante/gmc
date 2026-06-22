# Checkpoint Applied Algorithms in Software Development

This is a module/checkpoint folder.
It stores files used for this part of the repository.

## Overview
A JavaScript implementation of **Dijkstra's shortest-path algorithm** using
a binary **min-heap** as the priority queue (`O((V + E) log V)`). The file
provides two entry points: `dijkstra(graph, start)` (distances only, matching
the brief's signature exactly) and `dijkstraWithPaths(graph, start)` (distances
plus reconstructed paths via a `previous` map). The demo runs the graph from
the brief, a small road-network example with 10 cities, and four edge cases
(disconnected graph, singleton, negative weight → throws, missing start →
throws), followed by `console.assert` self-checks.

## Contents
- dijkstra.js — runnable JavaScript implementation, demo, edge cases, self-checks.
- projet.md — full description, algorithm walkthrough, complexity, and sample output.

## How to Run
```bash
node dijkstra.js
```

## Notes
Keep this folder aligned with project naming and structure rules.
