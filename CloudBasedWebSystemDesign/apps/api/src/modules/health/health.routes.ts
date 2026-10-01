import { Router } from 'express';
import type { PrismaClient } from '@prisma/client';

const startedAt = Date.now();

/** Liveness + readiness probe used by Render / load balancers / uptime monitors. */
export function healthRouter(db: PrismaClient): Router {
  const router = Router();
  router.get('/', async (_req, res) => {
    let database: 'up' | 'down' = 'up';
    try {
      await db.$queryRaw`SELECT 1`;
    } catch {
      database = 'down';
    }
    res.status(database === 'up' ? 200 : 503).json({
      status: database === 'up' ? 'ok' : 'degraded',
      database,
      uptimeSeconds: Math.round((Date.now() - startedAt) / 1000),
      version: process.env.npm_package_version ?? '1.0.0',
      commit: process.env.RENDER_GIT_COMMIT?.slice(0, 7) ?? null,
    });
  });
  return router;
}
