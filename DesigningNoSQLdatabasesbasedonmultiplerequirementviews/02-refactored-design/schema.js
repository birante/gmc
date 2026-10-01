// =============================================================================
// Part 2 - Refactored schema (run through mongos, BEFORE sharding.js)
//   mongosh "mongodb://localhost:27300" 02-refactored-design/schema.js
//
// Changes vs Part 1 (see design.md for the reasoning):
//   * orders: top-level customerId (shard key) + denormalised analytics fields
//             (orderDay, country, item.categoryId, item.brand, item.lineTotal);
//             uniqueness of orderNumber is now scoped to the shard key.
//   * products: stock moved out -> catalog documents become (almost) read-only.
//   * inventory: new hot, write-heavy collection, one doc per product.
//   * daily_sales, product_daily_sales, product_stats: pre-aggregated read models.
//   * etl_state: watermarks for the incremental $merge jobs.
// =============================================================================

const DB = typeof DB_NAME !== "undefined" ? DB_NAME : "shop";
const shop = db.getSiblingDB(DB);
shop.dropDatabase();

const money = { bsonType: "decimal" };
const orderStatuses = ["pending", "paid", "shipped", "delivered", "cancelled", "returned"];

// ----------------------------------------------------------------- users
// Unchanged from Part 1 (fits comfortably on one replica set; unsharded).
shop.createCollection("users", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["email", "name", "passwordHash", "createdAt"],
      properties: {
        email: { bsonType: "string" },
        name: { bsonType: "string" },
        passwordHash: { bsonType: "string" },
        addresses: { bsonType: "array", maxItems: 10 },
        createdAt: { bsonType: "date" }
      }
    }
  }
});
shop.users.createIndex({ email: 1 }, { unique: true, name: "uniq_email" });

// ----------------------------------------------------------------- products
// Catalog. Sharded by { "category.id": 1, sku: 1 } (range) in sharding.js.
shop.createCollection("products", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["sku", "name", "description", "price", "currency", "category", "status"],
      properties: {
        sku: { bsonType: "string" },
        name: { bsonType: "string" },
        description: { bsonType: "string" },
        brand: { bsonType: "string" },
        price: money,
        currency: { enum: ["XOF", "EUR", "USD"] },
        category: {
          bsonType: "object",
          required: ["id", "path"],
          properties: { id: { bsonType: "string" }, path: { bsonType: "array" } }
        },
        tags: { bsonType: "array" },
        attributes: { bsonType: "object" },
        inStock: { bsonType: "bool", description: "eventually-consistent flag synced from inventory" },
        rating: { bsonType: "object" },
        status: { enum: ["active", "draft", "archived"] }
      }
    }
  }
});
// Unique indexes on a sharded collection must be prefixed by the full shard key,
// so the shard key itself ({category.id, sku}) is the uniqueness constraint.
shop.products.createIndex({ "category.id": 1, sku: 1 }, { unique: true, name: "uniq_category_sku" });
shop.products.createIndex({ sku: 1 }, { name: "sku_lookup" }); // non-unique, scatter-gather lookup
shop.products.createIndex(
  { name: "text", brand: "text", tags: "text", description: "text" },
  { name: "product_text", weights: { name: 10, brand: 5, tags: 5, description: 1 } }
);
shop.products.createIndex({ "category.path": 1, status: 1, price: 1 }, { name: "browse_category_price" });
shop.products.createIndex({ "category.path": 1, status: 1, "rating.avg": -1 }, { name: "browse_category_rating" });

// ----------------------------------------------------------------- inventory
// Hot counters isolated from the catalog. _id = productId. Sharded { _id: "hashed" }.
shop.createCollection("inventory", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "sku", "available", "reserved", "updatedAt"],
      properties: {
        _id: { bsonType: "objectId" },
        sku: { bsonType: "string" },
        available: { bsonType: "int", minimum: 0 },
        reserved: { bsonType: "int", minimum: 0 },
        warehouse: { bsonType: "string" },
        updatedAt: { bsonType: "date" }
      }
    }
  }
});

