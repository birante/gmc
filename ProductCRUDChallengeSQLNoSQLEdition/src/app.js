const express = require("express");
const mongoRouter = require("./routes/nosql");
const mysqlRouter = require("./routes/sql");

function createApp() {
  const app = express();
  app.use(express.json({ limit: "100kb" }));

  app.get("/", (req, res) => {
    res.json({
      name: "product-crud-sql-nosql",
      endpoints: [
        // NoSQL (MongoDB via Mongoose)
        "POST   /mongo/products",
        "GET    /mongo/products",
        "GET    /mongo/products/:id",
        "PUT    /mongo/products/:id",
        "DELETE /mongo/products/:id",
        // SQL (MySQL via mysql2)
        "POST   /mysql/products",
        "GET    /mysql/products",
        "GET    /mysql/products/:id",
        "PUT    /mysql/products/:id",
        "DELETE /mysql/products/:id",
      ],
    });
  });

  app.use("/mongo", mongoRouter);
  app.use("/mysql", mysqlRouter);

  // 404
  app.use((req, res) => res.status(404).json({ error: "Not found" }));

  // Centralised error handler.
  app.use((err, req, res, next) => { // eslint-disable-line no-unused-vars
    console.error("[server]", err);
    res.status(err.statusCode || 500).json({ error: err.message || "Internal Server Error" });
  });

  return app;
}

module.exports = { createApp };
