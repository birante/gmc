import { Router } from 'express';
import { getFeed } from '../controllers/feedController.js';
import { requireAuth } from '../middleware/auth.js';
import { asyncHandler } from '../utils/httpError.js';

const router = Router();
router.get('/', requireAuth, asyncHandler(getFeed));
export default router;
