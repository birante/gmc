import { Router } from 'express';
import { authenticate } from '../../middleware/auth.js';
import { sensitiveLimiter } from '../../middleware/rate-limit.js';
import type { AuthController } from './auth.controller.js';

export function authRouter(controller: AuthController): Router {
  const router = Router();
  router.post('/login', sensitiveLimiter, controller.login);
  router.get('/me', authenticate, controller.me);
  return router;
}
