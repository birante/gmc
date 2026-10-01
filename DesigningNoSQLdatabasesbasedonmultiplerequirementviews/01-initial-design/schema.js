// =============================================================================
// Part 1 - Initial design: collections, $jsonSchema validators and indexes
// Run:  mongosh "mongodb://localhost:27017/?replicaSet=rs0" 01-initial-design/schema.js
// Idempotent: drops and recreates the "shop" database (or DB_NAME).
// =============================================================================

// Target database (override with: mongosh --eval 'var DB_NAME="other"' <file>)
const DB = typeof DB_NAME !== "undefined" ? DB_NAME : "shop";
const shop = db.getSiblingDB(DB);
shop.dropDatabase();

// -----------------------------------------------------------------------------
// users - customer accounts (addresses embedded: small, bounded, read together)
// -----------------------------------------------------------------------------
shop.createCollection("users", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["email", "name", "passwordHash", "createdAt"],
      properties: {
        email: { bsonType: "string", pattern: "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$" },
        name: { bsonType: "string", minLength: 1 },
        passwordHash: { bsonType: "string" },
        phone: { bsonType: "string" },
        addresses: {
          bsonType: "array",
          maxItems: 10, // bounded array -> safe to embed
          items: {
            bsonType: "object",
            required: ["label", "street", "city", "country"],
            properties: {
              label: { bsonType: "string" },
              street: { bsonType: "string" },
              city: { bsonType: "string" },
              postalCode: { bsonType: "string" },
              country: { bsonType: "string", minLength: 2, maxLength: 2 },
              isDefault: { bsonType: "bool" }
            }
          }
        },
        createdAt: { bsonType: "date" }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});

shop.users.createIndex({ email: 1 }, { unique: true, name: "uniq_email" });

// -----------------------------------------------------------------------------
// products - catalog (attributes as a flexible sub-document, stock on product)
// -----------------------------------------------------------------------------
shop.createCollection("products", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["sku", "name", "description", "price", "currency", "category", "stock", "status"],
      properties: {
        sku: { bsonType: "string" },
        name: { bsonType: "string", minLength: 1 },
        description: { bsonType: "string" },
        brand: { bsonType: "string" },
        price: { bsonType: "decimal", description: "Decimal128 for money" },
        currency: { enum: ["XOF", "EUR", "USD"] },
        category: {
          bsonType: "object",
          required: ["id", "path"],
          properties: {
            id: { bsonType: "string" },
            path: { bsonType: "array", items: { bsonType: "string" } } // ["electronics","phones"]
          }
        },
        tags: { bsonType: "array", items: { bsonType: "string" } },
        attributes: { bsonType: "object" }, // polymorphic: {color, size, ram...}
        images: { bsonType: "array", items: { bsonType: "string" } },
        stock: { bsonType: "int", minimum: 0 },
        rating: {
          bsonType: "object",
          properties: {
            avg: { bsonType: "number", minimum: 0, maximum: 5 },
            count: { bsonType: "int", minimum: 0 }
          }
        },
        status: { enum: ["active", "draft", "archived"] },
        createdAt: { bsonType: "date" },
        updatedAt: { bsonType: "date" }
      }
    }
  }
});

shop.products.createIndex({ sku: 1 }, { unique: true, name: "uniq_sku" });
// Full-text search with weights: name matters more than description
shop.products.createIndex(
  { name: "text", brand: "text", tags: "text", description: "text" },
  {
    name: "product_text",
    weights: { name: 10, brand: 5, tags: 5, description: 1 },
    default_language: "english"
  }
);
// Browse a category, sorted by price (ESR rule: Equality, Sort, Range)
shop.products.createIndex({ "category.path": 1, status: 1, price: 1 }, { name: "browse_category_price" });
// Browse "top rated" in a category
shop.products.createIndex({ "category.path": 1, status: 1, "rating.avg": -1 }, { name: "browse_category_rating" });

// -----------------------------------------------------------------------------
// orders - write-heavy; self-contained snapshot of customer, items and delivery
// -----------------------------------------------------------------------------
const orderStatuses = ["pending", "paid", "shipped", "delivered", "cancelled", "returned"];

shop.createCollection("orders", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["orderNumber", "customer", "items", "totals", "status", "statusHistory", "createdAt", "updatedAt"],
      properties: {
        orderNumber: { bsonType: "string" },
        customer: {
          bsonType: "object",
          required: ["id", "name", "email"],
          properties: {
            id: { bsonType: "objectId" },
            name: { bsonType: "string" },
            email: { bsonType: "string" }
          }
        },
        items: {
          bsonType: "array",
          minItems: 1,
          maxItems: 200,
          items: {
            bsonType: "object",
            required: ["productId", "sku", "name", "unitPrice", "quantity"],
            properties: {
              productId: { bsonType: "objectId" },
              sku: { bsonType: "string" },
              name: { bsonType: "string" },
              unitPrice: { bsonType: "decimal" },
              quantity: { bsonType: "int", minimum: 1 }
            }
          }
        },
        totals: {
          bsonType: "object",
          required: ["subtotal", "shipping", "grandTotal", "currency"],
          properties: {
            subtotal: { bsonType: "decimal" },
            shipping: { bsonType: "decimal" },
            grandTotal: { bsonType: "decimal" },
            currency: { enum: ["XOF", "EUR", "USD"] }
          }
        },
        shippingAddress: { bsonType: "object" },
        payment: {
          bsonType: "object",
          properties: {
            method: { enum: ["card", "mobile_money", "cash_on_delivery"] },
            transactionId: { bsonType: "string" }
          }
        },
        status: { enum: orderStatuses },
        delivery: {
          bsonType: "object",
          properties: {
            carrier: { bsonType: "string" },
            trackingNumber: { bsonType: "string" },
            estimatedAt: { bsonType: "date" },
            deliveredAt: { bsonType: "date" }
          }
        },
        statusHistory: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["status", "at"],
            properties: { status: { enum: orderStatuses }, at: { bsonType: "date" }, note: { bsonType: "string" } }
          }
        },
        version: { bsonType: "int", description: "optimistic concurrency counter" },
        createdAt: { bsonType: "date" },
        updatedAt: { bsonType: "date" }
      }
    }
  }
});

shop.orders.createIndex({ orderNumber: 1 }, { unique: true, name: "uniq_order_number" });
// "My orders" page: equality on customer, newest first
shop.orders.createIndex({ "customer.id": 1, createdAt: -1 }, { name: "customer_orders" });
// Back-office: orders in a given status, oldest first (fulfilment queue)
shop.orders.createIndex({ status: 1, createdAt: 1 }, { name: "status_queue" });

print("Collections: " + shop.getCollectionNames().sort().join(", "));
["users", "products", "orders"].forEach((c) =>
  print(`  ${c}: ` + shop[c].getIndexes().map((i) => i.name).join(", "))
);
