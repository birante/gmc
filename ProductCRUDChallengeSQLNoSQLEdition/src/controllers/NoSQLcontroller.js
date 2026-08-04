// NoSQL (MongoDB / Mongoose) controller for the Product resource.
// Same public contract as the SQL controller — a client can hit either
// mount point and behave identically.

const mongoose = require("mongoose");
const Product = require("../models/Product");

function validatePayload(body, { partial = false } = {}) {
  const errors = [];
  if (!partial && typeof body.name !== "string")            errors.push("name (string) is required");
  if (body.name !== undefined && typeof body.name !== "string") errors.push("name must be a string");
  if (!partial && (typeof body.price !== "number" || body.price < 0))
    errors.push("price (positive number) is required");
  if (body.price !== undefined && (typeof body.price !== "number" || body.price < 0))
    errors.push("price must be a positive number");
  if (body.category !== undefined && body.category !== null && typeof body.category !== "string")
    errors.push("category must be a string or null");
  if (body.inStock !== undefined && typeof body.inStock !== "boolean")
    errors.push("inStock must be a boolean");
  return errors;
}

exports.create = async (req, res) => {
  const errs = validatePayload(req.body ?? {});
  if (errs.length) return res.status(400).json({ errors: errs });
  const product = await Product.create(req.body);
  res.status(201).json({ product });
};

exports.readAll = async (req, res) => {
  const products = await Product.find().sort({ createdAt: -1 });
  res.json({ products });
};

exports.readOne = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ error: "Invalid id" });
  }
  const product = await Product.findById(req.params.id);
  if (!product) return res.status(404).json({ error: "Product not found" });
  res.json({ product });
};

exports.update = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ error: "Invalid id" });
  }
  const errs = validatePayload(req.body ?? {}, { partial: true });
  if (errs.length) return res.status(400).json({ errors: errs });

  const product = await Product.findByIdAndUpdate(
    req.params.id, req.body, { new: true, runValidators: true },
  );
  if (!product) return res.status(404).json({ error: "Product not found" });
  res.json({ product });
};

exports.remove = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ error: "Invalid id" });
  }
  const result = await Product.findByIdAndDelete(req.params.id);
  if (!result) return res.status(404).json({ error: "Product not found" });
  res.status(204).end();
};
