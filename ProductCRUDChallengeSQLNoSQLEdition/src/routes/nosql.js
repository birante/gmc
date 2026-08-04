const express = require("express");
const ctrl = require("../controllers/NoSQLcontroller");
const { isConnected, connectMongo } = require("../db/mongoConnect");

const router = express.Router();

// Middleware: refuse requests until Mongo is up.
router.use(async (req, res, next) => {
  try {
    if (!isConnected()) await connectMongo();
    next();
  } catch {
    res.status(503).json({ error: "MongoDB is not reachable" });
  }
});

const wrap = fn => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

router.post  ("/products",     wrap(ctrl.create));
router.get   ("/products",     wrap(ctrl.readAll));
router.get   ("/products/:id", wrap(ctrl.readOne));
router.put   ("/products/:id", wrap(ctrl.update));
router.delete("/products/:id", wrap(ctrl.remove));

module.exports = router;
