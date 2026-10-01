import mongoose from 'mongoose';
import { Server } from 'socket.io';
import { config } from '../config.js';
import { userFromToken } from '../middleware/auth.js';
import { Room } from '../models/Room.js';
import { Message } from '../models/Message.js';
import { serializeMessage, publicUser } from '../utils/serialize.js';
import { createPresence, roomKey, userKey } from './presence.js';

const MAX_LENGTH = 2000;

function reply(ack, payload) {
  if (typeof ack === 'function') ack(payload);
}

async function isMember(roomId, userId) {
  if (!mongoose.isValidObjectId(roomId)) return { room: null, member: false };
  const room = await Room.findById(roomId).select('members');
  if (!room) return { room: null, member: false };
  return { room, member: room.members.some((m) => String(m) === String(userId)) };
}

/**
 * Attache Socket.IO à un serveur HTTP existant.
 * Renvoie { io, presence }.
 */
export function attachSockets(httpServer, options = {}) {
  const io = new Server(httpServer, {
    cors: config.clientOrigin ? { origin: config.clientOrigin.split(',') } : undefined,
    ...options,
  });
  const presence = createPresence(io);

  io.use(async (socket, next) => {
    const token = socket.handshake.auth?.token;
    const user = await userFromToken(token);
    if (!user) return next(new Error('Non authentifié'));
    socket.data.user = user;
    socket.data.rooms = new Set();
    next();
  });

  io.on('connection', (socket) => {
    const user = socket.data.user;
    socket.join(userKey(String(user._id)));

    socket.on('room:join', async (payload, ack) => {
      try {
        const roomId = String(payload?.roomId || '');
        const { room, member } = await isMember(roomId, user._id);
        if (!room) return reply(ack, { error: 'Salon introuvable' });
        if (!member) return reply(ack, { error: "Vous n'êtes pas membre de ce salon" });
        presence.add(socket, roomId);
        reply(ack, { ok: true, users: presence.list(roomId) });
      } catch {
        reply(ack, { error: 'Erreur serveur' });
      }
    });

    socket.on('room:leave', (payload, ack) => {
      const roomId = String(payload?.roomId || '');
      if (socket.data.rooms.has(roomId)) presence.remove(socket, roomId);
      reply(ack, { ok: true });
    });

    socket.on('message:send', async (payload, ack) => {
      try {
        const roomId = String(payload?.roomId || '');
        const text = typeof payload?.text === 'string' ? payload.text.trim() : '';
        if (!text) return reply(ack, { error: 'Le message est vide' });
        if (text.length > MAX_LENGTH) return reply(ack, { error: `Le message dépasse ${MAX_LENGTH} caractères` });
        const { room, member } = await isMember(roomId, user._id);
        if (!room) return reply(ack, { error: 'Salon introuvable' });
        if (!member) return reply(ack, { error: "Vous n'êtes pas membre de ce salon" });
        const message = await Message.create({ room: room._id, user: user._id, text });
        const data = { ...serializeMessage(message), user: publicUser(user) };
        io.to(roomKey(roomId)).emit('message:new', data);
        socket.to(roomKey(roomId)).emit('typing', { roomId, user: publicUser(user), isTyping: false });
        reply(ack, { ok: true, message: data });
      } catch {
        reply(ack, { error: "Impossible d'envoyer le message" });
      }
    });

    const typing = (isTyping) => (payload) => {
      const roomId = String(payload?.roomId || '');
      if (!socket.data.rooms.has(roomId)) return;
      socket.to(roomKey(roomId)).emit('typing', { roomId, user: publicUser(user), isTyping });
    };
    socket.on('typing:start', typing(true));
    socket.on('typing:stop', typing(false));

    socket.on('disconnect', () => presence.removeSocket(socket));
  });

  return { io, presence };
}
