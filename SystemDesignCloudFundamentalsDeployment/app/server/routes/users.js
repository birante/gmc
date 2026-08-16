// CRUD routes for /api/users.

const express = require("express");
const mongoose = require("mongoose");
const User = require("../models/User");

const router = express.Router();

// Small wrapper — forwards any async rejection to Express's error handler.
const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

// GET /api/users
router.get("/", wrap(async (req, res) => {
  const users = await User.find().sort({ createdAt: -1 });
  res.json({ users });
}));

// POST /api/users
router.post("/", wrap(async (req, res) => {
  const user = await User.create(req.body);
  res.status(201).json({ user });
}));

// PUT /api/users/:id
router.put("/:id", wrap(async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ error: "invalid id" });
  }
  const user = await User.findByIdAndUpdate(req.params.id, req.body, {
    new: true, runValidators: true,
  });
  if (!user) return res.status(404).json({ error: "user not found" });
  res.json({ user });
}));

// DELETE /api/users/:id
router.delete("/:id", wrap(async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ error: "invalid id" });
  }
  const user = await User.findByIdAndDelete(req.params.id);
  if (!user) return res.status(404).json({ error: "user not found" });
  res.status(204).end();
}));

module.exports = router;
