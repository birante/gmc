// Demo — the same shopping session as v0-messy/shop.js, run through the
// refactored codebase.

import { ProductBuilder }        from "./builders/ProductBuilder.js";
import { Cart }                  from "./cart/Cart.js";
import { CheckoutService }       from "./services/CheckoutService.js";
import { PriceMonitor, notifyUser } from "./observers/priceMonitor.js";
import {
  PercentageDiscount,
  BuyOneGetOneFree,
  NoDiscount,
} from "./strategies/discountStrategies.js";

// --- Builder: rich Product construction, only optional fields you care about
const book = new ProductBuilder()
  .withId("P-001").withName("Book").withPrice(20)
  .withCategory("media").withTags(["bestseller"])
  .build();

const pen = new ProductBuilder()
  .withId("P-002").withName("Pen").withPrice(3)
  .withCategory("stationery")
  .build();

const coffee = new ProductBuilder()
  .withId("P-003").withName("Coffee").withPrice(15)
  .withCategory("food").withDescription("250g whole beans")
  .build();

// --- Strategy: per-line discount, no if/else ladder anywhere
const cart = new Cart()
  .add({ product: book,   quantity: 2, discount: new PercentageDiscount(10) })
  .add({ product: pen,    quantity: 5, discount: new BuyOneGetOneFree() })
  .add({ product: coffee, quantity: 1, discount: new NoDiscount() });

console.log("=== Cart ===");
cart.items.forEach(i =>
  console.log(`  ${i.quantity} x ${i.product.name.padEnd(8)} -> line $${i.lineTotal(cart).toFixed(2)}`)
);

// --- Observer: user watches Book, we drop the price -> user is notified
const alice   = { name: "Alice", email: "alice@x" };
const monitor = new PriceMonitor();
monitor.watch(book, notifyUser(alice));

console.log("\n=== Checkout ===");
const service = new CheckoutService();
const quote   = service.checkout(cart, alice);
console.log(`  Total charged: $${quote.total.toFixed(2)}`);

console.log("\n=== Price drop ===");
book.updatePrice(15);   // triggers observer
