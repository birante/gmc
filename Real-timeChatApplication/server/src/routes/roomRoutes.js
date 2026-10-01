import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import {
  createRoom,
  createRoomSchema,
  joinRoom,
  leaveRoom,
  listMessages,
  listRooms,
  messagesQuerySchema,
} from '../controllers/roomController.js';

const router = Router();

router.use(requireAuth);
router.get('/', listRooms);
router.post('/', validate(createRoomSchema), createRoom);
router.post('/:id/join', joinRoom);
router.post('/:id/leave', leaveRoom);
router.get('/:id/messages', validate(messagesQuerySchema, 'query'), listMessages);

export default router;
