import { Router } from 'express';
import { z } from 'zod';
import { authenticate, currentUser } from '../../middleware/auth.js';
import type { DashboardService } from './dashboard.service.js';

const querySchema = z.object({ clinicId: z.string().optional() });

export function dashboardRouter(service: DashboardService): Router {
  const router = Router();
  router.get('/stats', authenticate, async (req, res) => {
    const { clinicId } = querySchema.parse(req.query);
    res.json({ data: await service.stats(currentUser(req), clinicId) });
  });
  return router;
}
