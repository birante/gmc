# Designing a Simple OS Task Manager

Checkpoint on the four core OS mechanisms: **CPU scheduling**, **process synchronization**, **memory management (page replacement)**, and **disk scheduling**. Delivered as a single Markdown document — renders directly on GitHub, and can be exported to PDF (`Cmd/Ctrl+P → Save as PDF` from any Markdown-aware viewer) if the grader prefers that format. Diagrams use Mermaid.

Read the full analysis in [`analysis.md`](./analysis.md).

## Table of contents

| Part | Topic                      | Key result                                                       |
| ---- | -------------------------- | ---------------------------------------------------------------- |
| 1    | Process scheduling         | FCFS avg WT = 3.33; RR (q=2) avg WT = 3.33 — but RR is far more responsive (avg response time 1.0 vs 3.33). |
| 2    | Process synchronization    | Race condition without a lock — mutex enforces mutual exclusion around `counter++`. |
| 3    | Memory management          | Reference string `1,2,3,2,4,1,5` on 3 frames: FIFO = 6 faults, LRU = 6 faults (tie); optimal = 5. |
| 4    | Disk scheduling            | FCFS total head movement = 640; SSTF = 236. SSTF ≈ 2.7× less movement. |
