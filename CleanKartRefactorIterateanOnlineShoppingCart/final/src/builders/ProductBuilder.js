// Builder pattern for Product.
//
// Product has 3 required fields (id, name, price) and 4 optional ones
// (category, sku, description, tags). Passing them in a positional
// constructor becomes fragile fast — the builder gives a fluent API,
// enforces required fields at build() time, and lets callers add only
// the optional bits they care about.
//
// Usage:
//   const book = new ProductBuilder()
//     .withId("P-1").withName("Clean Code").withPrice(30)
//     .withCategory("book").withTags(["tech", "bestseller"])
//     .build();

import { Product } from "../models/Product.js";

export class ProductBuilder {
  #data;

  constructor() { this.#data = {}; }

  withId(id)                   { this.#data.id = id; return this; }
  withName(name)               { this.#data.name = name; return this; }
  withPrice(price)             { this.#data.price = price; return this; }
  withCategory(category)       { this.#data.category = category; return this; }
  withSku(sku)                 { this.#data.sku = sku; return this; }
  withDescription(description) { this.#data.description = description; return this; }
  withTags(tags)               { this.#data.tags = tags; return this; }
  addTag(tag) {
    this.#data.tags = [...(this.#data.tags ?? []), tag];
    return this;
  }

  build() {
    if (!this.#data.id)                                throw new Error("ProductBuilder: id is required");
    if (!this.#data.name)                              throw new Error("ProductBuilder: name is required");
    if (this.#data.price == null)                      throw new Error("ProductBuilder: price is required");
    return new Product(this.#data);
  }
}
