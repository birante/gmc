// Smoke test — hits both /mongo/* and /mysql/* against real DBs.
// If a DB is not reachable the corresponding section is SKIPPED with a
// friendly message instead of failing, so the test can be run without
// standing up both stacks.

const http = require("node:http");
const { createApp } = require("../src/app");
const { connectMongo, isConnected } = require("../src/db/mongoConnect");
const { getPool } = require("../src/db/mysqlPool");

let pass = 0, fail = 0, skip = 0;
const server = createApp().listen(0, "127.0.0.1");
let port;

function req(method, path, body) {
  return new Promise((resolve, reject) => {
    const headers = body ? { "Content-Type": "application/json" } : {};
    const r = http.request({ host: "127.0.0.1", port, path, method, headers }, res => {
      const chunks = [];
      res.on("data", c => chunks.push(c));
      res.on("end", () => {
        const raw = Buffer.concat(chunks).toString("utf8");
        let json = null; try { json = raw ? JSON.parse(raw) : null; } catch {}
        resolve({ status: res.statusCode, body: json });
      });
    });
    r.on("error", reject);
    if (body) r.write(JSON.stringify(body));
    r.end();
  });
}

async function runCrud(prefix, label) {
  console.log(`\n--- CRUD via ${label} (${prefix}) ---`);
  const t = async (name, fn) => {
    try { await fn(); console.log(`  ok   ${name}`); pass++; }
    catch (e) { console.error(`  FAIL ${name}\n       ${e.message}`); fail++; }
  };

  let created;
  await t("POST /products creates a product (201)", async () => {
    const r = await req("POST", `${prefix}/products`, {
      name: "Test Widget", price: 9.99, category: "gadgets", inStock: true,
    });
    if (r.status !== 201) throw new Error(`status ${r.status} body=${JSON.stringify(r.body)}`);
    if (!r.body.product.id && !r.body.product._id) throw new Error("no id in response");
    created = r.body.product;
  });

  await t("GET /products returns an array with the new product", async () => {
    const r = await req("GET", `${prefix}/products`);
    if (r.status !== 200) throw new Error(`status ${r.status}`);
    if (!Array.isArray(r.body.products) || r.body.products.length === 0)
      throw new Error("empty list");
  });

  await t("GET /products/:id returns the product", async () => {
    const id = created.id ?? created._id;
    const r = await req("GET", `${prefix}/products/${id}`);
    if (r.status !== 200) throw new Error(`status ${r.status}`);
    if (r.body.product.name !== "Test Widget") throw new Error("wrong product");
  });

  await t("PUT /products/:id updates the product", async () => {
    const id = created.id ?? created._id;
    const r = await req("PUT", `${prefix}/products/${id}`, { price: 12.50, inStock: false });
    if (r.status !== 200) throw new Error(`status ${r.status}`);
    if (Number(r.body.product.price) !== 12.50) throw new Error("price not updated");
    if (r.body.product.inStock !== false) throw new Error("inStock not updated");
  });

  await t("DELETE /products/:id removes it (204)", async () => {
    const id = created.id ?? created._id;
    const r = await req("DELETE", `${prefix}/products/${id}`);
    if (r.status !== 204) throw new Error(`status ${r.status}`);
    const after = await req("GET", `${prefix}/products/${id}`);
    if (after.status !== 404) throw new Error("still fetchable after delete");
  });

  await t("POST /products rejects missing name (400)", async () => {
    const r = await req("POST", `${prefix}/products`, { price: 1 });
    if (r.status !== 400) throw new Error(`status ${r.status}`);
  });
}

async function checkMongo() {
  try { await connectMongo(); return isConnected(); }
  catch { return false; }
}

async function checkMysql() {
  try {
    const p = await getPool();
    const c = await p.getConnection();
    c.release();
    return true;
  } catch { return false; }
}

async function main() {
  await new Promise(r => server.on("listening", r));
  port = server.address().port;

  if (await checkMongo()) await runCrud("/mongo", "MongoDB / Mongoose");
  else                    { console.log("\n[SKIP] MongoDB unreachable — set MONGO_URI or start a local server"); skip++; }

  if (await checkMysql()) await runCrud("/mysql", "MySQL / mysql2");
  else                    { console.log("\n[SKIP] MySQL unreachable — set MYSQL_* env vars or start a local server"); skip++; }

  console.log(`\n${pass} passed, ${fail} failed, ${skip} DB(s) skipped.`);
  server.close();
  process.exit(fail > 0 ? 1 : 0);
}

main().catch(err => { console.error("harness crashed:", err); server.close(); process.exit(1); });
