import { Router } from 'express';
import { body, query } from 'express-validator';
import { createBook, getBook, listBooks, listGenres, rateBook, search, updateBook } from '../controllers/bookController.js';
import { optionalAuth, requireAuth } from '../middleware/auth.js';
import { validate, validObjectId } from '../middleware/validate.js';
import { EXTERNAL_ID_RX } from '../utils/openLibrary.js';
import { isValidIsbn } from '../utils/text.js';
import { asyncHandler } from '../utils/httpError.js';

const router = Router();

const stringList = (field, label) =>
  body(field)
    .optional({ values: 'null' })
    .custom((v) => {
      const ok = typeof v === 'string' || (Array.isArray(v) && v.length <= 20 && v.every((s) => typeof s === 'string' && s.length <= 120));
      if (!ok) throw new Error(`${label} invalides`);
      return true;
    });

/** Règles communes à la création (POST) et à la modification (PUT) d'un livre. */
const bookFieldRules = [
  stringList('authors', 'Auteurs'),
  stringList('genres', 'Genres'),
  body('description').optional({ values: 'null' }).isString().isLength({ max: 5000 }).withMessage('La description ne doit pas dépasser 5000 caractères'),
  body('coverUrl')
    .optional({ values: 'falsy' })
    .isURL({ protocols: ['https'], require_protocol: true })
    .withMessage("L'URL de couverture doit être une adresse https:// valide"),
  body('isbn')
    .optional({ values: 'falsy' })
    .custom((v) => {
      if (!isValidIsbn(v)) throw new Error('ISBN invalide (10 ou 13 chiffres avec clé de contrôle)');
      return true;
    }),
  body('publishedDate')
    .optional({ values: 'falsy' })
    .custom((v) => {
      const m = String(v).match(/^(\d{1,4})(-\d{2}(-\d{2})?)?$/);
      if (!m || Number(m[1]) > new Date().getFullYear() + 1) throw new Error('Année de publication invalide');
      return true;
    }),
  body('pageCount').optional({ values: 'falsy' }).isInt({ min: 1, max: 20000 }).withMessage('Le nombre de pages doit être un entier entre 1 et 20000').toInt(),
];

router.get(
  '/search',
  optionalAuth,
  query('q').isString().trim().isLength({ min: 1, max: 200 }).withMessage('Le paramètre q est requis'),
  query('type').optional().isIn(['title', 'author', 'genre']).withMessage('type doit valoir title, author ou genre'),
  validate,
  asyncHandler(search)
);
router.get('/', optionalAuth, asyncHandler(listBooks));
router.get('/genres', asyncHandler(listGenres));
router.post(
  '/',
  requireAuth,
  body('externalId').optional().isString().matches(EXTERNAL_ID_RX).withMessage('Identifiant externe invalide (ex. ol:/works/OL45804W)'),
  body('title')
    .if(body('externalId').not().exists())
    .isString()
    .trim()
    .notEmpty()
    .withMessage('Le titre est requis'),
  body('title').optional().isString().isLength({ max: 300 }).withMessage('Le titre ne doit pas dépasser 300 caractères'),
  ...bookFieldRules,
  validate,
  asyncHandler(createBook)
);
router.get('/:id', optionalAuth, validObjectId('id'), asyncHandler(getBook));
router.put(
  '/:id',
  requireAuth,
  validObjectId('id'),
  body('title').optional().isString().trim().isLength({ min: 1, max: 300 }).withMessage('Le titre est requis (300 caractères max.)'),
  ...bookFieldRules,
  validate,
  asyncHandler(updateBook)
);
router.post(
  '/:id/rate',
  requireAuth,
  validObjectId('id'),
  body('value').isInt({ min: 1, max: 5 }).withMessage('La note doit être un entier entre 1 et 5').toInt(),
  validate,
  asyncHandler(rateBook)
);

export default router;
