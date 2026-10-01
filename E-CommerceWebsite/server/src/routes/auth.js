import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { asyncHandler } from '../utils/httpError.js';
import { validate } from '../middleware/validate.js';
import { requireAuth } from '../middleware/auth.js';
import { register, login, me, registerSchema, loginSchema } from '../controllers/authController.js';

const router = Router();

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: process.env.NODE_ENV === 'test' ? 1000 : 50,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: 'Trop de tentatives, réessayez plus tard' }
});

router.use(limiter);
router.post('/register', validate(registerSchema), asyncHandler(register));
router.post('/login', validate(loginSchema), asyncHandler(login));
router.get('/me', requireAuth, asyncHandler(me));

export default router;
