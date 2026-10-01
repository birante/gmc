import mongoose from 'mongoose';
import { config } from './config.js';
import app from './app.js';
import { seedDemo } from './seed.js';

async function start() {
  const server = app.listen(config.port, () => {
    console.log(`TaskFlow écoute sur le port ${config.port} (${config.env})`);
  });

  const connect = async () => {
    try {
      await mongoose.connect(config.mongoUri, { serverSelectionTimeoutMS: 5000 });
      console.log('Connecté à MongoDB');
      if (config.seedOnStart && (await seedDemo())) console.log('Données de démo créées (demo@taskflow.sn)');
    } catch (err) {
      console.error('Connexion MongoDB échouée, nouvelle tentative dans 3s :', err.message);
      setTimeout(connect, 3000);
    }
  };
  connect();

  const shutdown = async () => {
    server.close();
    await mongoose.disconnect();
    process.exit(0);
  };
  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
}

start();
