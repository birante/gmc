// =============================================================================
// Part 2 - Analytics: pre-aggregated read models maintained with $merge,
// analytical queries, and a change-stream trigger.
// Run through mongos after schema.js, sharding.js and migrate.js:
//   mongosh "mongodb://localhost:27300" 02-refactored-design/aggregations.js
// =============================================================================

const DB = typeof DB_NAME !== "undefined" ? DB_NAME : "shop";
const shop = db.getSiblingDB(DB);
const show = (title, value) => { print(`\n=== ${title} ===`); printjson(value); };

const REVENUE_STATUSES = ["pending", "paid", "shipped", "delivered"]; // cancelled/returned excluded
const ZERO = NumberDecimal("0");
const isRevenue = { $in: ["$status", REVENUE_STATUSES] };
const dayStr = (d) => d.toISOString().slice(0, 10);

// -----------------------------------------------------------------------------
// 1) Incremental refresh of the read models.
//    Find the days touched since the last watermark, then RECOMPUTE those days
//    entirely and upsert them with $merge. Recomputing whole buckets (instead
//    of +=) makes the job idempotent: re-running it, or overlapping windows,
//    never double-counts, and status changes (e.g. cancellations) are handled.
// -----------------------------------------------------------------------------
function refreshSalesReadModels({ full = false } = {}) {
  const runStart = new Date();
  const state = shop.etl_state.findOne({ _id: "sales" });
  const since = full || !state ? new Date(0) : state.watermark;

  const days = shop.orders.distinct("orderDay", { updatedAt: { $gte: since } });
  if (days.length === 0) return { days: 0, products: 0 };
  const matchDays = { $match: { orderDay: { $in: days } } };

  // 1a. daily_sales headline numbers (replace the whole day document)
  shop.orders.aggregate([
    matchDays,
    { $group: {
        _id: "$orderDay",
        orders: { $sum: { $cond: [isRevenue, 1, 0] } },
        cancelledOrders: { $sum: { $cond: [isRevenue, 0, 1] } },
        revenue: { $sum: { $cond: [isRevenue, "$totals.grandTotal", ZERO] } },
        itemsSold: { $sum: { $cond: [isRevenue, { $sum: "$items.quantity" }, 0] } }
    } },
    { $set: {
        avgOrderValue: { $cond: [{ $gt: ["$orders", 0] }, { $round: [{ $divide: ["$revenue", "$orders"] }, 2] }, ZERO] },
        refreshedAt: runStart
    } },
    { $merge: { into: "daily_sales", on: "_id", whenMatched: "replace", whenNotMatched: "insert" } }
  ]);

  // 1b. breakdowns merged into the same day documents (one field per pass)
  const breakdown = (field, keyExpr, unwindItems) => {
    const valueExpr = unwindItems ? "$items.lineTotal" : "$totals.grandTotal";
    const unitsExpr = unwindItems ? "$items.quantity" : 1;
    shop.orders.aggregate([
      matchDays,
      { $match: { status: { $in: REVENUE_STATUSES } } },
      ...(unwindItems ? [{ $unwind: "$items" }] : []),
      { $group: { _id: { day: "$orderDay", key: keyExpr }, revenue: { $sum: valueExpr }, units: { $sum: unitsExpr } } },
      { $group: { _id: "$_id.day", list: { $push: { key: "$_id.key", revenue: "$revenue", units: "$units" } } } },
      { $project: { [field]: { $sortArray: { input: "$list", sortBy: { revenue: -1 } } } } },
      { $merge: { into: "daily_sales", on: "_id", whenMatched: "merge", whenNotMatched: "discard" } }
    ]);
  };
  breakdown("byCategory", "$items.categoryId", true);
  breakdown("byCountry", "$country", false);
  breakdown("byPaymentMethod", "$payment.method", false);

  // 1c. product_daily_sales: one doc per (product, day); zero rows are kept so a
  //     fully-cancelled day correctly overwrites a previous non-zero value.
  shop.orders.aggregate([
    matchDays,
    { $unwind: "$items" },
    { $group: {
        _id: { productId: "$items.productId", day: "$orderDay" },
        categoryId: { $first: "$items.categoryId" },
        units: { $sum: { $cond: [isRevenue, "$items.quantity", 0] } },
        revenue: { $sum: { $cond: [isRevenue, "$items.lineTotal", ZERO] } },
        orders: { $sum: { $cond: [isRevenue, 1, 0] } }
    } },
    { $merge: { into: "product_daily_sales", on: "_id", whenMatched: "replace", whenNotMatched: "insert" } }
  ]);

  // 1d. product_stats for every product touched (all-time + rolling 30 days)
  const productIds = shop.orders.distinct("items.productId", { orderDay: { $in: days } });
  const cutoff = dayStr(new Date(Date.now() - 29 * 86400000));
  refreshProductStats({ "_id.productId": { $in: productIds } }, cutoff, runStart);

  // Watermark with a small overlap: safe because the job is idempotent.
  shop.etl_state.updateOne(
    { _id: "sales" },
    { $set: { watermark: new Date(runStart.getTime() - 5000), lastRun: runStart, lastDays: days.length } },
    { upsert: true }
  );
  return { days: days.length, products: productIds.length };
}

