// =============================================================================
// Part 1 - Main access-pattern queries (AP1..AP7 from design.md)
// Run after schema.js + seed.js:
//   mongosh "mongodb://localhost:27017/?replicaSet=rs0" 01-initial-design/queries.js
// =============================================================================

// Target database (override with: mongosh --eval 'var DB_NAME="other"' <file>)
const DB = typeof DB_NAME !== "undefined" ? DB_NAME : "shop";
const shop = db.getSiblingDB(DB);
const show = (title, value) => { print(`\n=== ${title} ===`); printjson(value); };
const winningIndex = (explain) => {
  // walk the winning plan and collect index names (works for IXSCAN / TEXT stages)
  const names = [];
  const walk = (s) => {
    if (!s) return;
    if (s.indexName) names.push(s.indexName);
    (s.inputStages || []).forEach(walk);
    walk(s.inputStage);
  };
  const plan = explain.queryPlanner.winningPlan;
  // through mongos the plan is nested per shard
  (plan.shards ? plan.shards.map((sh) => sh.winningPlan) : [plan]).forEach((p) => walk(p.queryPlan || p));
  return [...new Set(names)];
};

// --- AP1: full-text search, filtered by price, ranked by relevance -----------
const searchFilter = { $text: { $search: "wireless headphones" }, status: "active", price: { $lte: NumberDecimal("400") } };
show("AP1 full-text search 'wireless headphones'",
  shop.products
    .find(searchFilter, { name: 1, price: 1, score: { $meta: "textScore" } })
    .sort({ score: { $meta: "textScore" } })
    .limit(5)
    .toArray()
);
print("AP1 index used: " + winningIndex(shop.products.find(searchFilter).explain()));

// --- AP2: browse a category, cheapest first, keyset pagination ---------------
const page1 = shop.products
  .find({ "category.path": "electronics", status: "active" }, { name: 1, price: 1 })
  .sort({ price: 1, _id: 1 })
  .limit(5)
  .toArray();
show("AP2 browse 'electronics' page 1 (price asc)", page1);
const last = page1[page1.length - 1];
show("AP2 browse 'electronics' page 2 (keyset: price > last)",
  shop.products
    .find({
      "category.path": "electronics", status: "active",
      $or: [{ price: { $gt: last.price } }, { price: last.price, _id: { $gt: last._id } }]
    }, { name: 1, price: 1 })
    .sort({ price: 1, _id: 1 })
    .limit(5)
    .toArray()
);
print("AP2 index used: " + winningIndex(
  shop.products.find({ "category.path": "electronics", status: "active" }).sort({ price: 1 }).explain()));

// --- AP3: product detail page by SKU (point lookup) --------------------------
show("AP3 product detail by SKU", shop.products.findOne({ sku: "SKU-1004" }, { description: 0 }));

// --- AP4: place an order (multi-document ACID transaction) -------------------
// Stock decrement + order insert must succeed or fail together.
// writeConcern majority => an acknowledged order survives a primary failover.
function placeOrder(userId, lines /* [{sku, quantity}] */) {
  const session = db.getMongo().startSession();
  const s = session.getDatabase(DB);
  try {
    session.startTransaction({ readConcern: { level: "snapshot" }, writeConcern: { w: "majority" } });
    const user = s.users.findOne({ _id: userId });
    const items = [];
    let subtotal = 0;
    for (const line of lines) {
      // conditional decrement: only succeeds if enough stock is left (no oversell)
      const p = s.products.findOneAndUpdate(
        { sku: line.sku, status: "active", stock: { $gte: line.quantity } },
        { $inc: { stock: -line.quantity }, $set: { updatedAt: new Date() } },
        { returnDocument: "after" }
      );
      if (!p) throw new Error(`Out of stock: ${line.sku}`);
      items.push({ productId: p._id, sku: p.sku, name: p.name, unitPrice: p.price, quantity: NumberInt(line.quantity) });
      subtotal += parseFloat(p.price.toString()) * line.quantity;
    }
    const shipping = subtotal > 100 ? 0 : 5;
    const now = new Date();
    const order = {
      orderNumber: `ORD-2026-${now.getTime()}`,
      customer: { id: user._id, name: user.name, email: user.email },
      items,
      totals: {
        subtotal: NumberDecimal(subtotal.toFixed(2)), shipping: NumberDecimal(shipping.toFixed(2)),
        grandTotal: NumberDecimal((subtotal + shipping).toFixed(2)), currency: "EUR"
      },
      shippingAddress: user.addresses[0],
      payment: { method: "mobile_money" },
      status: "pending",
      delivery: {},
      statusHistory: [{ status: "pending", at: now }],
      version: NumberInt(1),
      createdAt: now,
      updatedAt: now
    };
    s.orders.insertOne(order);
    session.commitTransaction();
    return order.orderNumber;
  } catch (e) {
    session.abortTransaction();
    throw e;
  } finally {
    session.endSession();
  }
}

