import { Router } from 'express';
import { authenticate } from '../../middleware/auth.js';
import type { ImmunizationsController } from './immunizations.controller.js';

export function immunizationsRouter(controller: ImmunizationsController): Router {
  const router = Router();
  router.use(authenticate);
  router.get('/worklist', controller.worklist);
  router.post('/:id/administer', controller.administer);
  router.post('/:id/revert', controller.revert);
  return router;
}
