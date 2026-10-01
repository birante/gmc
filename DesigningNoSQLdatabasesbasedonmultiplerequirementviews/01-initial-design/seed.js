// =============================================================================
// Part 1 - Sample data (deterministic): 20 users, 40 products, 300 orders
// Run after schema.js:
//   mongosh "mongodb://localhost:27017/?replicaSet=rs0" 01-initial-design/seed.js
// =============================================================================

// Target database (override with: mongosh --eval 'var DB_NAME="other"' <file>)
const DB = typeof DB_NAME !== "undefined" ? DB_NAME : "shop";
const shop = db.getSiblingDB(DB);

// Small deterministic PRNG so every run produces the same data set
let seed = 42;
const rand = () => ((seed = (seed * 1103515245 + 12345) % 2147483648) / 2147483648);
const pick = (arr) => arr[Math.floor(rand() * arr.length)];
const randInt = (min, max) => Math.floor(rand() * (max - min + 1)) + min;
const D = (n) => NumberDecimal(n.toFixed(2));

shop.users.deleteMany({});
shop.products.deleteMany({});
shop.orders.deleteMany({});

// ---------------------------------------------------------------- users
const firstNames = ["Awa", "Moussa", "Fatou", "Ibrahima", "Aminata", "Cheikh", "Mariama", "Ousmane", "Khady", "Mamadou"];
const lastNames = ["Diop", "Ndiaye", "Fall", "Sow", "Ba"];
const cities = [["Dakar", "SN"], ["Thies", "SN"], ["Saint-Louis", "SN"], ["Paris", "FR"], ["Abidjan", "CI"]];

const users = [];
for (let i = 0; i < 20; i++) {
  const first = firstNames[i % firstNames.length];
  const last = lastNames[i % lastNames.length];
  const [city, country] = pick(cities);
  users.push({
    _id: new ObjectId(),
    email: `${first}.${last}${i}@example.com`.toLowerCase(),
    name: `${first} ${last}`,
    passwordHash: "$argon2id$v=19$m=65536,t=3,p=4$placeholder",
    phone: `+22177${String(1000000 + i)}`,
    addresses: [{ label: "home", street: `${randInt(1, 200)} Rue ${i}`, city, postalCode: "10000", country, isDefault: true }],
    createdAt: new Date(Date.now() - randInt(30, 400) * 86400000)
  });
}
shop.users.insertMany(users);

// ---------------------------------------------------------------- products
const catalog = [
  { cat: ["electronics", "phones"], brand: "Tecno", names: ["Spark 20 Smartphone", "Camon 30 Pro Smartphone", "Pova 6 Smartphone"], tags: ["android", "5g", "smartphone"], price: [90, 350] },
  { cat: ["electronics", "laptops"], brand: "Lenovo", names: ["IdeaPad Slim 3 Laptop", "ThinkPad E14 Laptop", "Yoga 7 Laptop"], tags: ["laptop", "windows", "ssd"], price: [450, 1400] },
  { cat: ["electronics", "audio"], brand: "Sony", names: ["WH-1000XM5 Wireless Headphones", "WF-C700N Earbuds", "SRS-XB100 Bluetooth Speaker"], tags: ["wireless", "bluetooth", "noise cancelling"], price: [50, 380] },
  { cat: ["fashion", "shoes"], brand: "Adidas", names: ["Ultraboost Running Shoes", "Samba OG Sneakers", "Terrex Hiking Boots"], tags: ["running", "sport", "shoes"], price: [70, 190] },
  { cat: ["fashion", "clothing"], brand: "Wax Studio", names: ["Wax Print Shirt", "Bazin Boubou", "Cotton Kaftan Dress"], tags: ["cotton", "african print", "handmade"], price: [25, 120] },
  { cat: ["home", "kitchen"], brand: "Moulinex", names: ["Easy Fry Air Fryer", "Blender Smoothie Pro", "Electric Kettle 1.7L"], tags: ["kitchen", "appliance", "cooking"], price: [30, 160] },
  { cat: ["books", "programming"], brand: "O'Reilly", names: ["Designing Data-Intensive Applications", "MongoDB: The Definitive Guide", "Learning SQL"], tags: ["database", "nosql", "programming"], price: [30, 60] }
];

