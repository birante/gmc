# Submission: Designing NoSQL Databases Based on Multiple Requirement Views

| Deliverable | Where |
|-------------|-------|
| Initial schema design | [`01-initial-design/design.md`](01-initial-design/design.md), [`schema.js`](01-initial-design/schema.js), [`seed.js`](01-initial-design/seed.js), [`queries.js`](01-initial-design/queries.js) |
| Refactored schema | [`02-refactored-design/design.md`](02-refactored-design/design.md), [`schema.js`](02-refactored-design/schema.js), [`sharding.js`](02-refactored-design/sharding.js), [`migrate.js`](02-refactored-design/migrate.js), [`aggregations.js`](02-refactored-design/aggregations.js), [`docker-compose.yml`](02-refactored-design/docker-compose.yml) |
| Reflection (200–300 words) | [`REFLECTION.md`](REFLECTION.md) |
| How to run | [`OVERVIEW.md`](OVERVIEW.md), [`run-all.sh`](run-all.sh) |

## Summary

* **Model:** MongoDB document store as the system of record. Redis key-value store for carts, sessions and cache.
* **Part 1:** Orders are self-contained documents (customer snapshot, items, address, status history) with `$jsonSchema` validation. Products have a weighted full-text index and ESR-ordered browse indexes. Checkout is a `w: majority` transaction with a conditional stock decrement. Status updates are atomic, with optimistic locking.
* **Part 2:** Orders are sharded on hashed `customerId`, products on `{category.id, sku}`, and inventory on hashed `_id`. Every shard is a 3-member replica set across availability zones, with a priority-0 analytics member. Read and write concerns are chosen per use case (CAP / PACELC). Denormalised order lines feed the pre-aggregated `daily_sales`, `product_daily_sales` and `product_stats` collections, maintained by idempotent `$merge` pipelines and triggered by a change stream.
* **Validated:** all scripts were executed on MongoDB 8.2: Part 1 on a replica set, Part 2 on a 2-shard × 3-node cluster behind `mongos`.
