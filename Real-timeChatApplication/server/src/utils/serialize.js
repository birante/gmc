export function publicUser(user) {
  if (!user) return null;
  return {
    id: String(user._id ?? user.id),
    username: user.username,
    avatarColor: user.avatarColor,
  };
}

export function serializeRoom(room, userId) {
  const members = (room.members || []).map((m) => (m && m.username ? publicUser(m) : { id: String(m) }));
  return {
    id: String(room._id),
    name: room.name,
    description: room.description || '',
    createdBy: room.createdBy && room.createdBy.username ? publicUser(room.createdBy) : room.createdBy ? { id: String(room.createdBy) } : null,
    members,
    memberCount: members.length,
    isMember: userId ? members.some((m) => m.id === String(userId)) : false,
    createdAt: room.createdAt,
  };
}

export function serializeMessage(msg) {
  return {
    id: String(msg._id),
    room: String(msg.room?._id ?? msg.room),
    user: publicUser(msg.user),
    text: msg.text,
    createdAt: msg.createdAt,
  };
}
