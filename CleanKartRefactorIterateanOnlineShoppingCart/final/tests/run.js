// Small test suite for the refactored version. Each test builds its
// own cart / service — no shared mutable state, unlike v0.

import { ProductBuilder }        from "../src/builders/ProductBuilder.js";
import { Cart }                  from "../src/cart/Cart.js";
import { CheckoutService }       from "../src/services/CheckoutService.js";
import { PriceMonitor }          from "../src/observers/priceMonitor.js";
import {
  NoDiscount,
  PercentageDiscount,
  FixedAmountDiscount,
  BuyOneGetOneFree,
  OrderMinimumDiscount,
} from "../src/strategies/discountStrategies.js";

let pass = 0, fail = 0;
const t = (name, fn) => {
  try { fn(); console.log(`  ok   ${name}`); pass++; }
  catch (e) { console.error(`  FAIL ${name}\n       ${e.message}`); fail++; }
};
const eq = (a, b, m = "") => { if (Math.abs(a - b) > 1e-9 && a !== b) throw new Error(`${m} expected ${b} got ${a}`); };
const ok = (c, m = "") => { if (!c) throw new Error(m || "assertion failed"); };

const p = (id, price) => new ProductBuilder().withId(id).withName(id).withPrice(price).build();

console.log("\n--- CleanKart tests ---");

t("PercentageDiscount reduces line by percent", () => {
  const cart = new Cart().add({ product: p("A", 10), quantity: 2, discount: new PercentageDiscount(10) });
  eq(cart.total, 18);
});

t("FixedAmountDiscount subtracts from unit price then multiplies", () => {
  const cart = new Cart().add({ product: p("A", 10), quantity: 3, discount: new FixedAmountDiscount(2) });
  eq(cart.total, 24);
});

t("BuyOneGetOneFree charges ceil(qty/2) units", () => {
  const cart = new Cart().add({ product: p("A", 10), quantity: 5, discount: new BuyOneGetOneFree() });
  eq(cart.total, 30);
});

t("OrderMinimumDiscount only kicks in above threshold", () => {
  const strat = new OrderMinimumDiscount(30, 10);
  const c1 = new Cart().add({ product: p("A", 10), quantity: 2, discount: strat });
  eq(c1.total, 20);   // below threshold -> no discount
  const c2 = new Cart().add({ product: p("A", 10), quantity: 5, discount: strat });
  eq(c2.total, 45);   // 50 * 0.9
});

t("Cart.subtotal is pre-discount sum", () => {
  const cart = new Cart()
    .add({ product: p("A", 10), quantity: 2, discount: new PercentageDiscount(50) })
    .add({ product: p("B", 5),  quantity: 3 });
  eq(cart.subtotal, 35);
  eq(cart.total, 25);
});

t("CheckoutService applies shipping only below the free-shipping threshold", () => {
  const svc = new CheckoutService({ notifier: () => {} });
  const small = new Cart().add({ product: p("A", 10), quantity: 1 });   // subtotal 10
  const q1 = svc.quote(small);
  eq(q1.shipping, 10);
  const big = new Cart().add({ product: p("A", 10), quantity: 6 });     // subtotal 60
  const q2 = svc.quote(big);
  eq(q2.shipping, 0);
});

t("CheckoutService clears the cart after checkout", () => {
  const svc = new CheckoutService({ notifier: () => {} });
  const cart = new Cart().add({ product: p("A", 10), quantity: 1 });
  svc.checkout(cart, { name: "u", email: "u@x" });
  ok(cart.isEmpty);
});

t("Observer fires only on price *drops*", () => {
  const prod = new ProductBuilder().withId("P").withName("P").withPrice(10).build();
  const monitor = new PriceMonitor();
  let events = 0;
  monitor.watch(prod, () => events++);
  prod.updatePrice(12);   // increase -> no event
  eq(events, 0);
  prod.updatePrice(8);    // drop -> event
  eq(events, 1);
});

t("ProductBuilder throws when required fields are missing", () => {
  try { new ProductBuilder().withName("x").withPrice(1).build(); throw new Error("should throw"); }
  catch (e) { ok(/id is required/.test(e.message)); }
});

t("Empty cart cannot be checked out", () => {
  const svc = new CheckoutService({ notifier: () => {} });
  try { svc.checkout(new Cart(), { name: "u", email: "u@x" }); throw new Error("should throw"); }
  catch (e) { ok(/empty/.test(e.message)); }
});

console.log(`\n${pass} passed, ${fail} failed.`);
if (fail > 0) process.exit(1);
