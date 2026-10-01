// =============================================================================
// Part 2 - Sharding & cluster-wide defaults (run through mongos AFTER schema.js)
//   mongosh "mongodb://localhost:27300" 02-refactored-design/sharding.js
// =============================================================================

const DB = typeof DB_NAME !== "undefined" ? DB_NAME : "shop";
const shop = db.getSiblingDB(DB);
const admin = db.getSiblingDB("admin");

// --- Cluster-wide defaults ----------------------------------------------------
// Durable by default: every write is acknowledged by a majority of each shard's
// replica set, every read sees only majority-committed data unless the caller
// explicitly asks for something weaker (e.g. catalog browsing, analytics).
admin.runCommand({
  setDefaultRWConcern: 1,
  defaultWriteConcern: { w: "majority", wtimeout: 5000 },
  defaultReadConcern: { level: "majority" }
});

// --- Enable sharding for the database ------------------------------------------
sh.enableSharding(DB);

// --- orders: hashed customerId -------------------------------------------------
// * very high cardinality, uniformly distributed -> inserts spread over all
//   shards (no hot "last chunk" like a monotonically increasing createdAt/_id)
// * "my orders" and order tracking always know the customer -> single-shard
//   targeted queries; a customer's orders are co-located.
sh.shardCollection(`${DB}.orders`, { customerId: "hashed" });

// --- inventory: hashed _id (productId) -----------------------------------------
// Point reads/updates by productId only; hashing spreads hot SKUs.
sh.shardCollection(`${DB}.inventory`, { _id: "hashed" });

// --- products: ranged { category.id, sku } -----------------------------------
// Browsing a category (the dominant catalog query) is targeted to the shard(s)
// that own that category range; the sku suffix keeps cardinality high so a huge
// category can still be split into many chunks, and because the shard key is
// itself unique ({category.id, sku}) MongoDB can still enforce SKU uniqueness.
sh.shardCollection(`${DB}.products`, { "category.id": 1, sku: 1 }, { unique: true });
// Pre-split at top-level category boundaries and spread them so the demo
// cluster is balanced from the first insert (the balancer would do it later).
const shardIds = admin.runCommand({ listShards: 1 }).shards.map((s) => s._id);
const primaryShard = db.getSiblingDB("config").databases.findOne({ _id: DB }).primary;
const otherShard = shardIds.find((s) => s !== primaryShard);
["electronics", "fashion", "home"].forEach((cat) => {
  sh.splitAt(`${DB}.products`, { "category.id": cat, sku: MinKey });
});
if (otherShard) {
  // [MinKey,"electronics") = books, ["fashion","home") = fashion -> other shard
  ["books/programming", "fashion/clothing"].forEach((cat) =>
    sh.moveChunk(`${DB}.products`, { "category.id": cat, sku: MinKey }, otherShard)
  );
}

// users, read models (daily_sales, product_*), etl_state stay UNSHARDED on the
// database's primary shard: they are small, and every shard is a replica set,
// so they are still highly available.

// --- Report -------------------------------------------------------------------
print("Default RW concern: " + JSON.stringify(admin.runCommand({ getDefaultRWConcern: 1 }).defaultWriteConcern));
db.getSiblingDB("config").collections
  .find({ _id: { $regex: `^${DB}\\.` } }, { key: 1 })
  .forEach((c) => print(`sharded ${c._id} key=${JSON.stringify(c.key)}`));
db.getSiblingDB("config").chunks
  .aggregate([
    { $lookup: { from: "collections", localField: "uuid", foreignField: "uuid", as: "c" } },
    { $unwind: "$c" },
    { $match: { "c._id": { $regex: `^${DB}\\.` } } },
    { $group: { _id: { ns: "$c._id", shard: "$shard" }, chunks: { $sum: 1 } } },
    { $sort: { "_id.ns": 1, "_id.shard": 1 } }
  ])
  .forEach((r) => print(`  ${r._id.ns} on ${r._id.shard}: ${r.chunks} chunk(s)`));
