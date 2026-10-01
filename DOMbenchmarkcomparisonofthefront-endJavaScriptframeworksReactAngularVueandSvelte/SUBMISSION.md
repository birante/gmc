# Submission - DOM benchmark of React, Angular, Vue and Svelte

## Deliverables

| Deliverable | Where |
|---|---|
| To-do app - React 19 (Vite) | [`react/`](react/) |
| To-do app - Angular 21 (CLI, standalone, `@for`/`@if`, `[(ngModel)]`) | [`angular/`](angular/) |
| To-do app - Vue 3 (Vite) | [`vue/`](vue/) |
| To-do app - Svelte 5 (Vite) | [`svelte/`](svelte/) |
| Benchmark harness (Puppeteer + Chrome for Testing) | [`benchmark/run.mjs`](benchmark/run.mjs), [`benchmark/report.mjs`](benchmark/report.mjs) |
| Benchmark results (table / chart) | [`benchmark/results/results.md`](benchmark/results/results.md), [`results.json`](benchmark/results/results.json), [`chart.html`](benchmark/results/chart.html), [`chart.svg`](benchmark/results/chart.svg) |
| Reflection report (about 290 words) | [`REFLECTION.md`](REFLECTION.md) |
| How to run, methodology, full results | [`PROJECT_README.md`](PROJECT_README.md) |

All four apps let you add a task (name and priority), list tasks with their priority, edit the name or priority, and remove a task. They share the same stylesheet, the same data generator and the same DOM structure (ids and `data-testid`s). Benchmark buttons (`Render 100/500/1000`, `Update 50`, `Delete 50`, `Clear`) make the measurements reproducible by hand in DevTools as well.

## Results (median ms; click until the DOM is patched and laid out)

Apple M1 Pro, 16 GB RAM, macOS 27.0.1, headless Chrome for Testing 154, 15 runs after 5 warm-up runs.

| Operation | React | Angular | Vue | Svelte |
|---|---:|---:|---:|---:|
| Render 100 tasks | **4.80** | 5.00 | 5.60 | 5.40 |
| Render 500 tasks | **13.70** | 17.70 | 15.50 | 17.90 |
| Render 1000 tasks | **26.00** | 33.30 | 30.50 | 36.70 |
| Update 50 tasks (of 1000) | 1.90 | 2.10 | **1.70** | 1.80 |
| Delete 50 tasks (of 1000) | 1.90 | **1.60** | 2.70 | 2.70 |
| JS heap with 1000 tasks (MB) | **3.18** | 6.81 | 5.06 | 5.08 |
| JS bundle (KB gzip) | 67.3 | 51.5 | 26.1 | **16.2** |

## Reproduce

```bash
cd benchmark && npm install && npx puppeteer browsers install chrome && npm run bench
```
