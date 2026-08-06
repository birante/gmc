# Migration of Data from SQL to NoSQL Databases — DLoader

> **Note on the tool.** "DLoader" as a named SQL-to-NoSQL migration tool doesn't
> appear in the widely-documented public tooling landscape (contrast with
> **AWS DMS**, **MongoDB Relational Migrator**, **Studio 3T's SQL-to-NoSQL**
> feature, **Talend**, or a home-grown ETL script). It looks like a
> course-specific tool or a pedagogical placeholder. The answers below treat
> DLoader as the tool named in the brief and describe what a fit-for-purpose
> migration tool *does*; the underlying principles transfer 1-for-1 to any of
> the mainstream tools above.

---

## 1. Introduction to Data Migration

### 1.1 What is data migration, and why does it matter?

**Data migration** is the process of moving data from one storage system to
another. In its cleanest form it is a three-step **ETL** pipeline —
**E**xtract from source, **T**ransform into the target's shape, **L**oad
into the destination — plus a validation step that proves the move was
complete and correct.

It matters because:

- **Business continuity** — the migrated data must be complete, correct,
  and usable in the new system, ideally without any downtime the
  business notices.
- **Cost predictability** — migration projects that overrun are a
  well-documented industry pattern; a solid design up front saves months.
- **Risk** — data loss, silent corruption, or performance regressions in
  the new store are all realistic hazards that can strand a project or
  ruin trust in the data.

### 1.2 Key differences between SQL and NoSQL

| Dimension        | SQL (RDBMS)                              | NoSQL (document / KV / wide-column / graph)         |
| ---------------- | ---------------------------------------- | --------------------------------------------------- |
| Schema           | Fixed, enforced at write time            | Flexible or schema-less; validation is optional     |
| Data model       | Rows in tables; relationships via FKs    | Documents (Mongo), key-value pairs (Dynamo, Redis), column families (Cassandra), nodes+edges (Neo4j) |
| Joins            | First-class, cheap for small datasets    | Rare or discouraged; data is embedded or duplicated |
| Transactions     | ACID, multi-row / multi-table by default | Often single-document atomicity or eventual consistency |
| Scaling          | Primarily vertical (bigger box)          | Horizontal (sharding, partitioning) is native       |
| Query language   | SQL — declarative, standardised          | Varies per engine (Mongo aggregation, DynamoDB API, CQL, Cypher…) |
| Best fit         | Highly relational data, complex queries  | Unstructured / semi-structured data, high write throughput, hot horizontal scale-out |

The migration bridges those two paradigms — a task that is **as much
about modelling as about copying bytes**.

---

## 2. Overview of DLoader

### 2.1 Role

DLoader (as described by the brief) is an **ETL pipeline between a source
SQL database and a target NoSQL database**. It reads rows out of
relational tables, transforms them into the target's document /
key-value / column-family shape, and writes them into the destination
store — with the operator staying in control of the mapping, batching,
and cutover strategy.

### 2.2 Features and capabilities

A tool of this kind is expected to provide:

- **Source connectors** — JDBC / ODBC drivers for MySQL, PostgreSQL,
  SQL Server, Oracle.
- **Target connectors** — MongoDB, DynamoDB, Cassandra, Couchbase, Redis,
  Neo4j, etc.
- **Declarative schema mapping** — a DSL or config file that says
  "table `orders` + `order_items` → collection `orders` with items as an
  embedded array."
- **Type coercion** — mapping `DATETIME` to ISO strings, `DECIMAL` to
  precise numeric types, `TINYINT(1)` to booleans, `TEXT` blobs to JSON
  where appropriate.
- **Join / denormalization support** — the ability to gather rows from
  several tables into a single embedded document (critical: a raw
  table-to-collection copy usually produces a bad NoSQL model).
- **Batching + parallelism** — bulk writes, N worker threads pumping
  documents in parallel, backpressure to protect the target.
- **CDC mode** — replaying WAL / binlog changes to keep source and target
  in sync during a phased cutover, so the switchover can happen with
  minimal downtime.
- **Idempotency + resume** — track progress in a checkpoint file so a
  crashed run can pick up where it left off without re-processing rows
  already loaded.
- **Validation hooks** — comparing row counts, checksums, or sampled
  documents between source and destination.
- **Dry-run mode** — read the source and log what *would* be written,
  without touching the target.

---

## 3. Migration Process

### 3.1 Steps to migrate SQL → NoSQL with DLoader

