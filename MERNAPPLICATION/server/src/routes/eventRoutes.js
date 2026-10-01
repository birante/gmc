import { Router } from 'express';
import { body, query } from 'express-validator';
import {
  listEvents,
  getEvent,
  createEvent,
  updateEvent,
  deleteEvent,
  registerToEvent,
  unregisterFromEvent,
  listCategories,
} from '../controllers/eventController.js';
import { CATEGORIES } from '../models/Event.js';
import { requireAuth, optionalAuth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { asyncHandler } from '../utils/httpError.js';

const router = Router();

const eventRules = (isUpdate) => {
  const opt = (chain) => (isUpdate ? chain.optional() : chain);
  return [
    opt(body('title')).isString().trim().isLength({ min: 3, max: 120 }).withMessage('Le titre doit contenir 3 à 120 caractères'),
    opt(body('description')).isString().trim().isLength({ min: 10, max: 5000 }).withMessage('La description doit contenir au moins 10 caractères'),
    opt(body('date')).isISO8601().withMessage('Date invalide').toDate(),
    opt(body('location')).isString().trim().isLength({ min: 2, max: 200 }).withMessage('Le lieu est requis'),
    body('category').optional().isIn(CATEGORIES).withMessage('Catégorie invalide'),
    opt(body('capacity')).isInt({ min: 1, max: 100000 }).withMessage('Le nombre de places doit être un entier ≥ 1').toInt(),
    body('imageUrl')
      .optional({ values: 'falsy' })
      .isURL({ protocols: ['http', 'https'], require_protocol: true })
      .withMessage("L'URL de l'image est invalide"),
  ];
};

router.get('/categories', listCategories);

router.get(
  '/',
  optionalAuth,
  query('category').optional({ values: 'falsy' }).isIn(CATEGORIES).withMessage('Catégorie invalide'),
  query('when').optional({ values: 'falsy' }).isIn(['upcoming', 'past', 'all']).withMessage('Filtre de date invalide'),
  query('page').optional().isInt({ min: 1 }).withMessage('Page invalide'),
  validate,
  asyncHandler(listEvents)
);

router.get('/:id', optionalAuth, asyncHandler(getEvent));
router.post('/', requireAuth, eventRules(false), validate, asyncHandler(createEvent));
router.put('/:id', requireAuth, eventRules(true), validate, asyncHandler(updateEvent));
router.delete('/:id', requireAuth, asyncHandler(deleteEvent));
router.post('/:id/register', requireAuth, asyncHandler(registerToEvent));
router.delete('/:id/register', requireAuth, asyncHandler(unregisterFromEvent));

export default router;
