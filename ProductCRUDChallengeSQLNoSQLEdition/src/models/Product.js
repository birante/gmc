// Mongoose schema for the Product resource.
// The SQL side has an equivalent table defined in ../sql/init.sql.

const mongoose = require("mongoose");

const productSchema = new mongoose.Schema(
  {
    name:     { type: String,  required: true, trim: true },
    price:    { type: Number,  required: true, min: 0 },
    category: { type: String,  default: null,  trim: true },
    inStock:  { type: Boolean, default: true },
  },
  { timestamps: true },
);

module.exports = mongoose.model("Product", productSchema);
