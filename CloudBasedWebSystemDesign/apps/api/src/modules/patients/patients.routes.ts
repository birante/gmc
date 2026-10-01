import { Router } from 'express';
import { authenticate, requireRole } from '../../middleware/auth.js';
import type { PatientsController } from './patients.controller.js';

export function patientsRouter(controller: PatientsController): Router {
  const router = Router();
  router.use(authenticate);
  router.get('/', controller.list);
  router.post('/', controller.create);
  router.get('/:id', controller.get);
  router.patch('/:id', controller.update);
  router.delete('/:id', requireRole('ADMIN'), controller.remove);
  return router;
}
