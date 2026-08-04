// MySQL connection pool + one-time schema bootstrap.
// Non-fatal: if MySQL is unreachable, the app still boots — /mysql/*
// routes return 503 until MySQL is up.

const fs   = require("fs");
const path = require("path");
const mysql = require("mysql2/promise");

let pool = null;
let initialized = false;

async function getPool() {
  if (pool) return pool;
  pool = mysql.createPool({
    host:            process.env.MYSQL_HOST     || "127.0.0.1",
    port: Number(   process.env.MYSQL_PORT)     || 3306,
    user:            process.env.MYSQL_USER     || "root",
    password:        process.env.MYSQL_PASSWORD || "secret",
    database:        process.env.MYSQL_DATABASE || "products",
    waitForConnections: true,
    connectionLimit:    10,
  });
  return pool;
}

// Ensure the `products` table exists before serving any request.
async function ensureSchema() {
  if (initialized) return;
  const p  = await getPool();
  const sql = fs.readFileSync(path.join(__dirname, "..", "sql", "init.sql"), "utf8");
  await p.query(sql);
  initialized = true;
  console.log("[mysql] schema ready");
}

module.exports = { getPool, ensureSchema };
