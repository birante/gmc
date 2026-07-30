// Observer pattern for price drops.
//
// v0's priceDrop() was a TODO that just printed. Here, PriceMonitor is a
// tiny pub/sub between products and interested users. Watchers subscribe
// on a specific product; when Product.updatePrice() lowers the price,
// every watcher receives an event carrying old/new price.

export class PriceMonitor {
  #watchers;   // product -> Set<listenerFn>

  constructor() { this.#watchers = new Map(); }

  watch(product, listener) {
    if (!this.#watchers.has(product)) {
      const set = new Set();
      this.#watchers.set(product, set);
      product.addListener(evt => {
        for (const fn of set) fn(evt);
      });
    }
    this.#watchers.get(product).add(listener);
  }

  unwatch(product, listener) {
    this.#watchers.get(product)?.delete(listener);
  }
}

// Convenience listener that formats a user-facing message.
export function notifyUser(user) {
  return ({ product, oldPrice, newPrice }) => {
    console.log(
      `[price-drop -> ${user.name} <${user.email}>] ${product.name}: `
      + `${oldPrice.toFixed(2)} -> ${newPrice.toFixed(2)}`
    );
  };
}
