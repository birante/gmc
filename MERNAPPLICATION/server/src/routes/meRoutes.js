import { Router } from 'express';
import { myEvents, myRegistrations } from '../controllers/eventController.js';
import { requireAuth } from '../middleware/auth.js';
import { asyncHandler } from '../utils/httpError.js';

const router = Router();
router.use(requireAuth);
router.get('/events', asyncHandler(myEvents));
router.get('/registrations', asyncHandler(myRegistrations));

export default router;
