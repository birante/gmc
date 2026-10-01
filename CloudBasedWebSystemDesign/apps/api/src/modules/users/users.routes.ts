import { Router } from 'express';
import { authenticate, requireRole } from '../../middleware/auth.js';
import type { UsersController } from './users.controller.js';

export function usersRouter(controller: UsersController): Router {
  const router = Router();
  router.use(authenticate, requireRole('ADMIN'));
  router.get('/', controller.list);
  router.post('/', controller.create);
  router.patch('/:id', controller.update);
  return router;
}
