# CleanKart — Iteration Report

Four iterations turned a 60-line messy prototype into a modular, patterned, tested codebase. Behavior is preserved end-to-end: v0 and `final/` produce the same `$64.80` order total on the demo scenario.

---

## Iteration 0 — the starting mess (`v0-messy/shop.js`)

The prototype had ten distinct code smells in under sixty lines:

| # | Smell                          | Where                                             |
| - | ------------------------------ | ------------------------------------------------- |
| 1 | **Module-level mutable state** | `let cart = []; let watchers = {}; let user = null;` |
| 2 | **God function**               | `calculate()` sums lines, applies discounts, adds shipping, adds tax |
| 3 | **If/else ladder on `discount` type** | `if (it.discount === "percent") … else if …`   |
| 4 | **Magic numbers**              | `total < 50`, `+= 10`, `* 0.08` — no names, no docs |
| 5 | **Primitive obsession**        | `addItem(name, price, qty, category, discount, code)` — 6 positional args, wrong order = silent bug |
| 6 | **Ambiguous names**            | `it`, `t`, `u`, `code`                            |
| 7 | **Mixed responsibilities**     | `checkout()` does compute + print + email + reset |
| 8 | **Dead TODO**                  | `priceDrop()` "will notify one day"               |
| 9 | **String duplication**         | `console.log(...)` copy-pasted 4× as the notification mechanism |
| 10 | **CommonJS in an ES-module project** | `module.exports = {...}` — inconsistent tooling |

The rest of this report walks through the four iterations, each of which fixed a subset of these and left the code runnable.

---

## Iteration 1 — clean code, no patterns yet

**Goal:** make the code trustworthy before touching design. Only mechanical refactorings.

**Techniques applied**
- **Extract module** — one file per concept (`models/Product.js`, `cart/Cart.js`, `services/CheckoutService.js`, `utils/constants.js`).
- **Extract method** — `calculate()` split into `Cart.total`, `CartItem.lineTotal`, `CheckoutService.quote` and `CheckoutService.checkout`.
- **Rename** — `it → item`, `t → total`, `u → user`, `code → discountValue` (later replaced by strategies).
- **Introduce named constants** — `PRICING.TAX_RATE`, `FLAT_SHIPPING_FEE`, `FREE_SHIPPING_MIN` in `constants.js`.
- **Kill globals** — no more module-level `cart`, `watchers`, `user`. Each cart is an instance; the checkout service is created per session.
- **Replace positional args with an options bag** — `addItem(name, price, qty, …)` → `cart.add({ product, quantity, discount })`.
- **Delete dead code** — the "TODO: notify users" comment and the raw `console.log(name + " is now …")` are gone.

Before (excerpt):
```js
function calculate() {
  let total = 0;
  for (let i = 0; i < cart.length; i++) {
    let it = cart[i];
    if (it.discount === "percent") { total += it.price * it.qty * (1 - it.code / 100); }
    else if (it.discount === "fixed") { total += (it.price - it.code) * it.qty; }
    else if (it.discount === "bogo")  { let paid = Math.ceil(it.qty / 2); total += it.price * paid; }
    else { total += it.price * it.qty; }
  }
  if (total < 50) total += 10;
  total = total + total * 0.08;
  return total;
}
```

After (excerpt from `Cart.js`, `CheckoutService.js`, `constants.js`):
```js
// Cart.js
get total() { return this.#items.reduce((s, i) => s + i.lineTotal(this), 0); }

// CheckoutService.js
quote(cart) {
  const subtotal = cart.total;
  const shipping = subtotal >= PRICING.FREE_SHIPPING_MIN ? 0 : PRICING.FLAT_SHIPPING_FEE;
  const tax      = (subtotal + shipping) * PRICING.TAX_RATE;
  return { subtotal, shipping, tax, total: subtotal + shipping + tax };
}
```

**Effect** — reads top-to-bottom, no globals, and the shipping/tax policy is now a single line each.

---

## Iteration 2 — Strategy pattern for discounts

