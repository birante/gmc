// Mongoose model — one collection, `users`.

const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    name:  { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true,
             match: [/^[^\s@]+@[^\s@]+\.[^\s@]+$/, "invalid email"] },
    role:  { type: String, enum: ["admin", "member", "viewer"], default: "member" },
  },
  { timestamps: true },
);

module.exports = mongoose.model("User", userSchema);
