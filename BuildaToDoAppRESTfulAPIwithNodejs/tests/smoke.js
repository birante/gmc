// End-to-end smoke test. Boots the real HTTP server on port 0 (kernel
// picks a free one), issues real requests via node:http, asserts status
// codes and response bodies. No third-party libraries.

import http from "node:http";
import { createApp } from "../src/server.js";
import { _reset } from "../src/store.js";

let pass = 0, fail = 0;
const t = async (name, fn) => {
  try { await fn(); console.log(`  ok   ${name}`); pass++; }
  catch (e) { console.error(`  FAIL ${name}\n       ${e.message}`); fail++; }
};
const eq = (a, b, m = "") => { if (JSON.stringify(a) !== JSON.stringify(b)) throw new Error(`${m} expected ${JSON.stringify(b)} got ${JSON.stringify(a)}`); };

const server = createApp();
await new Promise(r => server.listen(0, "127.0.0.1", r));
const { port } = server.address();

function request(method, path, body) {
  return new Promise((resolve, reject) => {
    const req = http.request({
      host: "127.0.0.1", port, path, method,
      headers: body ? { "Content-Type": "application/json" } : {},
    }, res => {
      const chunks = [];
      res.on("data", c => chunks.push(c));
      res.on("end", () => {
        const raw = Buffer.concat(chunks).toString("utf8");
        let json = null; try { json = raw ? JSON.parse(raw) : null; } catch {}
        resolve({ status: res.statusCode, body: json, raw });
      });
    });
    req.on("error", reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

console.log("\n--- todo-restful-api smoke tests ---");

await t("GET  /todos returns empty list initially", async () => {
  _reset();
  const r = await request("GET", "/todos");
  eq(r.status, 200); eq(r.body, []);
});

await t("POST /todos with valid title creates a todo (201)", async () => {
  _reset();
  const r = await request("POST", "/todos", { title: "Write tests" });
  eq(r.status, 201);
  if (!r.body.id) throw new Error("no id returned");
  eq(r.body.title, "Write tests");
  eq(r.body.completed, false);
});

await t("POST /todos rejects missing title (400)", async () => {
  const r = await request("POST", "/todos", { completed: true });
  eq(r.status, 400);
});

await t("POST /todos rejects non-boolean completed (400)", async () => {
  const r = await request("POST", "/todos", { title: "x", completed: "yes" });
  eq(r.status, 400);
});

await t("POST /todos rejects invalid JSON body (400)", async () => {
  const r = await new Promise((resolve, reject) => {
    const req = http.request({
      host: "127.0.0.1", port, path: "/todos", method: "POST",
      headers: { "Content-Type": "application/json" },
    }, res => {
      const chunks = [];
      res.on("data", c => chunks.push(c));
      res.on("end", () => resolve({ status: res.statusCode }));
    });
    req.on("error", reject);
    req.write("{not json");
    req.end();
  });
  eq(r.status, 400);
});

await t("GET /todos/:id returns 404 for unknown id", async () => {
  const r = await request("GET", "/todos/does-not-exist");
  eq(r.status, 404);
});

await t("full CRUD roundtrip", async () => {
  _reset();
  const created = await request("POST", "/todos", { title: "Read book" });
  eq(created.status, 201);
  const id = created.body.id;

  const got = await request("GET", `/todos/${id}`);
  eq(got.status, 200);
  eq(got.body.title, "Read book");

  const patched = await request("PATCH", `/todos/${id}`, { completed: true });
  eq(patched.status, 200);
  eq(patched.body.completed, true);
  eq(patched.body.title, "Read book");   // title untouched

  const list = await request("GET", "/todos");
  eq(list.status, 200);
  eq(list.body.length, 1);

  const del = await request("DELETE", `/todos/${id}`);
  eq(del.status, 204);

  const gone = await request("GET", `/todos/${id}`);
  eq(gone.status, 404);
});

await t("PATCH /todos/:id returns 404 for unknown id", async () => {
  const r = await request("PATCH", "/todos/nope", { completed: true });
  eq(r.status, 404);
});

await t("PATCH /todos/:id rejects empty title (400)", async () => {
  _reset();
  const c = await request("POST", "/todos", { title: "x" });
  const r = await request("PATCH", `/todos/${c.body.id}`, { title: "   " });
  eq(r.status, 400);
});

await t("DELETE /todos/:id returns 404 for unknown id", async () => {
  const r = await request("DELETE", "/todos/nope");
  eq(r.status, 404);
});

await t("PUT is accepted as an alias for PATCH", async () => {
  _reset();
  const c = await request("POST", "/todos", { title: "x" });
  const r = await request("PUT", `/todos/${c.body.id}`, { title: "y" });
  eq(r.status, 200); eq(r.body.title, "y");
});

await t("Unknown method on /todos returns 405", async () => {
  const r = await request("PUT", "/todos");
  eq(r.status, 405);
});

await t("Unknown route returns 404", async () => {
  const r = await request("GET", "/foo/bar");
  eq(r.status, 404);
});

console.log(`\n${pass} passed, ${fail} failed.`);
server.close();
if (fail > 0) process.exit(1);
