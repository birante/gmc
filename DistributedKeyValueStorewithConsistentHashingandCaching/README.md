# Distributed Key-Value Store — Consistent Hashing + Caching

In-process **simulation** of a distributed KV store. All the mechanisms
that a real system (Dynamo, Cassandra, Riak) would put on separate boxes
run inside one Node process here, so the whole thing is observable from
a single script.

## Run

```bash
node src/index.js          # end-to-end demo
node tests/run.js          # 11 unit tests
# or
npm start / npm test
```

Requires Node.js **≥ 18** (ES modules + private fields).

## What's included

| File                  | Role                                                             |
| --------------------- | ---------------------------------------------------------------- |
| `src/HashRing.js`     | 32-bit consistent-hash ring with 128 virtual nodes per physical  |
| `src/Node.js`         | Storage shard with a Map + alive/dead flag                       |
| `src/LruCache.js`     | LRU cache using JS Map's insertion order                         |
| `src/TtlCache.js`     | Per-entry-TTL cache (bonus)                                      |
| `src/Cluster.js`      | Transparent coordinator — put/get/delete, replication, rebalance |
| `src/index.js`        | Demo of every requirement                                        |
| `tests/run.js`        | 11 unit tests (hash ring, caches, replication, failover, rebalance) |
| `expected_output.txt` | Captured console output from a real run                          |

## What the checkpoint asks for — where each requirement is met

| Requirement                                    | Implementation                                                                 |
| ---------------------------------------------- | ------------------------------------------------------------------------------ |
| Consistent hashing assigns keys to nodes       | `HashRing.getNode(key)` / `getNodes(key, r)` in `src/HashRing.js`               |
| Node join / leave with minimal data movement   | `Cluster.addNode` + `Cluster.decommission` — demo prints the rebalance op count |
| Caching layer (LRU / TTL)                      | `LruCache.js` + `TtlCache.js` — LRU is wired into the Cluster by default       |
| Node failure with degraded availability        | `Cluster.failNode(id)` — read path falls through to replicas                    |
| Transparency (users never mention nodes)       | `Cluster.put(k, v)` / `Cluster.get(k)` don't take a node argument               |

## Consistent hashing, in one paragraph

The ring is a 32-bit unsigned integer space (0 … 2³²-1). Each physical
node stakes **128 virtual nodes**: their positions are the SHA-1 hashes
of `<nodeId>#0`, `<nodeId>#1`, …, `<nodeId>#127`. To find the owner of a
key, we hash the key, walk clockwise, and pick the first virtual node
whose position is `>=` the key's hash — the physical node behind that
vnode is the primary. For replication factor `R`, we keep walking and
collect the next `R-1` **distinct physical** nodes; those are the
replicas. When a node joins or leaves, only the keys between its
vnodes and their predecessors need to move — that's the "minimal data
movement" property.

## Demo highlights

The demo output (captured in `expected_output.txt`) walks through:

1. **Build a 3-node cluster** — `A`, `B`, `C` with `rf = 2`.
2. **PUT 6 users** — each is placed on 2 nodes (primary + one replica).
3. **GET twice** — first pass hits real nodes, second pass all cache.
4. **Add node-D** — 6 rebalance ops (3 relocated keys) on 12 replica placements. Baseline is `K × R / N = 12 / 4 = 3`. That's a **small fraction** relocating.
5. **Fail node-A** — all 6 users still reachable via replicas. Fail node-B on top; still 6 / 6 available (vnodes spread the replicas across ≥ 2 of the 4 nodes for every key).
   - **Contrast with rf=1**: same double-failure loses **3 of 6** users — the "limited availability" scenario the brief asks to demonstrate.
6. **Recover the failed nodes, decommission node-D gracefully** — 6 rebalance ops, every user still reachable.
7. **TTL cache** — set with a 50 ms TTL, expires after 120 ms.

## Verified end-to-end

- `node tests/run.js` → **11 passed, 0 failed**.
- `node src/index.js` produces the output in `expected_output.txt`, showing each of the five requirements met.

## Design notes / trade-offs

- **In-process simulation, not a real distributed system.** No RPC, no
  network partitions, no anti-entropy. The point of the checkpoint is
  to demonstrate the algorithms, not to reimplement Cassandra.
- **Cache invalidation** on membership change. `addNode` /
  `decommission` clear the whole cache, since ownership changed — this
  is coarse but always correct. A real system would invalidate only
  the keys whose owner set actually moved.
- **Rebalance ops** counts every place-or-remove operation. Each
  relocated key produces 2 ops (place on new owner + delete from old).
- **Replication is synchronous.** Every `put` writes to every live
  replica before returning. A real system would offer tunable
  consistency (`quorum`, `one`, `all` — Dynamo's W/R/N knobs).
- **No hinted handoff.** When a node is down, writes bound for it are
  silently dropped (they still hit the surviving replicas). Recovering
  the node does *not* backfill — a real Dynamo would use hinted
  handoff to catch it up. That's out of scope here.
