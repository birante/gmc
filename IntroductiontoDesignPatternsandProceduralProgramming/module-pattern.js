// Part 2 — Same behaviour, refactored with the Module pattern.
//
// The cart array is trapped inside the IIFE closure — there is no way for
// external code to reach it except through the returned public API.
// This gives us the encapsulation the procedural version lacked, without
// introducing classes.

const ShoppingCart = (function () {
  // --- private state
  let items = [];

  // --- private helpers
  function lineTotal(item) {
    return item.quantity * item.price;
  }

  function format(amount) {
    return `${amount.toFixed(2)} TND`;
  }

  // --- public API
  return {
    addItem(name, quantity, price) {
      if (!name)                                  throw new Error("addItem: name is required");
      if (!Number.isFinite(quantity) || quantity <= 0) throw new Error("addItem: quantity must be > 0");
      if (!Number.isFinite(price) || price < 0)   throw new Error("addItem: price must be >= 0");
      items.push({ name, quantity, price });
    },

    removeItem(name) {
      items = items.filter(item => item.name !== name);
    },

    clearCart() {
      items = [];
    },

    viewCart() {
      let total = 0;
      for (const item of items) {
        const line = lineTotal(item);
        total += line;
        console.log(`${item.name} (x${item.quantity}) - ${format(line)}`);
      }
      console.log(`Total: ${format(total)}`);
    },

    // Read-only snapshot — callers can inspect but not mutate the private state.
    get size() { return items.length; },
    snapshot()  { return items.map(i => ({ ...i })); },
  };
})();

// --- demo, same scenario as the procedural version
ShoppingCart.addItem("Apple",  2, 1.5);
ShoppingCart.addItem("Orange", 3, 2.0);
console.log("> viewCart()");
ShoppingCart.viewCart();

console.log("\n> removeItem(\"Apple\")");
ShoppingCart.removeItem("Apple");
console.log("> viewCart()");
ShoppingCart.viewCart();

// --- proof of encapsulation
console.log("\n> Attempting external tampering…");
console.log("  typeof ShoppingCart.items:", typeof ShoppingCart.items);   // undefined
try {
  ShoppingCart.items = [{ name: "Fraud", quantity: 999, price: 0 }];      // silently ignored
  console.log("  external assignment ignored, size is still", ShoppingCart.size);
} catch (e) {
  console.log("  external assignment rejected:", e.message);
}
