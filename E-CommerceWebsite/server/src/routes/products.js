import { Router } from 'express';
import { asyncHandler } from '../utils/httpError.js';
import { validate } from '../middleware/validate.js';
import { requireAuth, requireAdmin } from '../middleware/auth.js';
import * as c from '../controllers/productController.js';

const router = Router();

router.get('/', validate(c.listQuerySchema, 'query'), asyncHandler(c.listProducts));
router.get('/:slug', asyncHandler(c.getProduct));
router.post('/', requireAuth, requireAdmin, validate(c.productCreateSchema), asyncHandler(c.createProduct));
router.put('/:id', requireAuth, requireAdmin, validate(c.productUpdateSchema), asyncHandler(c.updateProduct));
router.delete('/:id', requireAuth, requireAdmin, asyncHandler(c.deleteProduct));

export default router;
