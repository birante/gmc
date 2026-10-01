import { Router } from 'express';
import { body } from 'express-validator';
import rateLimit from 'express-rate-limit';
import { register, login, logout, getMe, updateMe } from '../controllers/authController.js';
import { requireAuth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { asyncHandler } from '../utils/httpError.js';

const router = Router();

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: process.env.NODE_ENV === 'test' ? 10000 : 100,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: 'Trop de tentatives, réessayez plus tard' },
});

router.use(limiter);

router.post(
  '/register',
  body('name').isString().trim().isLength({ min: 2, max: 80 }).withMessage('Le nom doit contenir 2 à 80 caractères'),
  body('email').isEmail().withMessage('E-mail invalide').normalizeEmail({ gmail_remove_dots: false }),
  body('password').isString().isLength({ min: 6 }).withMessage('Le mot de passe doit contenir au moins 6 caractères'),
  body('bio').optional().isString().isLength({ max: 500 }).withMessage('La bio est limitée à 500 caractères'),
  validate,
  asyncHandler(register)
);

router.post(
  '/login',
  body('email').isEmail().withMessage('E-mail invalide').normalizeEmail({ gmail_remove_dots: false }),
  body('password').isString().notEmpty().withMessage('Mot de passe requis'),
  validate,
  asyncHandler(login)
);

router.post('/logout', logout);

router.get('/me', requireAuth, getMe);

router.put(
  '/me',
  requireAuth,
  body('name').optional().isString().trim().isLength({ min: 2, max: 80 }).withMessage('Le nom doit contenir 2 à 80 caractères'),
  body('email').optional().isEmail().withMessage('E-mail invalide').normalizeEmail({ gmail_remove_dots: false }),
  body('bio').optional().isString().isLength({ max: 500 }).withMessage('La bio est limitée à 500 caractères'),
  body('newPassword').optional({ values: 'falsy' }).isString().isLength({ min: 6 }).withMessage('Le nouveau mot de passe doit contenir au moins 6 caractères'),
  validate,
  asyncHandler(updateMe)
);

export default router;
