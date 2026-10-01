# Benchmark results

- Date: 2026-10-01T10:18:35.985Z
- Browser: Chrome/154.0.8037.57 (headless), Node v22.20.0
- Machine: Apple M1 Pro, 8 cores, 16 GB RAM, Darwin 27.0.0 (arm64)
- 15 measured iterations per operation after 5 warm-up iterations; memory: 5 fresh page loads
- Timing: update = performance.now() from button.click() until framework flush (setTimeout 0) + forced style/layout (offsetHeight); frame = until next rendered frame (rAF + setTimeout 0)
- Row DOM structure identical across frameworks: yes

## Update time per operation - median in ms (lower is better)

Click -> DOM patched -> style + layout done (primary metric). Best value in bold.

| Operation | React | Angular | Vue | Svelte |
|---|---:|---:|---:|---:|
| Render 100 tasks | **4.80** | 5.00 | 5.60 | 5.40 |
| Render 500 tasks | **13.70** | 17.70 | 15.50 | 17.90 |
| Render 1000 tasks | **26.00** | 33.30 | 30.50 | 36.70 |
| Update 50 tasks (of 1000) | 1.90 | 2.10 | **1.70** | 1.80 |
| Delete 50 tasks (of 1000) | 1.90 | **1.60** | 2.70 | 2.70 |

## Time per operation - mean ± standard deviation (min-max) in ms

| Operation | React | Angular | Vue | Svelte |
|---|---:|---:|---:|---:|
| Render 100 tasks | 4.57 ± 0.68 (3.00-5.40) | 5.07 ± 0.41 (4.60-6.00) | 5.54 ± 0.42 (4.40-6.00) | 5.39 ± 0.21 (5.10-5.80) |
| Render 500 tasks | 13.83 ± 0.51 (13.10-14.70) | 17.86 ± 0.56 (17.10-19.30) | 15.55 ± 0.52 (14.50-16.50) | 17.83 ± 0.70 (16.40-19.10) |
| Render 1000 tasks | 26.19 ± 0.67 (25.20-27.70) | 33.37 ± 0.57 (32.60-34.80) | 30.35 ± 0.66 (29.40-31.20) | 36.63 ± 0.61 (35.60-37.40) |
| Update 50 tasks (of 1000) | 1.97 ± 0.18 (1.80-2.30) | 2.12 ± 0.13 (1.90-2.30) | 1.65 ± 0.20 (1.30-1.90) | 1.79 ± 0.21 (1.40-2.10) |
| Delete 50 tasks (of 1000) | 1.97 ± 0.22 (1.60-2.30) | 1.57 ± 0.09 (1.40-1.70) | 2.72 ± 0.08 (2.60-2.90) | 2.77 ± 0.33 (2.40-3.40) |

## Click to next rendered frame - median in ms

Includes waiting for the next vsync (~16.7 ms frames at 60 Hz), so values cluster on frame boundaries.

| Operation | React | Angular | Vue | Svelte |
|---|---:|---:|---:|---:|
| Render 100 tasks | 17.70 | 17.60 | 18.20 | 17.90 |
| Render 500 tasks | 18.60 | 19.90 | 18.60 | 20.10 |
| Render 1000 tasks | 29.70 | 37.00 | 34.00 | 40.00 |
| Update 50 tasks (of 1000) | 18.00 | 18.10 | 18.50 | 18.00 |
| Delete 50 tasks (of 1000) | 19.90 | 20.30 | 20.10 | 19.90 |

## Memory - JS heap used after forced GC, median MB (lower is better)

| State | React | Angular | Vue | Svelte |
|---|---:|---:|---:|---:|
| App loaded (0 tasks) | 1.30 | 1.82 | 1.08 | 0.99 |
| 1000 tasks rendered | 3.18 | 6.81 | 5.06 | 5.08 |
| Delta for 1000 tasks | 1.88 | 4.99 | 3.98 | 4.09 |
| After update 50 + delete 50 | 3.39 | 6.59 | 4.93 | 4.95 |
| After clear | 2.01 | 2.46 | 1.63 | 1.37 |
| DOM nodes with 1000 tasks | 9079 | 11085 | 9083 | 11166 |

## Bundle size and versions

| Framework | Versions | JS raw (KB) | JS gzip (KB) |
|---|---|---:|---:|
| React | react 19.3.0, react-dom 19.3.0, vite 8.3.1 | 218.4 | 67.3 |
| Angular | @angular/core 21.2.25, vite 7.3.6, @angular/build 21.2.24 | 164.8 | 51.5 |
| Vue | vue 3.5.43, vite 8.3.1 | 67.8 | 26.1 |
| Svelte | svelte 5.57.1, vite 8.3.1 | 42.3 | 16.2 |
