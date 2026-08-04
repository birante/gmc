// SQL (MySQL / mysql2) controller for the Product resource.
// Every value passed into a query goes through a placeholder — no string
// interpolation of user input, no SQL injection.

const { getPool, ensureSchema } = require("../db/mysqlPool");

// Convert a DB row (snake_case, in_stock as 0/1) into the JSON shape
// the API returns (camelCase, boolean).
function rowToProduct(row) {
  if (!row) return null;
  return {
    id:        row.id,
    name:      row.name,
    price:     Number(row.price),         // DECIMAL comes back as string in mysql2
    category:  row.category,
    inStock:   Boolean(row.in_stock),
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

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

  await ensureSchema();
  const pool = await getPool();

  const { name, price, category = null, inStock = true } = req.body;
  const [result] = await pool.execute(
    "INSERT INTO products (name, price, category, in_stock) VALUES (?, ?, ?, ?)",
    [name, price, category, inStock],
  );
  const [[row]] = await pool.execute("SELECT * FROM products WHERE id = ?", [result.insertId]);
  res.status(201).json({ product: rowToProduct(row) });
};

exports.readAll = async (req, res) => {
  await ensureSchema();
  const pool = await getPool();
  const [rows] = await pool.execute("SELECT * FROM products ORDER BY created_at DESC");
  res.json({ products: rows.map(rowToProduct) });
};

exports.readOne = async (req, res) => {
  await ensureSchema();
  const pool = await getPool();
  const [rows] = await pool.execute("SELECT * FROM products WHERE id = ?", [req.params.id]);
  if (rows.length === 0) return res.status(404).json({ error: "Product not found" });
  res.json({ product: rowToProduct(rows[0]) });
};

exports.update = async (req, res) => {
  const errs = validatePayload(req.body ?? {}, { partial: true });
  if (errs.length) return res.status(400).json({ errors: errs });

  await ensureSchema();
  const pool = await getPool();

  // Build a dynamic SET clause using named columns — still fully
  // parameterized (only column NAMES are interpolated, values stay in
  // placeholders).
  const columnMap = { name: "name", price: "price", category: "category", inStock: "in_stock" };
  const sets = [];
  const values = [];
  for (const [key, col] of Object.entries(columnMap)) {
    if (req.body[key] !== undefined) {
      sets.push(`${col} = ?`);
      values.push(req.body[key]);
    }
  }
  if (sets.length === 0) return res.status(400).json({ error: "No updatable fields provided" });

  values.push(req.params.id);
  const [result] = await pool.execute(
    `UPDATE products SET ${sets.join(", ")} WHERE id = ?`,
    values,
  );
  if (result.affectedRows === 0) return res.status(404).json({ error: "Product not found" });

  const [[row]] = await pool.execute("SELECT * FROM products WHERE id = ?", [req.params.id]);
  res.json({ product: rowToProduct(row) });
};

exports.remove = async (req, res) => {
  await ensureSchema();
  const pool = await getPool();
  const [result] = await pool.execute("DELETE FROM products WHERE id = ?", [req.params.id]);
  if (result.affectedRows === 0) return res.status(404).json({ error: "Product not found" });
  res.status(204).end();
};
