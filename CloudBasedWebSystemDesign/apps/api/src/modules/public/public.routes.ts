import { Router } from 'express';
import { z } from 'zod';
import { sensitiveLimiter } from '../../middleware/rate-limit.js';
import type { PublicService } from './public.service.js';

const lookupSchema = z.object({
  referenceCode: z.string().trim().min(6).max(20),
  phoneLast4: z.string().regex(/^\d{4}$/, 'Enter the last 4 digits of the phone number'),
});

export function publicRouter(service: PublicService): Router {
  const router = Router();
  router.post('/lookup', sensitiveLimiter, async (req, res) => {
    const { referenceCode, phoneLast4 } = lookupSchema.parse(req.body);
    res.json({ data: await service.lookup(referenceCode, phoneLast4) });
  });
  return router;
}
