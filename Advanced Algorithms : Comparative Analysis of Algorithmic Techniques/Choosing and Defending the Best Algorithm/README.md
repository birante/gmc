# Choosing and Defending the Best Algorithm

This is a module/checkpoint folder.
It stores files used for this part of the repository.

## Overview
Two implementations of the maximum non-overlapping delivery-tasks problem in
JavaScript — a brute-force subset search (`O(2^n * n)`) and a greedy
earliest-end-time selection (`O(n log n)`) — plus a benchmark on 10 000
random tasks and stress tests on edge cases (all overlapping, all disjoint,
same start time, same end time). The write-up compares both approaches and
recommends greedy for the real-time backend.

## Contents
- deliveryTasks.js — runnable JavaScript implementation, benchmark, and stress tests.
- projet.md — full description, code walkthrough, measurements, and the recommendation.

## How to Run
```bash
node deliveryTasks.js
```

## Notes
Keep this folder aligned with project naming and structure rules.
