// smoke.js — quick end-to-end test that hits the four routes on a
// running server via node:http. Not a substitute for Postman, but
// useful for CI or when you just want a "does it work?" answer.

const http = require("node:http");

const HOST = process.env.HOST || "127.0.0.1";
const PORT = Number(process.env.PORT) || 5000;

function request(method, path, body) {
  return new Promise((resolve, reject) => {
    const headers = body ? { "Content-Type": "application/json" } : {};
    const req = http.request({ host: HOST, port: PORT, path, method, headers }, (res) => {
      const chunks = [];
      res.on("data", (c) => chunks.push(c));
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

async function main() {
  console.log("--- users-rest-api smoke ---");

  // POST — create a user
  const created = await request("POST", "/users", {
    name: "Alice Diop",
    email: `alice.${Date.now()}@example.com`,
    age: 28,
  });
  if (created.status !== 201) throw new Error(`POST /users -> ${created.status}: ${created.raw}`);
  const id = created.body.user._id;
  console.log(`POST   /users        -> 201 (id=${id})`);

  // GET — list users
  const list = await request("GET", "/users");
  if (list.status !== 200)             throw new Error("GET /users failed");
  if (!Array.isArray(list.body.users)) throw new Error("GET /users did not return an array");
  console.log(`GET    /users        -> 200 (${list.body.users.length} users)`);

  // PUT — update age
  const updated = await request("PUT", `/users/${id}`, { age: 29 });
  if (updated.status !== 200 || updated.body.user.age !== 29) {
    throw new Error(`PUT /users/:id failed: ${updated.status} ${updated.raw}`);
  }
  console.log(`PUT    /users/:id    -> 200 (age now ${updated.body.user.age})`);

  // DELETE — remove the user
  const removed = await request("DELETE", `/users/${id}`);
  if (removed.status !== 204) throw new Error(`DELETE /users/:id -> ${removed.status}`);
  console.log(`DELETE /users/:id    -> 204`);

  // Verify GET no longer includes it
  const followUp = await request("GET", "/users");
  if (followUp.body.users.some((u) => u._id === id)) {
    throw new Error("user still present after DELETE");
  }
  console.log("verified deletion via GET");

  console.log("\nall four routes green.");
}

main().catch((err) => {
  console.error("smoke test failed:", err.message);
  process.exit(1);
});
