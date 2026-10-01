import http from 'node:http';
import mongoose from 'mongoose';
import app from './app.js';
import { getJwtSecret } from './utils/config.js';
import { seedIfEmpty } from './seed.js';

const PORT = Number(process.env.PORT) || 3000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/booknest';

getJwtSecret(); // échoue immédiatement en production si JWT_SECRET est absent

async function connectWithRetry(retries = 10) {
  for (let i = 1; i <= retries; i++) {
    try {
      await mongoose.connect(MONGODB_URI, { serverSelectionTimeoutMS: 5000 });
      console.log('[db] connecté à MongoDB');
      return;
    } catch (err) {
      console.error(`[db] connexion échouée (${i}/${retries}) : ${err.message}`);
      await new Promise((r) => setTimeout(r, 3000));
    }
  }
  throw new Error('Impossible de se connecter à MongoDB');
}

const server = http.createServer(app);
server.listen(PORT, () => console.log(`[http] BookNest écoute sur le port ${PORT}`));

connectWithRetry()
  .then(async () => {
    if (process.env.SEED_ON_START === 'true') await seedIfEmpty();
  })
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });

const shutdown = () => {
  server.close(() => mongoose.disconnect().finally(() => process.exit(0)));
};
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
