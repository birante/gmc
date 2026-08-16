# How to benchmark this fairly

Two runners hitting the same GTFS feed with the same query mix, on the
same host. Any published numbers are only meaningful if every knob is
declared.

## Setup — declared per run

| Knob                    | Value                                          |
| ----------------------- | ---------------------------------------------- |
| Feed                    | e.g. IDFM Paris — commit N + row counts        |
| Host CPU / RAM / disk   | e.g. Apple M2 Pro, 32 GB, NVMe                 |
| Redis version           | e.g. 7.4, persistence: RDB every 5 min         |
| MongoDB version         | e.g. 7.0, WiredTiger cache = 4 GB              |
| Driver + version        | `ioredis 5.4.1`, `mongodb 6.7.0`               |
| Cold vs warm            | Discard first 10s of each run                  |
| Concurrency             | 1, 10, 50, 200 concurrent clients              |
| Duration                | ≥ 60s per (query, concurrency) point           |

## The five queries

| Query                                                                              | Frequency in real traffic |
| ---------------------------------------------------------------------------------- | ------------------------: |
| Q1 — Next 5 departures from a hot stop after `now`                                 |                       50 % |
| Q2 — Stops within 400 m of a lat/lng                                               |                       20 % |
| Q3 — Full stop sequence of a specific trip                                         |                       10 % |
| Q4 — "From A to B after time T" (single-hop, no transfer)                          |                       15 % |
| Q5 — "Same but include one transfer" (multi-hop, hardest)                           |                        5 % |

Draw the input parameters from realistic distributions:

- Stop IDs weighted by patronage (Gare du Nord gets 100× a suburb stop).
- Times skewed to peak hours (07-09 and 17-19).
- Coordinates from a heat map of user origins.

## Metrics per query

- p50 / p95 / p99 latency (ms).
- Throughput ceiling (queries / sec at each concurrency point).
- Cache hit ratio (Redis) / index-only scan ratio (MongoDB).
- CPU / RAM per DB process during the run.

## Watch out for

- **Warm-up.** Mongo's WiredTiger cache and Redis's OS page cache both
  need ~30 s to reach steady state.
- **Client-side bottlenecks.** `ioredis` and `mongodb` are both async;
  a naive `for/await` will limit you to ~200 QPS. Use `Promise.all` or
  worker threads.
- **GC pauses on the driver side.** Preallocate arrays, avoid churn.
- **Same OS + same disk queue** — don't run Mongo on SSD and Redis on
  a snapshot mount, comparisons will be dishonest.
- **Same aggregation-pipeline vs same round-trip pattern.** Mongo's
  aggregation on a `$lookup` is fair only if Redis's equivalent is
  application-side joining (multiple round trips), which is what
  production code does.

## Expected result shape (rule of thumb)

For a feed like Paris IDF (~9 M stop_times rows) on a warm cache and a
reasonable machine:

| Query | Redis (p50 / p99) | MongoDB (p50 / p99) |
| ----: | :---------------: | :-----------------: |
| Q1    | 0.3 ms / 1 ms     | 3 ms / 15 ms        |
| Q2    | 0.8 ms / 3 ms     | 4 ms / 20 ms        |
| Q3    | 0.4 ms / 2 ms     | 5 ms / 25 ms        |
| Q4    | 5 ms / 30 ms (app-side) | 10 ms / 50 ms (aggregation) |
| Q5    | 30 ms / 200 ms (app-side, N round trips) | 25 ms / 120 ms (single aggregation) |

Redis wins the primitives 10× on average, MongoDB pulls back on
complex multi-step queries. If your query mix is Q1-heavy, you want
Redis. If Q4-Q5-heavy, MongoDB. If mixed, use both.

**Do not publish these numbers as fact** — they're indicative
orders-of-magnitude to know what shape of result to expect. Real runs
must produce the actual numbers.
