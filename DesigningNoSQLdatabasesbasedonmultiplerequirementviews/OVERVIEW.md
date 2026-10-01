# Designing NoSQL Databases Based on Multiple Requirement Views

This checkpoint designs the database for an **e-commerce application** with **MongoDB** (document model) as the system of record and **Redis** (key-value) for carts, sessions and caching. The design is done twice:

1. **Initial design** (`01-initial-design/`): product browsing with full-text search, orders with customer info, items and delivery status, and thousands of transactions per second.
2. **Refactored design** (`02-refactored-design/`): large-scale analytics plus high availability and partition tolerance, using **sharding**, **replication across zones**, and **denormalised / pre-aggregated read models** maintained with `$merge` and change streams.

The assignment text is in [`Readme.md`](Readme.md). The reflection is in [`REFLECTION.md`](REFLECTION.md).

## Structure

```
.
├── Readme.md                     # assignment (unchanged)
├── OVERVIEW.md                   # this file (project README; named OVERVIEW.md because
│                                 #   README.md would collide with Readme.md on case-insensitive filesystems)
├── REFLECTION.md                 # 200-300 word reflection
├── SUBMISSION.md                 # deliverables summary
├── run-all.sh                    # runs every script in order
├── 01-initial-design/
│   ├── design.md                 # entities, access patterns, embedding vs referencing, indexes, consistency, diagrams
│   ├── schema.js                 # collections + $jsonSchema validators + indexes (incl. weighted text index)
│   ├── seed.js                   # deterministic sample data (20 users, 42 products, 300 orders)
│   └── queries.js                # access patterns AP1-AP7 (search, browse, transaction, status, ...)
└── 02-refactored-design/
    ├── design.md                 # what changed and why: shard keys, replica topology, concerns, CAP, read models
    ├── schema.js                 # refactored collections (inventory split, denormalised orders, read models)
    ├── sharding.js               # setDefaultRWConcern, enableSharding, shardCollection, pre-split
    ├── migrate.js                # Part 1 data -> refactored shape
    ├── aggregations.js           # $merge pipelines, dashboards, analytics secondaries, change stream
    ├── docker-compose.yml        # 2 shards x 3-member replica sets + config RS + mongos
    └── cluster/
        ├── init-cluster.sh       # rs.initiate + addShard (used by docker compose)
        └── start-local.sh        # same topology with native mongod/mongos (no Docker)
```

## How to run

Requirements: `mongosh` and MongoDB 8.x (either `mongod`/`mongos` binaries, or Docker).

### Option A: native binaries (no Docker)

```bash
./02-refactored-design/cluster/start-local.sh      # 2 shards x 3 nodes + config + mongos on :27300
./run-all.sh                                       # Part 1 + Part 2 against mongodb://127.0.0.1:27300
./02-refactored-design/cluster/start-local.sh clean  # stop and delete the data
```

### Option B: Docker

```bash
cd 02-refactored-design
docker compose up -d && docker compose logs -f init   # wait for "Cluster ready"
cd .. && CLUSTER_URI=mongodb://localhost:27017 ./run-all.sh
```

### Part 1 only (any replica set)

Transactions need a replica set. A single-node one is enough:

```bash
mongosh "mongodb://localhost:27017/?replicaSet=rs0" 01-initial-design/schema.js
mongosh "mongodb://localhost:27017/?replicaSet=rs0" 01-initial-design/seed.js
mongosh "mongodb://localhost:27017/?replicaSet=rs0" 01-initial-design/queries.js
```

All scripts accept `--eval 'var DB_NAME="otherdb"'` to target another database. `schema.js` drops and recreates its database.

## Key design decisions at a glance

| Concern | Part 1 | Part 2 |
|---------|--------|--------|
| Data model | Orders embed items, address and status history; products have flexible attributes | + denormalised `orderDay`, `country`, `categoryId`, `brand`, `lineTotal` in orders |
| Search | Weighted text index on name / brand / tags / description | Same, scatter-gather across shards (optional Atlas Search / OpenSearch) |
| Write path | Transaction: conditional stock `$inc` + order insert, `w: majority` | Stock moved to `inventory` (hashed); orders sharded on hashed `customerId` |
| Availability | 1 replica set | Every shard a 3-node replica set across 3 AZs; analytics node with priority 0 |
| Analytics | n/a | `daily_sales`, `product_daily_sales`, `product_stats` via idempotent `$merge`, triggered by change streams |
| Key-value | Redis for carts / sessions / cache | Same |
