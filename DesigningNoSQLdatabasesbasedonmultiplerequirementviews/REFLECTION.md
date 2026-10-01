# Reflection

**What challenges did you face during the schema refactor?**

The hardest part was choosing shard keys, because each one makes some queries cheap and others expensive. Sharding orders by hashed `customerId` spreads inserts evenly and keeps "my orders" on a single shard. The cost is that back-office lookups by status or order number must query every shard. Sharding also broke global unique indexes: MongoDB refused my first product shard key because the unique SKU index did not start with it. I had to make `{category.id, sku}` both the shard key and the uniqueness rule. Moving stock into its own collection also turned checkout into a cross-shard transaction, so I had to weigh atomicity against latency.

**How did the new requirements affect your design decisions?**

Analytics pushed me to denormalise. Order lines now copy the category, brand and line total, and each order stores its day and country. Pipelines can then group without joins. Dashboards read pre-aggregated `daily_sales` and `product_stats` documents, rebuilt by idempotent `$merge` jobs that a change stream triggers. Because whole days are recomputed instead of counters being incremented, a late cancellation cannot be counted twice. High availability led to three-member replica sets across zones and majority write concerns on money paths. Catalog and analytics reads accept slightly stale secondaries.

**How did the refactor improve scalability, availability and query performance?**

Write throughput now grows by adding shards instead of buying a larger server. Losing a whole zone still leaves a majority, so a new primary is elected automatically. Dashboards read about thirty small documents instead of scanning every order. Heavy ad-hoc queries run on tagged analytics secondaries, so checkout traffic is never slowed. The price is eventual consistency in reports and more pipeline code to maintain.
