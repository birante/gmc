// MongoDB connection helper. Non-fatal: if MongoDB is unreachable, the
// app still boots — /mongo/* routes return 503 until Mongo is up.

const mongoose = require("mongoose");

let ready = null;

async function connectMongo() {
  if (ready) return ready;
  const uri = process.env.MONGO_URI || "mongodb://127.0.0.1:27017/products";
  ready = mongoose
    .connect(uri, { serverSelectionTimeoutMS: 3000 })
    .then(() => {
      console.log(`[mongo] connected: ${uri}`);
      return mongoose.connection;
    })
    .catch((err) => {
      console.warn(`[mongo] connect failed: ${err.message}`);
      ready = null;               // allow future retries
      throw err;
    });
  return ready;
}

function isConnected() {
  return mongoose.connection.readyState === 1;
}

module.exports = { connectMongo, isConnected };
