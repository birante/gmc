// models/User.js — Mongoose schema and model for the Users collection.
// Any field the API needs to persist must be declared here so it survives
// Mongoose's default strict-mode filter on save.

const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    // Human-readable name — required so we always know who a user is.
    name: {
      type: String,
      required: [true, "name is required"],
      trim: true,
    },

    // Email — required and unique so two accounts can't collide.
    // Mongoose's built-in `match` regex keeps obviously malformed inputs
    // out at write time; downstream validation should still verify.
    email: {
      type: String,
      required: [true, "email is required"],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^[^\s@]+@[^\s@]+\.[^\s@]+$/, "invalid email"],
    },

    // Age — optional. CHECK is not a Mongoose primitive so we express
    // the "adult only" bound via `min` (which becomes a validator).
    age: {
      type: Number,
      min: [0, "age must be >= 0"],
    },
  },
  {
    timestamps: true,   // adds createdAt + updatedAt for free
  },
);

module.exports = mongoose.model("User", userSchema);
