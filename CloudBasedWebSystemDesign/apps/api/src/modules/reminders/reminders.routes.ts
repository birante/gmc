import { Router } from 'express';
import { z } from 'zod';
import { authenticate, currentUser } from '../../middleware/auth.js';
import type { RemindersService } from './reminders.service.js';

const querySchema = z.object({ clinicId: z.string().optional() });

export function remindersRouter(service: RemindersService): Router {
  const router = Router();
  router.use(authenticate);
  router.get('/preview', async (req, res) => {
    const { clinicId } = querySchema.parse(req.query);
    res.json({ data: await service.preview(currentUser(req), clinicId) });
  });
  router.post('/send', async (req, res) => {
    const { clinicId } = querySchema.parse(req.query);
    res.json({ data: await service.send(currentUser(req), clinicId) });
  });
  return router;
}
