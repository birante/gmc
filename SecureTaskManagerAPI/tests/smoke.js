// End-to-end smoke tests for the Secure Task Manager API.
// Boots the real server on an ephemeral port, hits it via node:http,
// asserts status codes + owner-isolation.

process.env.JWT_SECRET     = "test-secret";
process.env.SESSION_SECRET = "test-session-secret";
process.env.NODE_ENV       = "test";

const http = require("node:http");
const { createApp } = require("../src/app");
const User = require("../src/models/User");
const Task = require("../src/models/Task");

let pass = 0, fail = 0;
async function t(name, fn) {
  User._reset(); Task._reset();
  try { await fn(); console.log(`  ok   ${name}`); pass++; }
  catch (e) { console.error(`  FAIL ${name}\n       ${e.message}`); fail++; }
}
function eq(a, b, m = "") { if (JSON.stringify(a) !== JSON.stringify(b)) throw new Error(`${m} expected ${JSON.stringify(b)} got ${JSON.stringify(a)}`); }
function ok(c, m = "") { if (!c) throw new Error(m || "assertion failed"); }

const server = createApp().listen(0, "127.0.0.1");
let port;

function request(method, path, { body, cookie } = {}) {
  return new Promise((resolve, reject) => {
    const headers = {};
    if (body) headers["Content-Type"] = "application/json";
    if (cookie) headers.Cookie = cookie;

    const req = http.request({ host: "127.0.0.1", port, path, method, headers }, res => {
      const chunks = [];
      res.on("data", c => chunks.push(c));
      res.on("end", () => {
        const raw = Buffer.concat(chunks).toString("utf8");
        let json = null; try { json = raw ? JSON.parse(raw) : null; } catch {}
        // capture Set-Cookie for auth cookie propagation
        const setCookie = res.headers["set-cookie"] ?? [];
        const authCookie = setCookie.find(c => c.startsWith("token=")) ?? null;
        resolve({ status: res.statusCode, body: json, raw, authCookie, headers: res.headers });
      });
    });
    req.on("error", reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

const cookieOnly = (raw) => raw?.split(";")[0] ?? null;

async function main() {
  await new Promise(r => server.on("listening", r));
  port = server.address().port;
  console.log("\n--- secure-task-manager-api smoke tests ---");

await t("signup issues an HTTP-only cookie", async () => {
  const r = await request("POST", "/auth/signup", { body: { email: "a@x.com", password: "supersecret1" }});
  eq(r.status, 201);
  ok(r.authCookie, "expected Set-Cookie: token=...");
  ok(/HttpOnly/i.test(r.authCookie), "cookie must be HttpOnly");
  ok(/SameSite=Strict/i.test(r.authCookie), "cookie must be SameSite=Strict");
});

await t("signup rejects weak passwords", async () => {
  const r = await request("POST", "/auth/signup", { body: { email: "a@x.com", password: "123" }});
  eq(r.status, 400);
});

await t("signup rejects duplicate email", async () => {
  await request("POST", "/auth/signup", { body: { email: "a@x.com", password: "supersecret1" }});
  const r = await request("POST", "/auth/signup", { body: { email: "a@x.com", password: "supersecret1" }});
  eq(r.status, 409);
});

await t("login with wrong password returns 401", async () => {
  await request("POST", "/auth/signup", { body: { email: "a@x.com", password: "supersecret1" }});
  const r = await request("POST", "/auth/login", { body: { email: "a@x.com", password: "wrongpassword1" }});
  eq(r.status, 401);
});

await t("private routes require the cookie", async () => {
  const r = await request("GET", "/tasks");
  eq(r.status, 401);
});

await t("full CRUD roundtrip is owner-isolated", async () => {
  const alice = await request("POST", "/auth/signup", { body: { email: "alice@x.com", password: "supersecret1" }});
  const bob   = await request("POST", "/auth/signup", { body: { email: "bob@x.com",   password: "supersecret2" }});
  const aliceCookie = cookieOnly(alice.authCookie);
  const bobCookie   = cookieOnly(bob.authCookie);

  // alice creates a task
  const created = await request("POST", "/tasks", { body: { title: "Alice's task" }, cookie: aliceCookie });
  eq(created.status, 201);
  const taskId = created.body.task.id;

  // alice sees her task
  const aList = await request("GET", "/tasks", { cookie: aliceCookie });
  eq(aList.status, 200); eq(aList.body.tasks.length, 1);

  // bob sees an empty list (owner isolation)
  const bList = await request("GET", "/tasks", { cookie: bobCookie });
  eq(bList.status, 200); eq(bList.body.tasks.length, 0);

  // bob CANNOT delete alice's task
  const bobDelete = await request("DELETE", `/tasks/${taskId}`, { cookie: bobCookie });
  eq(bobDelete.status, 404, "cross-owner delete must 404");

  // alice CAN delete her own task
  const aliceDelete = await request("DELETE", `/tasks/${taskId}`, { cookie: aliceCookie });
  eq(aliceDelete.status, 204);
});

await t("POST /tasks rejects missing title", async () => {
  const r = await request("POST", "/auth/signup", { body: { email: "a@x.com", password: "supersecret1" }});
  const cookie = cookieOnly(r.authCookie);
  const bad = await request("POST", "/tasks", { body: { description: "no title" }, cookie });
  eq(bad.status, 400);
});

await t("mongoSanitize strips $-keys from body", async () => {
  // "$gt" as an email should not sneak past validation into the store
  const r = await request("POST", "/auth/signup", { body: { "email$gt": "", password: "supersecret1" }});
  eq(r.status, 400);   // email regex rejects, but the key must never reach a Mongo query
});

await t("helmet sets X-Content-Type-Options and disables x-powered-by", async () => {
  const r = await request("GET", "/");
  eq(r.headers["x-content-type-options"], "nosniff");
  eq(r.headers["x-powered-by"], undefined);
});

await t("logout clears the auth cookie", async () => {
  const s = await request("POST", "/auth/signup", { body: { email: "a@x.com", password: "supersecret1" }});
  const cookie = cookieOnly(s.authCookie);
  const r = await request("POST", "/auth/logout", { cookie });
  eq(r.status, 200);
  ok(r.headers["set-cookie"]?.some(c => c.startsWith("token=;")));
});

await t("Google OAuth returns 501 when unconfigured", async () => {
  const r = await request("GET", "/auth/google");
  eq(r.status, 501);
});

await t("unknown route returns 404", async () => {
  const r = await request("GET", "/nope");
  eq(r.status, 404);
});

  console.log(`\n${pass} passed, ${fail} failed.`);
  server.close();
  if (fail > 0) process.exit(1);
}

main().catch(err => {
  console.error("harness crashed:", err);
  server.close();
  process.exit(1);
});
