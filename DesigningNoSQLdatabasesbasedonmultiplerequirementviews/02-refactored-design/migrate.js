// =============================================================================
// Part 2 - Migrate Part 1 data (db "shop_v1") into the refactored, sharded
// schema (db "shop"). Run through mongos AFTER schema.js and sharding.js:
//   mongosh "mongodb://localhost:27300" 02-refactored-design/migrate.js
//
// To get Part 1 data into shop_v1 on the same cluster:
//   mongosh "mongodb://localhost:27300" --eval 'var DB_NAME="shop_v1"' 01-initial-design/schema.js
//   mongosh "mongodb://localhost:27300" --eval 'var DB_NAME="shop_v1"' 01-initial-design/seed.js
//
// In production this would be a dual-write / backfill job run in batches; here
// it is a straightforward batch copy that shows the shape transformation.
// =============================================================================

const SRC = typeof SRC_DB !== "undefined" ? SRC_DB : "shop_v1";
const DST = typeof DB_NAME !== "undefined" ? DB_NAME : "shop";
const src = db.getSiblingDB(SRC);
const dst = db.getSiblingDB(DST);
const BATCH = 500;

const flush = (coll, buf) => { if (buf.length) { coll.insertMany(buf, { ordered: false }); buf.length = 0; } };

// users: unchanged shape
let buf = [];
src.users.find().forEach((u) => { buf.push(u); if (buf.length >= BATCH) flush(dst.users, buf); });
flush(dst.users, buf);

// products -> products (without stock) + inventory (stock only)
const productInfo = {}; // productId -> { categoryId, brand } used to enrich order items
const invBuf = [];
src.products.find().forEach((p) => {
  productInfo[p._id.toHexString()] = { categoryId: p.category.id, brand: p.brand };
  invBuf.push({ _id: p._id, sku: p.sku, available: NumberInt(p.stock), reserved: NumberInt(0), warehouse: "DKR-1", updatedAt: new Date() });
  const { stock, ...catalog } = p;
  catalog.inStock = stock > 0;
  buf.push(catalog);
  if (buf.length >= BATCH) { flush(dst.products, buf); flush(dst.inventory, invBuf); }
});
flush(dst.products, buf);
flush(dst.inventory, invBuf);

// orders -> denormalised, shard-key-aware orders
src.orders.find().forEach((o) => {
  const items = o.items.map((it) => ({
    productId: it.productId,
    sku: it.sku,
    name: it.name,
    categoryId: productInfo[it.productId.toHexString()].categoryId,
    brand: productInfo[it.productId.toHexString()].brand,
    unitPrice: it.unitPrice,
    quantity: it.quantity,
    lineTotal: NumberDecimal((parseFloat(it.unitPrice.toString()) * it.quantity).toFixed(2))
  }));
  buf.push({
    _id: o._id,
    orderNumber: o.orderNumber,
    customerId: o.customer.id,
    customer: { name: o.customer.name, email: o.customer.email },
    items,
    totals: o.totals,
    shippingAddress: o.shippingAddress,
    payment: o.payment,
    status: o.status,
    delivery: o.delivery,
    statusHistory: o.statusHistory,
    version: o.version,
    orderDay: o.createdAt.toISOString().slice(0, 10),
    country: (o.shippingAddress && o.shippingAddress.country) || "SN",
    createdAt: o.createdAt,
    updatedAt: o.updatedAt
  });
  if (buf.length >= BATCH) flush(dst.orders, buf);
});
flush(dst.orders, buf);

["users", "products", "inventory", "orders"].forEach((c) =>
  print(`${c}: ${(c === "inventory" ? src.products : src[c]).countDocuments()} -> ${dst[c].countDocuments()}`)
);
print("\nOrders distribution across shards:");
printjson(dst.orders.getShardDistribution());
print("\nProducts distribution across shards:");
printjson(dst.products.getShardDistribution());
