import mongoose from 'mongoose';
import { config } from './config.js';
import { createServer } from './server.js';
import { seedIfEmpty } from './seed.js';

const { server, io } = createServer();

async function connectDb() {
  try {
    await mongoose.connect(config.mongoUri, { serverSelectionTimeoutMS: 5000 });
    console.log('MongoDB connecté');
    if (config.seedOnStart && (await seedIfEmpty())) console.log('Données de démo insérées');
  } catch (err) {
    console.error('Connexion MongoDB échouée, nouvelle tentative dans 5 s :', err.message);
    setTimeout(connectDb, 5000);
  }
}

server.listen(config.port, () => {
  console.log(`Waxtaan écoute sur le port ${config.port}`);
});
connectDb();

const shutdown = async () => {
  io.close();
  await mongoose.disconnect().catch(() => {});
  process.exit(0);
};
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
