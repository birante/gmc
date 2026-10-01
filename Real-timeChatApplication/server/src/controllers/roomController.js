import mongoose from 'mongoose';
import { z } from 'zod';
import { Room } from '../models/Room.js';
import { Message } from '../models/Message.js';
import { conflict, forbidden, notFound, badRequest } from '../utils/httpError.js';
import { serializeMessage, serializeRoom } from '../utils/serialize.js';

const MEMBER_FIELDS = 'username avatarColor';

export const createRoomSchema = z.object({
  name: z
    .string({ required_error: 'Le nom du salon est requis' })
    .trim()
    .min(2, 'Le nom du salon doit contenir au moins 2 caractères')
    .max(40, 'Le nom du salon ne doit pas dépasser 40 caractères'),
  description: z.string().trim().max(200, 'La description ne doit pas dépasser 200 caractères').optional().default(''),
});

export const messagesQuerySchema = z.object({
  before: z
    .string()
    .optional()
    .refine((v) => !v || !Number.isNaN(Date.parse(v)), 'Paramètre "before" invalide (date ISO attendue)'),
  limit: z.coerce.number().int().min(1).max(100).optional().default(30),
});

const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

async function findRoomOr404(id) {
  if (!mongoose.isValidObjectId(id)) throw notFound('Salon introuvable');
  const room = await Room.findById(id);
  if (!room) throw notFound('Salon introuvable');
  return room;
}

async function populated(roomId) {
  return Room.findById(roomId).populate('members', MEMBER_FIELDS).populate('createdBy', MEMBER_FIELDS);
}

function notifyMembers(req, room) {
  const io = req.app.get('io');
  if (io) io.emit('room:members', { roomId: String(room._id), room: serializeRoom(room) });
}

export async function listRooms(req, res) {
  const rooms = await Room.find()
    .sort({ createdAt: 1 })
    .populate('members', MEMBER_FIELDS)
    .populate('createdBy', MEMBER_FIELDS);
  res.json({ rooms: rooms.map((r) => serializeRoom(r, req.user._id)) });
}

export async function createRoom(req, res) {
  const { name, description } = req.validated.body;
  const exists = await Room.findOne({ name: new RegExp(`^${escapeRegex(name)}$`, 'i') });
  if (exists) throw conflict('Un salon porte déjà ce nom');
  const room = await Room.create({ name, description, createdBy: req.user._id, members: [req.user._id] });
  const full = await populated(room._id);
  const io = req.app.get('io');
  if (io) io.emit('room:created', { room: serializeRoom(full) });
  res.status(201).json({ room: serializeRoom(full, req.user._id) });
}

export async function joinRoom(req, res) {
  const room = await findRoomOr404(req.params.id);
  await Room.updateOne({ _id: room._id }, { $addToSet: { members: req.user._id } });
  const full = await populated(room._id);
  notifyMembers(req, full);
  res.json({ room: serializeRoom(full, req.user._id) });
}

export async function leaveRoom(req, res) {
  const room = await findRoomOr404(req.params.id);
  const wasMember = room.members.some((m) => String(m) === String(req.user._id));
  if (!wasMember) throw badRequest("Vous n'êtes pas membre de ce salon");
  await Room.updateOne({ _id: room._id }, { $pull: { members: req.user._id } });
  const full = await populated(room._id);
  const presence = req.app.get('presence');
  if (presence) presence.removeUserFromRoom(String(req.user._id), String(room._id));
  notifyMembers(req, full);
  res.json({ room: serializeRoom(full, req.user._id) });
}

export async function listMessages(req, res) {
  const room = await findRoomOr404(req.params.id);
  const isMember = room.members.some((m) => String(m) === String(req.user._id));
  if (!isMember) throw forbidden('Rejoignez le salon pour voir ses messages');
  const { before, limit } = req.validated.query;
  const filter = { room: room._id };
  if (before) filter.createdAt = { $lt: new Date(before) };
  const docs = await Message.find(filter)
    .sort({ createdAt: -1, _id: -1 })
    .limit(limit + 1)
    .populate('user', MEMBER_FIELDS);
  const hasMore = docs.length > limit;
  const messages = docs.slice(0, limit).reverse().map(serializeMessage);
  res.json({ messages, hasMore });
}
