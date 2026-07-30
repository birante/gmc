// Cart aggregates line items. No I/O, no shipping/tax logic — those
// live in CheckoutService. This class only knows how to add, remove, and
// sum lines, honouring each line's discount strategy.

import { CartItem } from "./CartItem.js";

export class Cart {
  #items;

  constructor() { this.#items = []; }

  get items()      { return [...this.#items]; }
  get itemCount()  { return this.#items.reduce((n, i) => n + i.quantity, 0); }
  get isEmpty()    { return this.#items.length === 0; }

  // Sum of raw prices, before any discount — used by cart-wide discount
  // strategies (e.g. OrderMinimumDiscount).
  get subtotal() {
    return this.#items.reduce((sum, i) => sum + i.lineTotalBeforeDiscount, 0);
  }

  // Sum after per-line discounts.
  get total() {
    return this.#items.reduce((sum, i) => sum + i.lineTotal(this), 0);
  }

  add({ product, quantity = 1, discount }) {
    this.#items.push(new CartItem({ product, quantity, discount }));
    return this;
  }

  removeByProductId(productId) {
    this.#items = this.#items.filter(i => i.product.id !== productId);
    return this;
  }

  clear() { this.#items = []; return this; }
}
