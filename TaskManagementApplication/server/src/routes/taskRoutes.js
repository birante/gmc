import { Router } from 'express';
import { body, query } from 'express-validator';
import { requireAuth } from '../middleware/requireAuth.js';
import { validate } from '../middleware/validate.js';
import { PRIORITIES, STATUSES } from '../models/Task.js';
import {
  listTasks, getStats, createTask, getTask, updateTask, updateStatus, deleteTask, SORT_KEYS,
} from '../controllers/taskController.js';

const router = Router();
router.use(requireAuth);

const deadlineRule = (chain) =>
  chain
    .optional({ values: 'undefined' })
    .custom((v) => v === null || v === '' || !Number.isNaN(Date.parse(v)))
    .withMessage('Échéance invalide')
    .customSanitizer((v) => (v === '' || v === null ? null : new Date(v)));

const taskRules = (isCreate) => [
  isCreate
    ? body('title').isString().withMessage('Le titre est requis').trim().notEmpty().withMessage('Le titre est requis').isLength({ max: 200 }).withMessage('Titre trop long (200 max)')
    : body('title').optional().isString().trim().notEmpty().withMessage('Le titre ne peut pas être vide').isLength({ max: 200 }).withMessage('Titre trop long (200 max)'),
  body('description').optional({ values: 'null' }).isString().withMessage('Description invalide').isLength({ max: 5000 }).withMessage('Description trop longue'),
  deadlineRule(body('deadline')),
  body('priority').optional().isIn(PRIORITIES).withMessage('Priorité invalide (low, medium, high)'),
  body('status').optional().isIn(STATUSES).withMessage('Statut invalide (todo, in_progress, done)'),
  validate,
];

router.get(
  '/',
  query('status').optional({ values: 'falsy' }).isIn(STATUSES).withMessage('Statut invalide'),
  query('search').optional().isString().isLength({ max: 200 }).withMessage('Recherche trop longue'),
  query('sort').optional({ values: 'falsy' }).isIn(SORT_KEYS).withMessage('Tri invalide'),
  validate,
  listTasks
);
router.get('/stats', getStats);
router.post('/', taskRules(true), createTask);
router.get('/:id', getTask);
router.put('/:id', taskRules(false), updateTask);
router.patch(
  '/:id/status',
  body('status').isIn(STATUSES).withMessage('Statut invalide (todo, in_progress, done)'),
  validate,
  updateStatus
);
router.delete('/:id', deleteTask);

export default router;
