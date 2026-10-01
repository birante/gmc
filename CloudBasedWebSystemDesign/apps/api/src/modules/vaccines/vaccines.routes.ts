import { Router } from 'express';
import { authenticate } from '../../middleware/auth.js';
import type { VaccinesRepository } from './vaccines.repository.js';

/** Read-only reference data: the immunisation schedule. */
export function vaccinesRouter(vaccines: VaccinesRepository): Router {
  const router = Router();
  router.get('/', authenticate, async (_req, res) => {
    res.json({ data: await vaccines.list() });
  });
  return router;
}
