import { createApp } from './app.js';
import { env } from './config/env.js';
import { logger } from './lib/logger.js';
import { prisma } from './lib/prisma.js';
import { seed } from './scripts/seed.js';

async function main() {
  await prisma.$connect();
  if (env.SEED_ON_START) {
    await seed(prisma, { demo: env.SEED_DEMO_DATA });
  }

  const app = createApp({ db: prisma, webDistDir: env.WEB_DIST_DIR });
  const server = app.listen(env.PORT, () => {
    logger.info({ port: env.PORT, env: env.NODE_ENV }, 'VaxTrack API listening');
  });

  // Graceful shutdown: finish in-flight requests, then close the DB pool.
  const shutdown = (signal: string) => {
    logger.info({ signal }, 'Shutting down');
    server.close(async () => {
      await prisma.$disconnect();
      process.exit(0);
    });
    setTimeout(() => process.exit(1), 10_000).unref();
  };
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

main().catch(async (err) => {
  logger.fatal({ err }, 'Failed to start');
  await prisma.$disconnect();
  process.exit(1);
});
