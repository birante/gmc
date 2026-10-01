import mongoose from 'mongoose';
import { config } from './config.js';
import { createApp } from './app.js';
import { seedIfEmpty } from './seed.js';

async function main() {
  const app = createApp();
  const server = app.listen(config.port, () => {
    console.log(`Boutik en écoute sur le port ${config.port} (${config.env})`);
  });

  const connect = async () => {
    try {
      await mongoose.connect(config.mongoUri, { serverSelectionTimeoutMS: 5000 });
      console.log('MongoDB connecté');
      if (config.seedOnStart) await seedIfEmpty();
    } catch (err) {
      console.error('Connexion MongoDB échouée, nouvel essai dans 5 s :', err.message);
      setTimeout(connect, 5000);
    }
  };
  connect();

  const shutdown = async () => {
    server.close();
    await mongoose.disconnect().catch(() => {});
    process.exit(0);
  };
  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
}

main();
