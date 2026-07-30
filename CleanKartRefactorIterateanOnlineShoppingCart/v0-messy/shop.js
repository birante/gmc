// v0 — intentionally messy starter code.
// Kept exactly as it would look in a rushed prototype:
//   * mutable module-level state
//   * one function doing five things
//   * magic numbers everywhere (tax, shipping, thresholds)
//   * discount rules as an if/else ladder
//   * notifications hard-coded to console.log
//   * TODO left in the code
//
// This file is *not* meant to be edited. It exists so REPORT.md can point
// at every code smell. The refactored version lives in ../final/.

let cart = [];
let watchers = {};   // productName -> [emails]
let user = null;

function addItem(name, price, qty, category, discount, code) {
  cart.push({ name: name, price: price, qty: qty, category: category, discount: discount, code: code });
  console.log("Added " + name);
}

function calculate() {
  let total = 0;
  for (let i = 0; i < cart.length; i++) {
    let it = cart[i];
    if (it.discount === "percent") {
      total += it.price * it.qty * (1 - it.code / 100);
    } else if (it.discount === "fixed") {
      total += (it.price - it.code) * it.qty;
    } else if (it.discount === "bogo") {
      let paid = Math.ceil(it.qty / 2);
      total += it.price * paid;
    } else {
      total += it.price * it.qty;
    }
  }
  // shipping
  if (total < 50) {
    total += 10;
  }
  // tax
  total = total + total * 0.08;
  return total;
}

function checkout(u) {
  user = u;
  let t = calculate();
  console.log("Hi " + user.name + ", your total is $" + t.toFixed(2));
  // send email
  console.log("Sending email to " + user.email);
  cart = [];
  return t;
}

function watch(name, email) {
  if (!watchers[name]) watchers[name] = [];
  watchers[name].push(email);
}

function priceDrop(name, newPrice) {
  // TODO: notify users watching this product
  console.log(name + " is now " + newPrice);
}

// demo
addItem("Book",   20, 2, "media", "percent", 10);
addItem("Pen",     3, 5, "stationery", "bogo", 0);
addItem("Coffee", 15, 1, "food", "none", 0);
watch("Book", "alice@x");
console.log("Total:", checkout({ name: "Alice", email: "alice@x" }).toFixed(2));
priceDrop("Book", 15);
