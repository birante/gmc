// Strategy pattern for discounts.
//
// v0 had an if/else ladder inside calculate(). Every new discount
// (student, seasonal, coupon…) forced editing that function — closed
// against extension, wide open to bugs. Each strategy is now a small
// object with a single method apply(lineTotal, item, cart) that returns
// the (possibly reduced) amount to charge.

class DiscountStrategy {
  apply(lineTotal /* number */, item /* CartItem */, cart /* Cart */) {
    throw new Error("DiscountStrategy.apply() not implemented");
  }
}

export class NoDiscount extends DiscountStrategy {
  apply(lineTotal) { return lineTotal; }
}

export class PercentageDiscount extends DiscountStrategy {
  #percent;
  constructor(percent) {
    super();
    if (percent < 0 || percent > 100) throw new Error("percent must be 0..100");
    this.#percent = percent;
  }
  apply(lineTotal) { return lineTotal * (1 - this.#percent / 100); }
}

export class FixedAmountDiscount extends DiscountStrategy {
  #amountPerUnit;
  constructor(amountPerUnit) {
    super();
    if (amountPerUnit < 0) throw new Error("amount must be >= 0");
    this.#amountPerUnit = amountPerUnit;
  }
  apply(_lineTotal, item) {
    const discounted = Math.max(0, item.product.price - this.#amountPerUnit);
    return discounted * item.quantity;
  }
}

export class BuyOneGetOneFree extends DiscountStrategy {
  apply(_lineTotal, item) {
    const paid = Math.ceil(item.quantity / 2);
    return item.product.price * paid;
  }
}

// Cart-wide strategy that could combine or override per-item strategies.
export class OrderMinimumDiscount extends DiscountStrategy {
  #threshold;
  #percent;
  constructor(threshold, percent) {
    super();
    this.#threshold = threshold;
    this.#percent = percent;
  }
  apply(lineTotal, _item, cart) {
    return cart.subtotal >= this.#threshold
      ? lineTotal * (1 - this.#percent / 100)
      : lineTotal;
  }
}