const customer = shop.users.findOne({}, { _id: 1 });
const inStock = shop.products.find({ status: "active", stock: { $gte: 5 } }).limit(2).toArray();
const stockBefore = inStock[0].stock;
const newOrderNumber = placeOrder(customer._id, [{ sku: inStock[0].sku, quantity: 2 }, { sku: inStock[1].sku, quantity: 1 }]);
show("AP4 placed order", { orderNumber: newOrderNumber, stockBefore, stockAfter: shop.products.findOne({ sku: inStock[0].sku }).stock });

// Failure path: ordering more than available aborts the whole transaction
const scarce = shop.products.findOne({ status: "active" });
try {
  placeOrder(customer._id, [{ sku: inStock[1].sku, quantity: 1 }, { sku: scarce.sku, quantity: 100000 }]);
} catch (e) {
  show("AP4 rejected order (transaction rolled back)", { error: e.message, stockUnchanged: shop.products.findOne({ sku: inStock[1].sku }).stock });
}

// --- AP5: customer order history (newest first) ------------------------------
const histFilter = { "customer.id": customer._id };
show("AP5 order history",
  shop.orders.find(histFilter, { orderNumber: 1, status: 1, "totals.grandTotal": 1, createdAt: 1 }).sort({ createdAt: -1 }).limit(5).toArray());
print("AP5 index used: " + winningIndex(shop.orders.find(histFilter).sort({ createdAt: -1 }).explain()));

// --- AP6: update delivery status (atomic single-document, optimistic lock) ---
// A single-document update is atomic in MongoDB, so status + history + version
// change together. The version check prevents two workers from racing.
function advanceStatus(orderNumber, expectedVersion, newStatus, extra = {}) {
  const now = new Date();
  const res = shop.orders.updateOne(
    { orderNumber, version: expectedVersion },
    {
      $set: Object.assign({ status: newStatus, updatedAt: now }, extra),
      $push: { statusHistory: { status: newStatus, at: now } },
      $inc: { version: 1 }
    },
    { writeConcern: { w: "majority" } }
  );
  return res.modifiedCount === 1;
}
show("AP6 pending -> paid", advanceStatus(newOrderNumber, 1, "paid", { "payment.transactionId": "TX-NEW-1" }));
show("AP6 stale update rejected (version 1 again)", advanceStatus(newOrderNumber, 1, "shipped"));
show("AP6 track order", shop.orders.findOne({ orderNumber: newOrderNumber }, { status: 1, statusHistory: 1, version: 1 }));

// --- AP7: fulfilment queue - oldest paid orders first ------------------------
show("AP7 next orders to ship",
  shop.orders.find({ status: "paid" }, { orderNumber: 1, createdAt: 1, "customer.name": 1 }).sort({ createdAt: 1 }).limit(5).toArray());
print("AP7 index used: " + winningIndex(shop.orders.find({ status: "paid" }).sort({ createdAt: 1 }).explain()));
