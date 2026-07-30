// Line item in a cart. Immutable in identity (product + quantity are
// what the checkout receives); the discount strategy is per-line so
// different products can be discounted differently.

import { NoDiscount } from "../strategies/discountStrategies.js";

export class CartItem {
  #product;
  #quantity;
  #discount;

  constructor({ product, quantity, discount = new NoDiscount() }) {
    if (!product) throw new Error("CartItem requires a product");
    if (!Number.isInteger(quantity) || quantity <= 0) {
      throw new Error("CartItem quantity must be a positive integer");
    }
    this.#product = product;
    this.#quantity = quantity;
    this.#discount = discount;
  }

  get product()  { return this.#product; }
  get quantity() { return this.#quantity; }
  get discount() { return this.#discount; }

  get lineTotalBeforeDiscount() {
    return this.#product.price * this.#quantity;
  }

  lineTotal(cart) {
    return this.#discount.apply(this.lineTotalBeforeDiscount, this, cart);
  }
}