function refreshProductStats(match, cutoff, runStart) {
  shop.product_daily_sales.aggregate([
    { $match: match },
    { $group: {
        _id: "$_id.productId",
        categoryId: { $first: "$categoryId" },
        units: { $sum: "$units" },
        revenue: { $sum: "$revenue" },
        orders: { $sum: "$orders" },
        lastSoldDay: { $max: { $cond: [{ $gt: ["$units", 0] }, "$_id.day", null] } },
        units30: { $sum: { $cond: [{ $gte: ["$_id.day", cutoff] }, "$units", 0] } },
        revenue30: { $sum: { $cond: [{ $gte: ["$_id.day", cutoff] }, "$revenue", ZERO] } }
    } },
    // $lookup into the sharded products collection (supported since MongoDB 5.1)
    { $lookup: { from: "products", localField: "_id", foreignField: "_id", as: "p",
                 pipeline: [{ $project: { name: 1, brand: 1, sku: 1 } }] } },
    { $set: { p: { $first: "$p" } } },
    { $project: {
        name: "$p.name", sku: "$p.sku", brand: "$p.brand", categoryId: 1,
        allTime: { units: "$units", revenue: "$revenue", orders: "$orders" },
        last30d: { units: "$units30", revenue: "$revenue30" },
        lastSoldDay: 1,
        refreshedAt: runStart
    } },
    { $merge: { into: "product_stats", on: "_id", whenMatched: "replace", whenNotMatched: "insert" } }
  ]);
}

// Nightly job: the 30-day window slides even when nothing changes, so recompute
// every product once per day (cheap: reads product_daily_sales, not orders).
function nightlyRollingWindowRefresh() {
  const runStart = new Date();
  refreshProductStats({}, dayStr(new Date(Date.now() - 29 * 86400000)), runStart);
}

show("Initial full refresh", refreshSalesReadModels({ full: true }));
nightlyRollingWindowRefresh();
show("Read model sizes", {
  orders: shop.orders.countDocuments(),
  daily_sales: shop.daily_sales.countDocuments(),
  product_daily_sales: shop.product_daily_sales.countDocuments(),
  product_stats: shop.product_stats.countDocuments()
});

// -----------------------------------------------------------------------------
// 2) Dashboard queries - served from tiny pre-aggregated documents
// -----------------------------------------------------------------------------
const since14 = dayStr(new Date(Date.now() - 13 * 86400000));
show("A1 revenue trend, last 14 days (daily_sales)",
  shop.daily_sales.find({ _id: { $gte: since14 } }, { orders: 1, revenue: 1, avgOrderValue: 1, itemsSold: 1 }).sort({ _id: 1 }).toArray());

show("A2 top 5 products by revenue, last 30 days (product_stats)",
  shop.product_stats.find({}, { name: 1, categoryId: 1, last30d: 1 }).sort({ "last30d.revenue": -1 }).limit(5).toArray());

show("A3 category share of revenue, last 30 days (daily_sales.byCategory)",
  shop.daily_sales.aggregate([
    { $match: { _id: { $gte: dayStr(new Date(Date.now() - 29 * 86400000)) } } },
    { $unwind: "$byCategory" },
    { $group: { _id: "$byCategory.key", revenue: { $sum: "$byCategory.revenue" }, units: { $sum: "$byCategory.units" } } },
    { $group: { _id: null, total: { $sum: "$revenue" }, cats: { $push: "$$ROOT" } } },
    { $unwind: "$cats" },
    { $project: { _id: "$cats._id", revenue: "$cats.revenue", units: "$cats.units",
                  sharePct: { $round: [{ $multiply: [{ $divide: ["$cats.revenue", "$total"] }, 100] }, 1] } } },
    { $sort: { revenue: -1 } }
  ]).toArray());

