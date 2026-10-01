import { Router } from 'express';
import { body } from 'express-validator';
import { login, me, register } from '../controllers/authController.js';
import { requireAuth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { asyncHandler } from '../utils/httpError.js';

const router = Router();

router.post(
  '/register',
  body('username').isString().trim().matches(/^[a-zA-Z0-9_.-]{3,30}$/).withMessage("Le nom d'utilisateur doit faire 3 à 30 caractères (lettres, chiffres, _ . -)"),
  body('email').isEmail().withMessage('Email invalide').normalizeEmail({ gmail_remove_dots: false }),
  body('password').isString().isLength({ min: 6 }).withMessage('Le mot de passe doit contenir au moins 6 caractères'),
  body('favoriteGenres').optional().isArray({ max: 20 }).withMessage('Genres favoris invalides'),
  body('bio').optional().isString().isLength({ max: 500 }),
  validate,
  asyncHandler(register)
);

router.post(
  '/login',
  body('email').isEmail().withMessage('Email invalide').normalizeEmail({ gmail_remove_dots: false }),
  body('password').isString().notEmpty().withMessage('Mot de passe requis'),
  validate,
  asyncHandler(login)
);

router.get('/me', requireAuth, asyncHandler(me));

export default router;
