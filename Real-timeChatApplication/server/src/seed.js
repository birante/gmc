import path from 'node:path';
import { fileURLToPath } from 'node:url';
import bcrypt from 'bcryptjs';
import mongoose from 'mongoose';
import { config } from './config.js';
import { User } from './models/User.js';
import { Room } from './models/Room.js';
import { Message } from './models/Message.js';

export const DEMO_USERS = [
  { username: 'awa', email: 'awa@waxtaan.sn', avatarColor: '#e76f51' },
  { username: 'moussa', email: 'moussa@waxtaan.sn', avatarColor: '#3a86ff' },
];
export const DEMO_PASSWORD = 'password123';

const ROOMS = [
  { name: 'Général', description: 'Discussions générales et annonces' },
  { name: 'Tech', description: 'Code, outils et nouveautés techniques' },
  { name: 'Détente', description: 'Pause café, musique et bonne humeur' },
];

/** Insère les données de démo si la base est vide. Renvoie true si le seed a eu lieu. */
export async function seedIfEmpty() {
  const [users, rooms] = await Promise.all([User.countDocuments(), Room.countDocuments()]);
  if (users > 0 || rooms > 0) return false;

  const passwordHash = await bcrypt.hash(DEMO_PASSWORD, 10);
  const created = await User.insertMany(DEMO_USERS.map((u) => ({ ...u, passwordHash })));
  const ids = created.map((u) => u._id);
  const createdRooms = await Room.insertMany(
    ROOMS.map((r) => ({ ...r, createdBy: ids[0], members: ids })),
  );
  const general = createdRooms[0];
  const now = Date.now();
  await Message.insertMany([
    { room: general._id, user: ids[0], text: 'Salut tout le monde, bienvenue sur Waxtaan !', createdAt: new Date(now - 120000) },
    { room: general._id, user: ids[1], text: 'Merci Awa ! Ça marche super bien 🙂', createdAt: new Date(now - 60000) },
  ]);
  return true;
}

const isMain = process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (isMain) {
  await mongoose.connect(config.mongoUri);
  const done = await seedIfEmpty();
  console.log(done ? 'Données de démo insérées.' : 'Base non vide : seed ignoré.');
  await mongoose.disconnect();
}
