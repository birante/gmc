import { Router } from 'express';
import { body } from 'express-validator';
import {
  addComment,
  createRecommendation,
  deleteComment,
  deleteRecommendation,
  getRecommendation,
  like,
  listComments,
  listRecommendations,
  unlike,
  updateRecommendation,
} from '../controllers/recommendationController.js';
import { optionalAuth, requireAuth } from '../middleware/auth.js';
import { validate, validObjectId } from '../middleware/validate.js';
import { asyncHandler } from '../utils/httpError.js';

const router = Router();
const ratingRule = (opt) =>
  (opt ? body('rating').optional() : body('rating')).isInt({ min: 1, max: 5 }).withMessage('La note doit être un entier entre 1 et 5').toInt();
const reviewRule = (opt) =>
  (opt ? body('review').optional() : body('review')).isString().trim().isLength({ min: 3, max: 2000 }).withMessage("L'avis doit contenir entre 3 et 2000 caractères");

router.get('/', optionalAuth, asyncHandler(listRecommendations));
router.post(
  '/',
  requireAuth,
  ratingRule(false),
  reviewRule(false),
  body('bookId').optional().isString(),
  body('book').optional().isObject().withMessage('Livre invalide'),
  body().custom((b) => {
    if (!b.bookId && !b.book?.externalId && !b.book?.title?.trim?.()) throw new Error('Indiquez un livre (titre requis)');
    return true;
  }),
  validate,
  asyncHandler(createRecommendation)
);
router.get('/:id', optionalAuth, validObjectId('id'), asyncHandler(getRecommendation));
router.patch('/:id', requireAuth, validObjectId('id'), ratingRule(true), reviewRule(true), validate, asyncHandler(updateRecommendation));
router.delete('/:id', requireAuth, validObjectId('id'), asyncHandler(deleteRecommendation));
router.post('/:id/like', requireAuth, validObjectId('id'), asyncHandler(like));
router.delete('/:id/like', requireAuth, validObjectId('id'), asyncHandler(unlike));
router.get('/:id/comments', validObjectId('id'), asyncHandler(listComments));
router.post(
  '/:id/comments',
  requireAuth,
  validObjectId('id'),
  body('text').isString().trim().isLength({ min: 1, max: 1000 }).withMessage('Le commentaire doit contenir entre 1 et 1000 caractères'),
  validate,
  asyncHandler(addComment)
);

export const commentsRouter = Router();
commentsRouter.delete('/:id', requireAuth, validObjectId('id'), asyncHandler(deleteComment));

export default router;