show("A4 week-over-week revenue per category (product_daily_sales)",
  shop.product_daily_sales.aggregate([
    { $match: { "_id.day": { $gte: since14 } } },
    { $group: {
        _id: "$categoryId",
        thisWeek: { $sum: { $cond: [{ $gte: ["$_id.day", dayStr(new Date(Date.now() - 6 * 86400000))] }, "$revenue", ZERO] } },
        lastWeek: { $sum: { $cond: [{ $lt: ["$_id.day", dayStr(new Date(Date.now() - 6 * 86400000))] }, "$revenue", ZERO] } }
    } },
    { $set: { growthPct: { $cond: [{ $gt: ["$lastWeek", 0] },
        { $round: [{ $multiply: [{ $divide: [{ $subtract: ["$thisWeek", "$lastWeek"] }, "$lastWeek"] }, 100] }, 1] }, null] } } },
    { $sort: { growthPct: -1 } }
  ]).toArray());

// -----------------------------------------------------------------------------
// 3) Ad-hoc exploration on RAW orders, routed to the analytics members
//    (priority 0, tagged {workload:"analytics"}) so it never competes with
//    checkout traffic on the primaries. Slightly stale data is acceptable.
// -----------------------------------------------------------------------------
const conn = db.getMongo();
conn.setReadPref("secondary", [{ workload: "analytics" }, {}]); // fall back to any secondary
show("A5 basket size & AOV by country and payment method (raw orders on analytics secondaries)",
  shop.orders.aggregate([
    { $match: { status: { $in: REVENUE_STATUSES } } },
    { $group: {
        _id: { country: "$country", payment: "$payment.method" },
        orders: { $sum: 1 },
        avgItems: { $avg: { $sum: "$items.quantity" } },
        aov: { $avg: "$totals.grandTotal" }
    } },
    { $set: { avgItems: { $round: ["$avgItems", 2] }, aov: { $round: ["$aov", 2] } } },
    { $sort: { orders: -1 } },
    { $limit: 8 }
  ], { readConcern: { level: "local" } }).toArray());
conn.setReadPref("primary");

// -----------------------------------------------------------------------------
// 4) Change stream: react to order writes in near real time.
//    In production a small worker would run this loop forever (resuming from
//    the stored resume token) and call refreshSalesReadModels() in micro-batches.
//    Here we open the stream, cancel one order, and show the read model update.
// -----------------------------------------------------------------------------
const stream = shop.orders.watch(
  [{ $match: { operationType: { $in: ["insert", "update", "replace"] } } }],
  { fullDocument: "updateLookup" }
);
const victim = shop.orders.findOne({ status: "paid" });
const before = shop.daily_sales.findOne({ _id: victim.orderDay }, { orders: 1, cancelledOrders: 1, revenue: 1 });

shop.orders.updateOne(
  { customerId: victim.customerId, _id: victim._id }, // includes shard key -> single-shard write
  { $set: { status: "cancelled", updatedAt: new Date() },
    $push: { statusHistory: { status: "cancelled", at: new Date(), note: "change-stream demo" } },
    $inc: { version: 1 } }
);

let event = null;
for (let i = 0; i < 50 && !event; i++) event = stream.tryNext();
stream.close();
show("Change event received", event && { op: event.operationType, orderNumber: event.fullDocument.orderNumber, status: event.fullDocument.status, resumeToken: event._id });
show("Incremental refresh triggered by the event", refreshSalesReadModels());
show(`daily_sales[${victim.orderDay}] before -> after`, {
  before,
  after: shop.daily_sales.findOne({ _id: victim.orderDay }, { orders: 1, cancelledOrders: 1, revenue: 1 })
});

// -----------------------------------------------------------------------------
// 5) Query routing evidence: targeted vs scatter-gather on the sharded orders
// -----------------------------------------------------------------------------
const shardsUsed = (exp) => Object.keys((exp.queryPlanner.winningPlan.shards || []).reduce((m, s) => (m[s.shardName] = 1, m), {}));
show("Routing", {
  "orders by customerId (targeted)": shardsUsed(shop.orders.find({ customerId: victim.customerId }).explain()),
  "orders by status (scatter-gather)": shardsUsed(shop.orders.find({ status: "paid" }).explain()),
  "products in category 'fashion/shoes' (targeted)": shardsUsed(shop.products.find({ "category.id": "fashion/shoes" }).explain()),
  "products full-text search (scatter-gather)": shardsUsed(shop.products.find({ $text: { $search: "laptop" } }).explain())
});