// ----------------------------------------------------------------- orders
// Sharded { customerId: "hashed" } in sharding.js.
shop.createCollection("orders", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["orderNumber", "customerId", "customer", "items", "totals", "status",
                 "statusHistory", "orderDay", "country", "createdAt", "updatedAt"],
      properties: {
        orderNumber: { bsonType: "string" },
        customerId: { bsonType: "objectId", description: "shard key (hashed)" },
        customer: {
          bsonType: "object",
          required: ["name", "email"],
          properties: { name: { bsonType: "string" }, email: { bsonType: "string" } }
        },
        items: {
          bsonType: "array",
          minItems: 1,
          maxItems: 200,
          items: {
            bsonType: "object",
            required: ["productId", "sku", "name", "categoryId", "unitPrice", "quantity", "lineTotal"],
            properties: {
              productId: { bsonType: "objectId" },
              sku: { bsonType: "string" },
              name: { bsonType: "string" },
              categoryId: { bsonType: "string", description: "denormalised for analytics" },
              brand: { bsonType: "string", description: "denormalised for analytics" },
              unitPrice: money,
              quantity: { bsonType: "int", minimum: 1 },
              lineTotal: money
            }
          }
        },
        totals: {
          bsonType: "object",
          required: ["subtotal", "shipping", "grandTotal", "currency"],
          properties: { subtotal: money, shipping: money, grandTotal: money, currency: { enum: ["XOF", "EUR", "USD"] } }
        },
        shippingAddress: { bsonType: "object" },
        payment: { bsonType: "object" },
        status: { enum: orderStatuses },
        delivery: { bsonType: "object" },
        statusHistory: { bsonType: "array" },
        version: { bsonType: "int" },
        orderDay: { bsonType: "string", pattern: "^\\d{4}-\\d{2}-\\d{2}$", description: "UTC bucket, denormalised" },
        country: { bsonType: "string", minLength: 2, maxLength: 2 },
        createdAt: { bsonType: "date" },
        updatedAt: { bsonType: "date" }
      }
    }
  }
});
shop.orders.createIndex({ customerId: 1, orderNumber: 1 }, { unique: true, name: "uniq_customer_order_number" });
shop.orders.createIndex({ customerId: 1, createdAt: -1 }, { name: "customer_orders" });   // targeted
shop.orders.createIndex({ orderNumber: 1 }, { name: "order_number_lookup" });           // support desk (scatter)
shop.orders.createIndex({ status: 1, createdAt: 1 }, { name: "status_queue" });          // fulfilment (scatter)
shop.orders.createIndex({ updatedAt: 1 }, { name: "etl_watermark" });                     // incremental $merge
shop.orders.createIndex({ orderDay: 1 }, { name: "order_day" });                          // day recomputation

// ----------------------------------------------------------------- read models
// daily_sales: one document per UTC day -> dashboards read 30-365 tiny docs.
shop.createCollection("daily_sales", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "orders", "revenue", "itemsSold", "refreshedAt"],
      properties: {
        _id: { bsonType: "string", description: "YYYY-MM-DD" },
        orders: { bsonType: "number" },
        cancelledOrders: { bsonType: "number" },
        revenue: money,
        avgOrderValue: money,
        itemsSold: { bsonType: "number" },
        byCategory: { bsonType: "array" },
        byCountry: { bsonType: "array" },
        byPaymentMethod: { bsonType: "array" },
        refreshedAt: { bsonType: "date" }
      }
    }
  }
});

// product_daily_sales: { _id: { productId, day } } -> trends per product.
shop.createCollection("product_daily_sales");
shop.product_daily_sales.createIndex({ "_id.day": 1 }, { name: "by_day" });

// product_stats: one document per product (all-time + rolling 30 days).
shop.createCollection("product_stats");
shop.product_stats.createIndex({ "last30d.revenue": -1 }, { name: "top_30d_revenue" });
shop.product_stats.createIndex({ categoryId: 1, "last30d.units": -1 }, { name: "category_top_30d_units" });

shop.createCollection("etl_state");

print("Collections: " + shop.getCollectionNames().sort().join(", "));
