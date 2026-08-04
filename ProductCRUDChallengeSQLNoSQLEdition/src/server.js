const { createApp } = require("./app");
const { connectMongo } = require("./db/mongoConnect");
const { getPool, ensureSchema } = require("./db/mysqlPool");

const PORT = Number(process.env.PORT) || 3000;
const app  = createApp();

app.listen(PORT, () => {
  console.log(`server listening on http://localhost:${PORT}`);

  // Warm up connections in the background — routes still work if these
  // fail (the per-route middleware retries).
  connectMongo().catch(() => {});
  (async () => {
    try { await getPool(); await ensureSchema(); }
    catch (err) { console.warn(`[mysql] warm-up failed: ${err.code || err.message}`); }
  })();
});
