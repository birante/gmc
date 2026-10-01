import { publicUser } from '../utils/serialize.js';

export const roomKey = (roomId) => `room:${roomId}`;
export const userKey = (userId) => `user:${userId}`;

/**
 * Suivi en mémoire des utilisateurs connectés par salon.
 * rooms: Map<roomId, Map<userId, { user, sockets: Set<socketId> }>>
 */
export function createPresence(io) {
  const rooms = new Map();

  function list(roomId) {
    const entries = rooms.get(roomId);
    if (!entries) return [];
    return [...entries.values()].map((e) => e.user).sort((a, b) => a.username.localeCompare(b.username));
  }

  function broadcast(roomId) {
    io.to(roomKey(roomId)).emit('room:users', { roomId, users: list(roomId) });
  }

  function add(socket, roomId) {
    const user = publicUser(socket.data.user);
    if (!rooms.has(roomId)) rooms.set(roomId, new Map());
    const entries = rooms.get(roomId);
    if (!entries.has(user.id)) entries.set(user.id, { user, sockets: new Set() });
    entries.get(user.id).sockets.add(socket.id);
    socket.data.rooms.add(roomId);
    socket.join(roomKey(roomId));
    broadcast(roomId);
  }

  function remove(socket, roomId, { silent = false } = {}) {
    const userId = String(socket.data.user._id);
    socket.data.rooms.delete(roomId);
    socket.leave(roomKey(roomId));
    const entries = rooms.get(roomId);
    const entry = entries?.get(userId);
    if (entry) {
      entry.sockets.delete(socket.id);
      if (entry.sockets.size === 0) {
        entries.delete(userId);
        socket.to(roomKey(roomId)).emit('typing', {
          roomId,
          user: publicUser(socket.data.user),
          isTyping: false,
        });
      }
      if (entries.size === 0) rooms.delete(roomId);
    }
    if (!silent) broadcast(roomId);
  }

  function removeSocket(socket) {
    for (const roomId of [...socket.data.rooms]) remove(socket, roomId);
  }

  function removeUserFromRoom(userId, roomId) {
    for (const socket of io.sockets.sockets.values()) {
      if (String(socket.data.user?._id) === userId && socket.data.rooms.has(roomId)) {
        remove(socket, roomId, { silent: true });
      }
    }
    broadcast(roomId);
  }

  return { add, remove, removeSocket, removeUserFromRoom, list };
}
