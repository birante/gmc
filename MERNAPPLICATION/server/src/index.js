import http from 'node:http';
import mongoose from 'mongoose';
import { config } from './utils/config.js';
import app from './app.js';
import { seedIfEmpty } from './seed.js';

const server = http.createServer(app);

async function connectWithRetry(attempt = 1) {
  try {
    await mongoose.connect(config.mongoUri, { serverSelectionTimeoutMS: 5000 });
    console.log('[db] connecté à MongoDB');
    if (config.seedOnStart) await seedIfEmpty();
  } catch (err) {
    const delay = Math.min(30000, attempt * 2000);
    console.error(`[db] échec de connexion (${err.message}), nouvelle tentative dans ${delay / 1000}s`);
    setTimeout(() => connectWithRetry(attempt + 1), delay);
  }
}

server.listen(config.port, () => {
  console.log(`[server] EventHub écoute sur le port ${config.port}`);
  connectWithRetry();
});

const shutdown = async (signal) => {
  console.log(`[server] ${signal} reçu, arrêt…`);
  server.close();
  await mongoose.disconnect().catch(() => {});
  process.exit(0);
};
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
