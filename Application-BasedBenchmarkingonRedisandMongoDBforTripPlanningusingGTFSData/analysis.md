# Redis vs MongoDB for GTFS Trip Planning — Analysis

---

## 1. Introduction to GTFS

### 1.1 What GTFS is

**GTFS** — the *General Transit Feed Specification* — is the de-facto
open standard for describing scheduled public transportation. It was
born at Portland's TriMet in 2005, adopted by Google Maps as its transit
data format, and is now published by thousands of transit agencies
worldwide (see [OpenMobilityData](https://openmobilitydata.org)).

A GTFS feed is a ZIP archive of CSV files. The core files:

| File                    | Purpose                                                              |
| ----------------------- | -------------------------------------------------------------------- |
| `agency.txt`            | The transit agency operating the service                             |
| `stops.txt`             | Physical stops / stations with lat/lng                               |
| `routes.txt`            | A route is a family of trips serving the same corridor (e.g. "Bus 33")|
| `trips.txt`             | A specific run of a route on a specific service day                  |
| `stop_times.txt`        | The **largest** file — one row per (trip, stop, sequence), with arrival/departure times |
| `calendar.txt`          | Which days of the week a service pattern is active                   |
| `calendar_dates.txt`    | Exceptions to the calendar (holidays, special days)                  |
| `shapes.txt`            | Optional — geometry of the path a bus follows                        |
| `transfers.txt`         | Optional — transfer rules and durations between stops                |
| `fare_attributes.txt` / `fare_rules.txt` | Fare structure                                          |
| `frequencies.txt`       | Optional — for services described as "every N minutes"               |
| `feed_info.txt`         | Publisher and version metadata                                       |

The archive is a **relational-shaped export**: `stop_times.foreign key trips.foreign key routes.foreign key agency`. Loading it into a data store almost always means picking whether to keep that shape or denormalise.

### 1.2 Trip planning with GTFS

The core question is:
> *"Given origin `A`, destination `B`, and departure time `T`, what
> sequence of vehicles gets me there fastest?"*

The classical algorithms — **Dijkstra on a time-expanded graph**,
**RAPTOR** (Round-Based Public Transit Router), **CSA** (Connection
Scan Algorithm) — all boil down to the same primitive queries on the
GTFS tables:

- *"which trips visit stop `s` around time `t`?"* — index `stop_times`
  by `stop_id`, filter by `departure_time > t`.
- *"which stops does trip `T` visit after stop `s`?"* — index
  `stop_times` by `(trip_id, stop_sequence)`.
- *"which stops are within a walking distance `d` of coordinate `(lat, lng)`?"*
  — geospatial index on `stops`.
- *"is trip `T` running on date `D`?"* — `calendar` / `calendar_dates`.
- *"what routes does agency `A` operate?"* — cataloguey stuff.

The database sits under those primitives. Fast primitives → fast trip
planning. That's what we benchmark.

---

## 2. Redis and MongoDB — how they differ from SQL and from each other

Both are non-SQL:
- **No fixed schema** — you don't `CREATE TABLE`.
- **Different query paradigm** — no JOINs (usually), no SQL syntax.
- **Horizontally scalable** — sharding is a first-class deployment mode.

But they solve different problems.

### 2.1 Redis — in-memory data-structure server

- Keeps the working set **entirely in RAM** (with optional AOF /
  snapshot persistence).
- Sub-millisecond latency, single-threaded event loop per shard, no I/O
  waits during a request.
- Rich **native data structures** — strings, hashes, lists, sets,
  sorted sets, streams, HyperLogLogs, bitmaps, and — critically here —
  **geospatial** (`GEOADD`, `GEOSEARCH`).
- Not a general query engine: you fetch data by *known key* or via
  data-structure-specific commands (`ZRANGEBYSCORE`, `SINTER`, etc.).
- Persistence is opt-in (RDB snapshots, AOF log). Some folks use it as
  a cache only; others as a system of record.

### 2.2 MongoDB — document database

- Documents in **BSON** (JSON with types), typically one collection per
  logical entity.
- **Disk-based** with a memory-mapped / WiredTiger cache; the working
  set doesn't need to fit in RAM.
- Rich **query language**: filters, projections, aggregation pipeline
  (multi-stage transformations equivalent to SQL joins, group-bys,
  window functions).
- Secondary indexes on any field, geospatial indexes (`2dsphere`),
  text indexes, TTL indexes, wildcard indexes.
- Replica sets for HA, **sharded clusters** for horizontal scale-out.
- ACID transactions across documents (added in 4.0).

### 2.3 One-line differentiation

- **Redis** — a hyper-fast smart cache with data structures baked in.
- **MongoDB** — a general-purpose document DB with a real query engine.

---

## 3. Benchmarking criteria — what to measure and why

### 3.1 Which numbers matter

For a trip-planning workload:

| Metric                                     | Why it matters                                            |
| ------------------------------------------ | --------------------------------------------------------- |
| **Read latency p50 / p95 / p99**           | User-facing "when's the next bus?" query                  |
| **Throughput (ops/sec)**                   | Whether one instance can serve rush-hour traffic          |
| **Ingestion time / rate**                  | How long the daily / weekly GTFS refresh takes            |
| **Storage footprint on disk (or RAM)**     | Cost per stored feed                                      |
| **Working-set / RAM requirement**          | Do you need to keep everything hot?                       |
| **Index build time**                       | Downtime window during a refresh                          |
| **Complex-query latency**                  | Aggregation / multi-stage — the "one hard query"          |
| **Recovery time after a crash**            | Ops burden                                                |
| **Horizontal scaling headroom**            | Can I 10× the users next year?                            |
| **Consistency model at scale**             | Cross-shard reads, replica lag, etc.                      |

### 3.2 Why application-based benchmarks (not synthetic ones)

Synthetic benchmarks (redis-benchmark, YCSB) tell you the DB's raw
capabilities. That's useful but misleading — they don't reflect your
data shape or your query mix.

An **application-based benchmark** replays realistic queries on
realistic data:

- Real GTFS from a real city (Paris IDF / New York MTA / TfL).
- The exact query mix the trip planner emits (skewed towards big
  transit hubs, midday time windows, etc.).
- Same client, same network path, same warm-up policy for both DBs.
- Long enough to include cache-warm-up, GC pauses, replication lag.

Only then do the numbers reflect *"how will this DB behave in my
service?"*.

---

## 4. Data ingestion and storage

### 4.1 Ingesting GTFS

A GTFS feed is ~15 CSVs — parse row by row, transform, write. In both
cases you almost never want to load `stop_times.txt` as-is (it's often
the biggest file — 10-100 M rows for a large agency). You **derive
indexes** at ingest time.

**Redis ingestion** (Node, `ioredis`) — use a **pipeline** to batch
100–1000 writes per round-trip:

```js
const pipe = redis.pipeline();
for (const row of parseCsv("stops.txt")) {
  const stopKey = `stop:${row.stop_id}`;
  pipe.hset(stopKey, {
    name: row.stop_name,
    lat:  row.stop_lat,
    lng:  row.stop_lon,
    code: row.stop_code || "",
  });
  pipe.geoadd("geo:stops", row.stop_lon, row.stop_lat, row.stop_id);
}
await pipe.exec();
```

For `stop_times.txt` — a sorted set per stop, scored by seconds-since-midnight:

```js
for (const st of parseCsv("stop_times.txt")) {
  pipe.zadd(`stoptimes:${st.stop_id}`,
    toSecondsSinceMidnight(st.departure_time),
    `${st.trip_id}:${st.stop_sequence}`);
}
```

**MongoDB ingestion** (Node, `mongoose` or plain driver) — bulk writes
per collection:

```js
await db.collection("stops").insertMany(
  parseCsv("stops.txt").map(r => ({
    _id: r.stop_id,
    name: r.stop_name,
    location: { type: "Point", coordinates: [+r.stop_lon, +r.stop_lat] },
    code: r.stop_code || null,
  }))
);
await db.collection("stops").createIndex({ location: "2dsphere" });
```

For `stop_times`, one document per row and a compound index:

```js
await db.collection("stop_times").createIndex({ stop_id: 1, departure_time: 1 });
await db.collection("stop_times").createIndex({ trip_id: 1, stop_sequence: 1 });
```

### 4.2 Storage model comparison

| Concern         | Redis                                                        | MongoDB                                                       |
| --------------- | ------------------------------------------------------------ | ------------------------------------------------------------- |
| Physical unit   | Key ↦ value (structure-aware)                                | Document within a collection                                  |
| Indexes         | Implicit (data structures ARE the index)                     | Explicit `createIndex`                                        |
| RAM requirement | Full dataset in RAM (or Redis-on-Flash for cold data)        | Only the working set needs to fit                             |
| On-disk footprint | Redis snapshot ~ full dataset size                         | BSON + WiredTiger compression — often 3-5× smaller than raw CSV |
| Refresh strategy | Blue/green with two prefixes (`v1:*`, `v2:*`) then `RENAME` | Blue/green collections then `renameCollection` — same idea    |

---

## 5. Query performance

### 5.1 The trip-planner query mix

Three primitives cover ~80% of trip-planning traffic:

1. **Next N departures from stop `S` after time `T`**
2. **Stops within `d` meters of `(lat, lng)`**
3. **Fetch trip `T`'s stop sequence**

### 5.2 On Redis

**Q1 — Next 5 departures from stop `S` after `T` (seconds since midnight):**

```
ZRANGEBYSCORE stoptimes:S T +inf LIMIT 0 5
```

Sorted-set range query — expected **O(log N + K)** where K is the
result size. Typical latency: **< 1 ms** for K < 100.

**Q2 — Stops within 400 m of a lat/lng:**

```
GEOSEARCH geo:stops FROMLONLAT 2.3522 48.8566 BYRADIUS 400 m ASC COUNT 20
```

**Q3 — Fetch the full sequence for a trip:**

Redis has no first-class "trip → ordered list of stops" structure, but
you can build one at ingest time: `LPUSH triproute:T stop_id` per row
and `LRANGE triproute:T 0 -1` to fetch. Or store the whole sequence as
JSON in a single key.

### 5.3 On MongoDB

**Q1 — Next 5 departures from stop `S`:**

```js
db.stop_times.find({
  stop_id: "S",
  departure_time: { $gte: "13:15:00" },
}).sort({ departure_time: 1 }).limit(5)
```

With the compound index on `{stop_id, departure_time}`, this is an
index scan. Typical latency: **1-5 ms** on warm cache; more on cold.

**Q2 — Stops within 400 m:**

```js
db.stops.find({
  location: { $near: {
    $geometry: { type: "Point", coordinates: [2.3522, 48.8566] },
    $maxDistance: 400,
  }}
}).limit(20)
```

Needs the `2dsphere` index.

**Q3 — Fetch trip sequence:**

```js
db.stop_times.find({ trip_id: "T" }).sort({ stop_sequence: 1 })
```

### 5.4 Complex — "give me a bus route from A to B leaving after 14:00"

This is where MongoDB's aggregation pipeline shines:

```js
db.stop_times.aggregate([
  { $match: { stop_id: "A", departure_time: { $gte: "14:00" } } },
  { $lookup: { from: "stop_times", localField: "trip_id", foreignField: "trip_id", as: "rest" }},
  { $unwind: "$rest" },
  { $match: { "rest.stop_id": "B", "rest.stop_sequence": { $gt: "$stop_sequence" } } },
  { $project: { trip_id: 1, from: "$departure_time", to: "$rest.arrival_time" } },
  { $limit: 5 },
])
```

The same query on Redis requires **application-side joining** — issue
Q1, then for each candidate trip fetch its sequence, filter. Faster
per-primitive, more code.

---

## 6. Scalability and efficiency

### 6.1 Redis at scale

- **Single-threaded per shard** — one CPU core does all the work. Scale
  is **horizontal** via *Redis Cluster*: keys are hashed into 16 384
  slots distributed across shards. Cross-shard operations need `HASH_TAG`
  discipline (`{stop:S}:times`).
- Persistence via RDB (periodic) or AOF (write-ahead log). AOF slows
  writes; RDB has a bounded loss window.
- **RAM cost dominates**. For Paris IDF (~9 M `stop_times` rows,
  ~50 000 stops, ~5 000 routes) — expect ~2-3 GB in-RAM depending on
  encoding. Redis Enterprise offers Redis-on-Flash to spill cold keys
  to SSD.

### 6.2 MongoDB at scale

- **Replica sets** for HA (primary + secondaries).
- **Sharding** by a shard key across many replica sets. Choosing the
  shard key is the number-one decision — for GTFS, sharding
  `stop_times` by `stop_id` co-locates all departures for a stop on the
  same shard, which is what most queries want.
- Storage is **compressed on disk** — the same GTFS feed can be 3-5×
  smaller than in Redis.
- Aggregations can push down to shards but the coordinator merges — a
  join across shards is not free.

### 6.3 Recommendation for a large-scale trip planner

**Neither alone; both together.** The high-QPS query surface —
"departures near me right now", "next N buses at stop X" — belongs in
Redis (or a cache in front of anything). The write path, the analytics
("how many trips ran late last month?"), the source of truth — those
belong in a document DB. A very common production topology:

```
   ┌────────────────────────┐
   │  Trip-planner service  │
   └────┬─────────────┬─────┘
        │ hot reads   │ cold reads / writes
        ▼             ▼
     ┌─────┐       ┌─────────┐
     │Redis│──etl──│MongoDB  │
     └─────┘       └─────────┘
```

Nightly ETL rebuilds Redis from MongoDB after each GTFS refresh, using
blue/green cutover so the service never sees an inconsistent view.

**If forced to pick one:** for a *large-scale, planet-wide, general
trip planner* — **MongoDB**, because the storage cost of keeping
everything in RAM across all agencies is prohibitive. For a *single
city, latency-sensitive product* (say, "which bus should I catch NOW"),
**Redis** is often enough on its own.

---

## 7. Practical application — a simple Redis-backed trip planner

### 7.1 Scope

Given a GTFS feed for one city, expose an HTTP API:

- `GET /stops/near?lat=&lng=&radius=` → the closest N stops.
- `GET /stops/:id/next?time=` → next 5 departures from that stop after `time`.
- `GET /trips/:id` → the ordered stop sequence for a trip.

### 7.2 Data model in Redis

| Key pattern                | Type       | Content                                     |
| -------------------------- | ---------- | ------------------------------------------- |
| `stop:<id>`                | Hash       | `{name, lat, lng, code}`                    |
| `geo:stops`                | Geospatial | all stops indexed by lat/lng                |
| `stoptimes:<stop_id>`      | Sorted Set | member=`trip_id:sequence`, score=seconds-since-midnight |
| `trip:<id>`                | Hash       | `{route_id, service_id, headsign}`          |
| `triproute:<id>`           | List       | ordered `stop_id`s of that trip             |
| `route:<id>`               | Hash       | `{short_name, long_name, type}`             |

### 7.3 Implementation steps

1. **Ingest** — a Node.js script parses each GTFS file with
   `csv-parser`, pipelines `HSET` / `ZADD` / `GEOADD` commands into
   Redis. On a modern laptop against a local Redis, a large city feed
   ingests in ~30-90 seconds.
2. **Refresh strategy** — write to a versioned prefix (`v2:stop:*`
   etc.). Once the ingest finishes, atomically swap the prefix pointer
   (`SET current_version v2`) so readers see the new data
   simultaneously. Wipe `v1:*` in the background.
3. **HTTP API** — Express, three routes:

   ```js
   app.get("/stops/near", async (req, res) => {
     const { lat, lng, radius = 400 } = req.query;
     const ids = await redis.geosearch("geo:stops",
       "FROMLONLAT", lng, lat, "BYRADIUS", radius, "m", "ASC", "COUNT", 20);
     const stops = await Promise.all(ids.map(id => redis.hgetall(`stop:${id}`)));
     res.json({ stops });
   });

   app.get("/stops/:id/next", async (req, res) => {
     const t = toSeconds(req.query.time || nowLocal());
     const members = await redis.zrangebyscore(`stoptimes:${req.params.id}`,
       t, "+inf", "LIMIT", 0, 5);
     res.json({ departures: members.map(parse) });
   });

   app.get("/trips/:id", async (req, res) => {
     const stops = await redis.lrange(`triproute:${req.params.id}`, 0, -1);
     res.json({ trip: await redis.hgetall(`trip:${req.params.id}`), stops });
   });
   ```

4. **Deploy** — App Service (Linux) + Redis Enterprise Cloud (managed).
   Cache stampede protection via `SETNX`-based single-flight when
   rebuilding the version prefix.

### 7.4 Why Redis fit here

- The three queries above are naturally expressed as Redis primitives.
- P99 for each stays under 5 ms on a modest instance.
- The feed fits in a few GB of RAM even for a large city.

For a version that also does *multi-hop routing* (RAPTOR), MongoDB
becomes attractive as a system-of-record backing an in-memory graph
loaded by the router process at boot.

---

## 8. Conclusion

### 8.1 Advantages / disadvantages

**Redis**

- **Pros** — sub-millisecond primitives, geospatial + sorted sets are
  a natural fit, tiny code footprint, zero query-language surface to
  learn beyond a handful of commands.
- **Cons** — RAM cost scales with dataset, no query engine beyond
  data-structure operations, cross-shard joins are your problem, ops
  discipline needed for durability.

**MongoDB**

- **Pros** — full query language + aggregation pipeline, secondary
  indexes on anything, disk-first storage keeps costs sane at scale,
  familiar to teams coming from SQL, mature ops tooling.
- **Cons** — latency an order of magnitude higher than Redis for the
  same primitive, indexing is your responsibility (bad indexes = slow
  scans), aggregation-pipeline complexity grows fast.

### 8.2 Which one for future GTFS projects

- **Latency-first, single-city trip planner** — **Redis**. The
  primitives fit, RAM is cheap enough, ops is straightforward.
- **Multi-city, analytics-heavy, or a system of record that also feeds
  analytics** — **MongoDB**.
- **A planet-scale trip planner with real-time updates** — **both**:
  MongoDB as the persistent store, Redis as the hot-cache tier
  serving the read fan-out. Feed refreshes are ETL jobs that rebuild
  Redis from MongoDB.

The most useful line to remember: **Redis and MongoDB are complements,
not rivals, for GTFS workloads at scale.** Choosing between them for a
small project is fine and pragmatic. Choosing between them for a large
one usually means you haven't yet realised you want both.
