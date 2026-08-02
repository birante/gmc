// Part 1 — Procedural shopping cart.
// Deliberately follows the procedural style requested by the brief:
//   * a module-level variable holds the cart data
//   * free functions manipulate that shared variable
//   * no encapsulation, no objects

let cart = [];   // global-ish state — the "procedural" trait

function addItem(name, quantity, price) {
  cart.push({ name, quantity, price });
}

function removeItem(name) {
  cart = cart.filter(item => item.name !== name);
}

function clearCart() {
  cart = [];
}

function viewCart() {
  let total = 0;
  for (const item of cart) {
    const lineTotal = item.quantity * item.price;
    total += lineTotal;
    console.log(`${item.name} (x${item.quantity}) - ${lineTotal.toFixed(2)} TND`);
  }
  console.log(`Total: ${total.toFixed(2)} TND`);
}

// --- demo matching the brief's example
addItem("Apple", 2, 1.5);
addItem("Orange", 3, 2.0);
console.log("> viewCart()");
viewCart();

console.log("\n> removeItem(\"Apple\")");
removeItem("Apple");
console.log("> viewCart()");
viewCart();
