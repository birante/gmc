// server.js — Express + Mongoose REST API for the Users collection.
// Four routes as required by the brief:
//   GET    /users       -> return all users
//   POST   /users       -> add a new user
//   PUT    /users/:id   -> edit a user by id
//   DELETE /users/:id   -> remove a user by id

const path     = require("path");
const express  = require("express");
const mongoose = require("mongoose");

// Load environment variables from config/.env (not the default ./.env,
// which the brief explicitly places in a config/ folder).
require("dotenv").config({ path: path.join(__dirname, "config", ".env") });

const User = require("./models/User");

const PORT      = Number(process.env.PORT) || 5000;
const MONGO_URI = process.env.MONGO_URI;

if (!MONGO_URI) {
  console.error("MONGO_URI is not set. Copy config/.env.example -> config/.env");
  process.exit(1);
}

// ------------------------------------------------------------------------
// Database connection
// ------------------------------------------------------------------------
mongoose
  .connect(MONGO_URI)
  .then(() => console.log(`[mongoose] connected to ${MONGO_URI}`))
  .catch((err) => {
    console.error(`[mongoose] failed to connect: ${err.message}`);
    process.exit(1);
  });

// ------------------------------------------------------------------------
// Express app
// ------------------------------------------------------------------------
const app = express();
app.use(express.json({ limit: "100kb" }));   // parse JSON bodies

// Small helper so every async route handler funnels its errors into
// the centralised error middleware below — avoids sprinkling try/catch.
const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

// Health-check / index route — helpful when opening the URL in a browser.
app.get("/", (req, res) => {
  res.json({
    name: "users-rest-api",
    endpoints: [
      "GET    /users",
      "POST   /users",
      "PUT    /users/:id",
      "DELETE /users/:id",
    ],
  });
});

// ------------------------------------------------------------------------
// 1) GET /users  -> return all users
// ------------------------------------------------------------------------
app.get(
  "/users",
  asyncHandler(async (req, res) => {
    const users = await User.find().sort({ createdAt: -1 });
    res.json({ users });
  }),
);

// ------------------------------------------------------------------------
// 2) POST /users  -> add a new user
//    Mongoose validates the body against the schema (name, email, age).
// ------------------------------------------------------------------------
app.post(
  "/users",
  asyncHandler(async (req, res) => {
    const user = await User.create(req.body);
    res.status(201).json({ user });
  }),
);

// ------------------------------------------------------------------------
// 3) PUT /users/:id  -> edit a user by id
//    { new: true } returns the UPDATED document.
//    runValidators applies the schema's validators (required, match) on
//    the incoming patch, otherwise Mongoose skips them for updates.
// ------------------------------------------------------------------------
app.put(
  "/users/:id",
  asyncHandler(async (req, res) => {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ error: "invalid user id" });
    }
    const user = await User.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true },
    );
    if (!user) return res.status(404).json({ error: "user not found" });
    res.json({ user });
  }),
);

// ------------------------------------------------------------------------
// 4) DELETE /users/:id  -> remove a user by id
// ------------------------------------------------------------------------
app.delete(
  "/users/:id",
  asyncHandler(async (req, res) => {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({ error: "invalid user id" });
    }
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) return res.status(404).json({ error: "user not found" });
    res.status(204).end();
  }),
);

// ------------------------------------------------------------------------
// 404 + centralised error handler
// ------------------------------------------------------------------------
app.use((req, res) => res.status(404).json({ error: "route not found" }));

app.use((err, req, res, next) => { // eslint-disable-line no-unused-vars
  // Mongoose ValidationError -> 400, duplicate-key -> 409, else 500.
  if (err.name === "ValidationError") {
    return res.status(400).json({ error: err.message });
  }
  if (err.code === 11000) {
    return res.status(409).json({ error: `duplicate value: ${JSON.stringify(err.keyValue)}` });
  }
  console.error("[server] unhandled error:", err);
  res.status(500).json({ error: "internal server error" });
});

// ------------------------------------------------------------------------
// Start listening
// ------------------------------------------------------------------------
app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});

module.exports = app;
