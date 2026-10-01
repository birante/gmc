import { Router } from 'express';
import { body } from 'express-validator';
import rateLimit from 'express-rate-limit';
import { register, login, me } from '../controllers/authController.js';
import { requireAuth } from '../middleware/requireAuth.js';
import { validate } from '../middleware/validate.js';

const router = Router();

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: process.env.NODE_ENV === 'test' ? 1000 : 50,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: 'Trop de tentatives, réessayez plus tard' },
});

router.post(
  '/register',
  authLimiter,
  body('name').isString().trim().isLength({ min: 2, max: 80 }).withMessage('Le nom doit contenir entre 2 et 80 caractères'),
  body('email').isEmail().withMessage('Email invalide').normalizeEmail({ gmail_remove_dots: false }),
  body('password').isString().isLength({ min: 6 }).withMessage('Le mot de passe doit contenir au moins 6 caractères'),
  validate,
  register
);

router.post(
  '/login',
  authLimiter,
  body('email').isEmail().withMessage('Email invalide').normalizeEmail({ gmail_remove_dots: false }),
  body('password').isString().notEmpty().withMessage('Mot de passe requis'),
  validate,
  login
);

router.get('/me', requireAuth, me);

export default router;
