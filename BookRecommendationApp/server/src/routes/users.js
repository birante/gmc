import { Router } from 'express';
import { body } from 'express-validator';
import { follow, getProfile, listUsers, unfollow, updateMe } from '../controllers/userController.js';
import { optionalAuth, requireAuth } from '../middleware/auth.js';
import { validate, validObjectId } from '../middleware/validate.js';
import { asyncHandler } from '../utils/httpError.js';

const router = Router();

router.get('/', optionalAuth, asyncHandler(listUsers));
router.patch(
  '/me',
  requireAuth,
  body('bio').optional().isString().isLength({ max: 500 }).withMessage('La bio ne doit pas dépasser 500 caractères'),
  body('favoriteGenres').optional().isArray({ max: 20 }).withMessage('Genres favoris invalides'),
  validate,
  asyncHandler(updateMe)
);
router.post('/:id/follow', requireAuth, validObjectId('id'), asyncHandler(follow));
router.delete('/:id/follow', requireAuth, validObjectId('id'), asyncHandler(unfollow));
router.get('/:username', optionalAuth, asyncHandler(getProfile));

export default router;
