// Express server — API + static React build in one process.
//
//   /api/users*  -> mongoose CRUD
//   *            -> React SPA (index.html), so the client-side router
//                   handles unknown paths instead of a 404.

const path     = require("path");
const express  = require("express");
const mongoose = require("mongoose");
const cors     = require("cors");
require("dotenv").config();

const usersRouter = require("./routes/users");

const PORT        = Number(process.env.PORT) || 3000;
const MONGO_URI   = process.env.MONGO_URI;
const CORS_ORIGIN = process.env.CORS_ORIGIN;   // dev-only cross-origin allowlist

if (!MONGO_URI) {
  console.error("MONGO_URI is not set. Copy .env.example -> .env and fill it in.");
  process.exit(1);
}

// --- MongoDB
mongoose
  .connect(MONGO_URI)
  .then(() => console.log(`[mongoose] connected`))
  .catch((err) => {
    console.error(`[mongoose] connection failed: ${err.message}`);
    process.exit(1);
  });

// --- Express
const app = express();
app.use(express.json({ limit: "100kb" }));

// CORS is only useful in dev, when the Vite server (5173) calls the API (3000).
// In production the React build is served by this same server → same origin.
if (CORS_ORIGIN) app.use(cors({ origin: CORS_ORIGIN, credentials: false }));

app.use("/api/users", usersRouter);
app.get("/api/health", (req, res) => res.json({ ok: true }));

// --- Static React (production only — the build lives in server/public)
const staticDir = path.join(__dirname, "public");
app.use(express.static(staticDir));
app.get(/^\/(?!api).*/, (req, res) => {
  res.sendFile(path.join(staticDir, "index.html"), (err) => {
    // if the build hasn't been created yet, tell the developer clearly
    if (err) res.status(404).json({
      error: "React build not found. Run `npm run postinstall` (or `npm install`).",
    });
  });
});

// --- Centralised error handler
app.use((err, req, res, next) => { // eslint-disable-line no-unused-vars
  if (err.name === "ValidationError") return res.status(400).json({ error: err.message });
  if (err.code === 11000)             return res.status(409).json({ error: `duplicate value: ${JSON.stringify(err.keyValue)}` });
  console.error("[server] unhandled:", err);
  res.status(500).json({ error: "internal server error" });
});

app.listen(PORT, () => console.log(`[server] listening on http://localhost:${PORT}`));

module.exports = app;
