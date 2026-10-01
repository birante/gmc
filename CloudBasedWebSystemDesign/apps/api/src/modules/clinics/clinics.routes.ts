import { Router } from 'express';
import { authenticate, requireRole } from '../../middleware/auth.js';
import type { ClinicsController } from './clinics.controller.js';

export function clinicsRouter(controller: ClinicsController): Router {
  const router = Router();
  router.use(authenticate);
  router.get('/', controller.list);
  router.post('/', requireRole('ADMIN'), controller.create);
  router.patch('/:id', requireRole('ADMIN'), controller.update);
  return router;
}
