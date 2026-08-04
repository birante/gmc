const express = require("express");
const ctrl = require("../controllers/SQLcontroller");
const { getPool } = require("../db/mysqlPool");

const router = express.Router();

// Middleware: verify MySQL is reachable before serving.
router.use(async (req, res, next) => {
  try {
    const pool = await getPool();
    const conn = await pool.getConnection();
    conn.release();
    next();
  } catch (err) {
    res.status(503).json({ error: `MySQL is not reachable: ${err.code || err.message}` });
  }
});

const wrap = fn => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

router.post  ("/products",     wrap(ctrl.create));
router.get   ("/products",     wrap(ctrl.readAll));
router.get   ("/products/:id", wrap(ctrl.readOne));
router.put   ("/products/:id", wrap(ctrl.update));
router.delete("/products/:id", wrap(ctrl.remove));

module.exports = router;