const products = [];
let skuN = 1000;
catalog.forEach((group) => {
  group.names.forEach((name) => {
    // two variants per product name (e.g. colours) -> ~42 products
    ["Black", "Blue"].forEach((color) => {
      const price = group.price[0] + rand() * (group.price[1] - group.price[0]);
      products.push({
        _id: new ObjectId(),
        sku: `SKU-${skuN++}`,
        name: `${group.brand} ${name} (${color})`,
        description: `${name} by ${group.brand}. Colour ${color.toLowerCase()}. ${group.tags.join(", ")}. Fast delivery in Senegal and West Africa.`,
        brand: group.brand,
        price: D(price),
        currency: "EUR",
        category: { id: group.cat.join("/"), path: group.cat },
        tags: group.tags,
        attributes: { color },
        images: [`https://cdn.example.com/p/${skuN}.jpg`],
        stock: NumberInt(randInt(0, 500)),
        rating: { avg: Math.round((3 + rand() * 2) * 10) / 10, count: NumberInt(randInt(0, 900)) },
        status: rand() < 0.95 ? "active" : "draft",
        createdAt: new Date(Date.now() - randInt(60, 365) * 86400000),
        updatedAt: new Date()
      });
    });
  });
});
shop.products.insertMany(products);

// ---------------------------------------------------------------- orders
const statuses = ["pending", "paid", "shipped", "delivered", "delivered", "delivered", "cancelled"];
const flow = ["pending", "paid", "shipped", "delivered"];
const orders = [];
for (let i = 0; i < 300; i++) {
  const u = pick(users);
  const createdAt = new Date(Date.now() - randInt(0, 29) * 86400000 - randInt(0, 86399) * 1000);
  const items = [];
  const nItems = randInt(1, 4);
  const used = new Set();
  for (let k = 0; k < nItems; k++) {
    const p = pick(products);
    if (used.has(p.sku)) continue;
    used.add(p.sku);
    items.push({ productId: p._id, sku: p.sku, name: p.name, unitPrice: p.price, quantity: NumberInt(randInt(1, 3)) });
  }
  const subtotal = items.reduce((s, it) => s + parseFloat(it.unitPrice.toString()) * it.quantity, 0);
  const shipping = subtotal > 100 ? 0 : 5;
  const status = pick(statuses);
  const history = [];
  if (status === "cancelled") {
    history.push({ status: "pending", at: createdAt }, { status: "cancelled", at: new Date(Math.min(createdAt.getTime() + 3600000, Date.now())), note: "customer request" });
  } else {
    for (let s = 0; s <= flow.indexOf(status); s++) history.push({ status: flow[s], at: new Date(Math.min(createdAt.getTime() + s * 86400000, Date.now())) });
  }
  orders.push({
    orderNumber: `ORD-2026-${String(i + 1).padStart(6, "0")}`,
    customer: { id: u._id, name: u.name, email: u.email },
    items,
    totals: { subtotal: D(subtotal), shipping: D(shipping), grandTotal: D(subtotal + shipping), currency: "EUR" },
    shippingAddress: u.addresses[0],
    payment: { method: pick(["card", "mobile_money", "cash_on_delivery"]), transactionId: `TX${100000 + i}` },
    status,
    delivery: ["shipped", "delivered"].includes(status)
      ? { carrier: pick(["DHL", "La Poste", "Yango"]), trackingNumber: `TRK${200000 + i}`, estimatedAt: new Date(createdAt.getTime() + 4 * 86400000) }
      : {},
    statusHistory: history,
    version: NumberInt(history.length),
    createdAt,
    updatedAt: history[history.length - 1].at
  });
}
shop.orders.insertMany(orders);

print(`Seeded: ${shop.users.countDocuments()} users, ${shop.products.countDocuments()} products, ${shop.orders.countDocuments()} orders`);
