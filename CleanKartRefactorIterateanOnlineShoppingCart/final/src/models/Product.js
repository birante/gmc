// Product is a rich domain object. Construction is delegated to
// ProductBuilder so callers do not have to remember argument order or
// pass undefined for optional fields.
//
// The price setter is the only mutable field, so we can notify observers
// when it changes (see observers/priceMonitor.js).

export class Product {
  #id;
  #name;
  #price;
  #category;
  #sku;
  #description;
  #tags;
  #listeners;

  constructor({ id, name, price, category, sku, description, tags }) {
    if (!id)   throw new Error("Product.id is required");
    if (!name) throw new Error("Product.name is required");
    if (price == null || price < 0) throw new Error("Product.price must be >= 0");
    this.#id = id;
    this.#name = name;
    this.#price = price;
    this.#category = category ?? "misc";
    this.#sku = sku ?? id;
    this.#description = description ?? "";
    this.#tags = Object.freeze([...(tags ?? [])]);
    this.#listeners = new Set();
  }

  get id()          { return this.#id; }
  get name()        { return this.#name; }
  get price()       { return this.#price; }
  get category()    { return this.#category; }
  get sku()         { return this.#sku; }
  get description() { return this.#description; }
  get tags()        { return this.#tags; }

  addListener(fn)    { this.#listeners.add(fn); }
  removeListener(fn) { this.#listeners.delete(fn); }

  updatePrice(newPrice) {
    if (newPrice < 0) throw new Error("Price cannot be negative");
    const oldPrice = this.#price;
    this.#price = newPrice;
    if (newPrice < oldPrice) {
      for (const fn of this.#listeners) fn({ product: this, oldPrice, newPrice });
    }
  }
}
