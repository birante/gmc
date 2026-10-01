import { Router } from 'express';
import { asyncHandler } from '../utils/httpError.js';
import { validate } from '../middleware/validate.js';
import { requireAuth, requireAdmin } from '../middleware/auth.js';
import * as c from '../controllers/orderController.js';

const router = Router();

router.use(requireAuth);
router.post('/', validate(c.createOrderSchema), asyncHandler(c.createOrder));
router.get('/mine', asyncHandler(c.myOrders));
router.get('/', requireAdmin, asyncHandler(c.allOrders));
router.get('/:id', asyncHandler(c.getOrder));
router.post('/:id/pay', asyncHandler(c.payOrder));
router.patch('/:id/status', requireAdmin, validate(c.statusSchema), asyncHandler(c.updateStatus));

export default router;