**Smell targeted:** the `if (it.discount === …) else if` ladder in the old `calculate()` (smell #3). Adding a "student discount" or a "seasonal promo" meant editing the ladder — closed against extension.

**Pattern applied** — `strategies/discountStrategies.js`

```js
class DiscountStrategy { apply(lineTotal, item, cart) { throw new Error("not implemented"); } }

export class PercentageDiscount extends DiscountStrategy {
  #percent;
  constructor(p) { super(); this.#percent = p; }
  apply(lineTotal) { return lineTotal * (1 - this.#percent / 100); }
}
export class BuyOneGetOneFree extends DiscountStrategy {
  apply(_lineTotal, item) { return item.product.price * Math.ceil(item.quantity / 2); }
}
export class OrderMinimumDiscount extends DiscountStrategy {
  apply(lineTotal, _item, cart) {
    return cart.subtotal >= this.#threshold ? lineTotal * (1 - this.#percent / 100) : lineTotal;
  }
}
```

**Effect**
- `CartItem.lineTotal` shrank to a single dispatch: `this.#discount.apply(this.lineTotalBeforeDiscount, this, cart)`.
- Adding a new discount is now a *new file*, not a modification of `Cart`.
- Cart-wide rules are expressible too (see `OrderMinimumDiscount`, which reads `cart.subtotal`).
- Tests use the strategies directly, no need to reach into cart internals.

---

## Iteration 3 — Observer pattern for price drops

**Smell targeted:** the `priceDrop()` TODO (#8) and the fact that "who wants to know" was hard-coded to `console.log`.

**Pattern applied** — `observers/priceMonitor.js` + `Product.updatePrice()`

```js
// Product.js
updatePrice(newPrice) {
  const oldPrice = this.#price;
  this.#price = newPrice;
  if (newPrice < oldPrice) for (const fn of this.#listeners) fn({ product: this, oldPrice, newPrice });
}

// priceMonitor.js
class PriceMonitor {
  watch(product, listener) { /* subscribe */ }
  unwatch(product, listener) { /* … */ }
}
```

**Effect**
- The publisher (`Product`) fires an event only when the price actually drops — no false alarms on price *increases*.
- Subscribers are arbitrary functions, so anything (a user notifier, a wishlist re-ranker, a logger) can plug in.
- The demo shows Alice receiving a formatted message via `notifyUser(alice)`; the tests verify no event fires on a price *increase*.

---

## Iteration 4 — Builder pattern for Product

**Smell targeted:** the 6-positional-argument `addItem(name, price, qty, category, discount, code)` (#5) and the growing list of optional Product fields (tags, description, SKU) that would have made the constructor even worse.

**Pattern applied** — `builders/ProductBuilder.js`

```js
const book = new ProductBuilder()
  .withId("P-001").withName("Book").withPrice(20)
  .withCategory("media")
  .withTags(["bestseller"])
  .build();
```

**Effect**
- Required fields are enforced at `build()` — you cannot forget an id or a price.
- Optional fields are opt-in; you don't have to pass `undefined` for the ones you don't need.
- Reading a call site tells you exactly which fields matter, without having to consult the constructor signature.

---

## How clean-code principles shaped the result

| Principle                       | Concrete application                                                                 |
| ------------------------------- | ------------------------------------------------------------------------------------ |
| **Single Responsibility**       | `Cart` holds items; `CartItem` computes its own line; `CheckoutService` orchestrates; strategies price. Nobody knows about all four. |
| **Open/Closed**                 | Adding a discount is a new class, not a change to `Cart`. Adding a channel for price drops is a new subscriber, not a change to `Product`. |
| **Dependency Inversion**        | `CheckoutService` depends on an injected `notifier` (defaults to console). Swappable for tests without touching production code. |
| **Meaningful names**            | `PRICING.FREE_SHIPPING_MIN` beats `50`. `PercentageDiscount` beats `it.discount === "percent"`. |
| **Small functions**             | The longest method in `final/` (`OrderMinimumDiscount.apply`) is 4 lines. |
| **No mutable globals**          | Everything is instance-scoped. Two carts / two services never bleed into each other. |
| **Fail loudly at boundaries**   | `Product`, `CartItem`, `ProductBuilder`, `CheckoutService` all validate inputs and throw with a clear message. |

---

## Trade-offs & things left out

- **Persistence** — everything is in memory. A real system would put a `CartRepository` behind a port.
- **Currency** — floats are used for prices to keep the code short; real production code would use integer minor units to avoid rounding drift.
- **Async notification** — the observer is synchronous. For a real store, a queue-backed adapter would be a natural next step.
- **Composite discount** — you can currently attach one strategy per line. A `CompositeDiscount` combining several would be the natural next iteration.

---

## Verification

- **v0 total** on the demo scenario: `$64.80`
- **Refactored total** on the same scenario: `$64.80`
- **Unit tests**: `10 passed, 0 failed` (`npm test`).