1. **Assess & discover.**
   Run a schema survey on the source: which tables, how large, which
   are hot, how they relate. Identify the access patterns the target
   NoSQL model must serve (write-heavy? read-heavy? by which key?).

2. **Design the target model.**
   *This is the step people underestimate.* Sketch collections /
   partitions matching the read patterns, decide what to **embed**
   versus what to **reference**, pick a shard key, decide TTLs and
   secondary indexes.

3. **Write the mapping.**
   Declare in DLoader's config how source tables map to target
   documents, including joins ("fetch order + its items, embed items
   as an array"), type conversions, and default values for optional
   columns.

4. **Set up the destination.**
   Create collections, indexes, and shards before the load runs — you
   don't want to build indexes on 500 million documents after the fact.

5. **Dry-run.**
   DLoader reads from source, transforms in memory, logs what it
   would emit. Verify the shape of sampled documents is what you
   expect.

6. **Bulk initial load.**
   Run the extraction against a snapshot / read-replica of the source
   so you don't hammer production. Batch inserts, parallel workers.

7. **Enable CDC.**
   Turn on change-data-capture so any writes to the source *after*
   the snapshot get replayed to the target. Now the two stores
   converge instead of drifting apart.

8. **Verify.**
   Row counts, checksums per table/collection, sampled row-by-row
   diffs. See §6.

9. **Dual-write or cutover.**
   Either point application writes at both stores for a
   confidence-building period, then flip reads over — or, once CDC
   has caught up and validation is green, do a hard cutover during a
   short freeze window.

10. **Decommission the source.**
    After a soak period long enough to confirm nothing is broken,
    stop the source instance.

### 3.2 Common challenges and how to address them

| Challenge                                    | Mitigation                                                                 |
| -------------------------------------------- | -------------------------------------------------------------------------- |
| **Impedance mismatch** — joins and referential integrity vanish | Model the target for access patterns, not for source structure. Embed vs reference is the key decision. |
| **Type differences** (DECIMAL, TIMESTAMP, BLOB) | Explicit coercions in the mapping; test with edge cases (nulls, timezones, high-precision decimals). |
| **Large data volume** — the initial load takes days | Snapshot + CDC: bulk-copy the frozen snapshot, then stream deltas.        |
| **Referential integrity** silently broken     | Validate FK-driven joins during transformation; log orphans as warnings.   |
| **Application downtime**                     | CDC + dual-write during the cutover; feature-flag the read path.           |
| **Silent data corruption**                   | Checksums per row, sample diffing, canary reads after cutover.             |
| **Rollback path**                             | Keep the source running (read-only) for a soak period.                     |
| **Character-set / encoding drift**           | Enforce UTF-8 end-to-end; guard against `latin1 → utf8mb4` classic bugs.   |

---

## 4. Data Transformation

### 4.1 How DLoader handles it

Transformation happens between the extract and load phases. A tool of
this kind typically supports:

- **Declarative field mapping** — `orders.customer_id → customer._id`.
- **Type coercion** — `DECIMAL(10, 2) → double or Decimal128`,
  `TIMESTAMP → ISODate`.
- **Aggregation across tables** — an SQL join declared in the mapping
  produces a single output document.
- **Row-level scripting hooks** — an escape hatch to run custom logic
  when the declarative mapping isn't enough.
- **Filtering / partitioning** — only load `orders` where
  `status <> 'draft'`, or shard rows by `region`.
- **Enrichment** — add computed fields (a full name derived from first +
  last, an ISO country code from a lookup table).

### 4.2 Concrete transformation examples

**Example A — flatten a 1-to-many join into an embedded array**

Source (SQL):

```
customers(id, name)
orders   (id, customer_id, total, status)
order_items(id, order_id, sku, qty, price)
```

Target (MongoDB):

```json
{
  "_id": "<customerId>",
  "name": "Alice Ba",
  "orders": [
    { "orderId": 42, "total": 120.5, "status": "shipped",
      "items": [
        { "sku": "SKU-1", "qty": 2, "price": 40 },
        { "sku": "SKU-3", "qty": 1, "price": 40.5 }
      ]}
  ]
}
```

**Example B — collapse a normalised classifier**

`users.country_id → countries.iso_code` becomes just `country: "SN"` on
the target document, saving a join at read time.

**Example C — split a fat row for a KV target**

A wide `products` row with 40 attributes becomes:
- Key `product:<sku>:base` → { name, price, description }
- Key `product:<sku>:stock` → { in_stock, warehouse, updated_at }

so that stock-only writes don't invalidate the base cache.

**Example D — boolean coercion**

MySQL's `TINYINT(1)` returns 0 or 1; the target document should store a
real `true` / `false` for JSON parsers to work naturally.

**Example E — flag the "unknown" cases**

`NULL` in SQL can mean many things (missing, "N/A", "not applicable"). At
the target, decide per field whether to store the field with `null`, omit
the field entirely, or replace with a sentinel — and stay consistent.

---

## 5. Performance Considerations

### 5.1 Factors to plan for

- **Source-side load.** Reading terabytes hits the source's IO. Use a
  read-replica or snapshot to protect production.
- **Target-side throughput.** DynamoDB provisioned-capacity throttling,
  MongoDB write-concern latency, index-build time.
- **Network path.** Same-region is a must for big loads; cross-region
  can add hours.
- **Document / row size.** Very large embedded arrays inflate write cost
  and hit engine limits (Mongo's 16 MB doc, DynamoDB's 400 KB item).
- **Index strategy.** Build indexes *before* the bulk load only if the
  DB tolerates it well; otherwise build after (Mongo prefers after for
  huge loads).
- **Batch size.** 1000 rows/batch is a common default; too large →
  memory pressure, too small → per-request overhead dominates.
- **Parallelism.** N workers ~ N × single-worker throughput up to the
  first bottleneck (network, target IO, source read).
- **Cutover window.** Off-peak, coordinated with business.

### 5.2 How DLoader optimises the load

- Multi-threaded readers and writers with configurable pool sizes.
- Batched writes with automatic retry/backoff.
- Streaming pipeline — memory footprint stays flat regardless of source
  size.
- Checkpoints so an interrupted run resumes without redoing work.
- Optional compression on the wire between DLoader and the target.
- CDC to spread the load over time instead of a single big-bang burst.

---

## 6. Consistency and Integrity

### 6.1 How DLoader keeps the data honest

- **Idempotent inserts** keyed on the source's primary key — a retried
  write hits the same document, not a duplicate.
- **Per-batch transactions** where the target supports them (Mongo's
  multi-doc transactions, DynamoDB TransactWriteItems).
- **CDC-based deltas** so ongoing changes are replayed in order, keeping
  source and target converging.
- **Dead-letter queue** for rows that fail transformation, so they can
  be inspected and re-processed without blocking the whole load.

### 6.2 Verification strategies

- **Row / document counts** per table / collection — cheap and catches
  gross undercounts.
- **Aggregate checksums** — for each source table, `SUM(numeric_col)`,
  `COUNT(DISTINCT x)`; recompute at the target and compare.
- **Sampled row diffs** — pull 1 000 random source rows, chase their
  equivalents at the target, deep-equal them.
- **Referential checks** — every embedded `customer.orders[*]` should
  correspond to a row in the source's `orders`.
- **Cutover shadowing** — for a week post-migration, dual-read from
  both stores and log divergences before decommissioning the source.

---

## 7. Practical Application — a Migration Plan

**Hypothetical.** An e-commerce backend runs on MySQL with:

```
customers(id, name, email, country_id)
countries(id, iso, name)
orders(id, customer_id, total, status, created_at)
order_items(id, order_id, sku, qty, unit_price)
```

The team wants to migrate to **MongoDB** to enable flexible product
attributes, faster read of the "customer with all orders" view, and
horizontal scale-out.

**Target model.** Embed orders (and their items) inside the customer
document, denormalise the country ISO code:

```json
{
  "_id": <customer.id>,
  "name": "…",
  "email": "…",
  "country": "SN",
  "orders": [
    { "id": 42, "total": 120.5, "status": "shipped",
      "createdAt": "2026-08-01T09:12:00Z",
      "items": [ { "sku": "…", "qty": 2, "price": 40.0 } ] }
  ]
}
```

**Step-by-step plan.**

1. **Discovery.** Row counts, DB size, peak write rate, biggest
   `orders.items` per customer. Confirm 16 MB Mongo doc limit isn't
   hit (a whale customer with 200 000 orders would need referencing,
   not embedding).
2. **Provision** the Mongo cluster; create the `customers` collection
   and indexes on `email` and `orders.id`.
3. **Write the mapping** — one join per customer, denormalise
   `countries.iso` as `country`, cast `TINYINT` status to a string
   enum, `DATETIME` → ISODate.
4. **Snapshot the MySQL source** and point DLoader at the replica.
5. **Dry-run** — verify the shape of 100 sampled documents.
6. **Bulk load** during off-peak hours, workers = 8, batch = 500.
7. **Enable CDC** from MySQL binlog into Mongo — small ongoing lag
   (< 1 min).
8. **Validate**: total customer count, sum of `orders.total`
   per country, sample 1 000 customers deep-diff.
9. **Cutover** — briefly quiesce writes, drain the CDC queue,
   flip the application read path to Mongo, then writes.
10. **Soak & decommission** — 2 weeks of dual reads + monitoring,
    then MySQL goes read-only, then decommissioned.

---

## 8. Case Studies and Examples

Publicly documented real-world SQL-to-NoSQL migrations:

- **Craigslist → MongoDB (2011)** — moved a 2 TB archive of historical
  ads out of MySQL into MongoDB to keep 5 years of retention online
  without bloating the primary MySQL cluster. The migration itself
  used a job queue: workers pulled archived rows, transformed them
  into documents, wrote them to Mongo. **Lesson:** *use MongoDB for
  the immutable historical tier, keep the transactional tier where
  it excels.*

- **Foursquare — PostgreSQL → MongoDB (2010s)** — Foursquare migrated
  large parts of its check-in workload to MongoDB for horizontal
  scale. A key incident is publicly documented: an ill-planned shard
  rebalance took the whole service down for hours. **Lesson:** *even
  when the migration itself succeeds, you must operate the new store
  fluently before decommissioning the old one*.

- **The Guardian — Postgres → MongoDB (~2011)** — content management
  moved to a document model to accommodate varying article shapes
  (video, longform, live blog). **Lesson:** *content workloads with
  polymorphic shapes are natural fits for document stores; take the
  time to model the shape variants before migrating.*

- **General AWS DMS studies** — AWS's Database Migration Service is
  widely used for RDBMS → DynamoDB / DocumentDB migrations; AWS
  publishes numerous case studies emphasising **snapshot + CDC** as
  the standard pattern for near-zero-downtime moves.

**Cross-cutting lessons:**

1. **Model first, migrate second.** A naive table-to-collection copy
   almost always produces a bad NoSQL model.
2. **Snapshot + CDC beats big-bang** for anything larger than a few GB.
3. **Verify aggregates, not just counts.** Counts catch missing rows;
   aggregate checksums catch silent transformation bugs.
4. **Have a rollback plan.** Keep the source alive read-only for a
   soak period; treat the migration as a slow cutover, not an
   instant.
5. **Operate the target before betting the business on it.** Foursquare
   is the canonical warning here.

---

## 9. Conclusion

### 9.1 Advantages of migrating SQL → NoSQL

- **Flexible schema** — accommodate polymorphic data without repeated
  migrations.
- **Horizontal scale** — shard write throughput across many nodes.
- **Read patterns aligned with the model** — one query fetches the
  whole "customer with orders" object instead of five joins.
- **Cheaper commodity storage** at scale.
- **Native fit for semi-structured / unstructured / event-shaped data.**

### 9.2 Disadvantages

- **No cheap joins.** Cross-collection queries are expensive; the model
  must anticipate this.
- **Weaker cross-record transactions.** ACID exists in some NoSQL
  engines but is often narrower than in an RDBMS.
- **Denormalization → duplication → update anomalies** unless the
  application manages them carefully.
- **Tooling gap** — decades of RDBMS tooling (reporting, BI, drivers)
  is more mature than the equivalent for NoSQL stores.
- **Operational learning curve** — Mongo sharding, DynamoDB partition
  keys, Cassandra tunings each have their own foot-guns.

### 9.3 When to reach for a tool like DLoader

**Recommend it when:**

- The move is a one-way, non-trivial migration (dozens of tables, GBs +
  of data, referential graphs to denormalise).
- You need snapshot + CDC (near-zero downtime) rather than an
  application-level double-write.
- The mapping is complex enough that hand-writing an ETL script would
  duplicate a tool's capabilities.

**Don't reach for it when:**

- The dataset is small (< 1 GB, tens of thousands of rows) — a
  hand-written script is faster to build than to configure any tool.
- The migration is really a **model redesign in disguise** — no tool
  substitutes for thinking through the target's access patterns; the
  tool is downstream of that decision.
- The team doesn't already understand the target NoSQL engine at
  operational depth.

The tool is a means. The decision about what to embed, what to
reference, which key to shard on, and how to prove the two stores
agree — that's the real work.
