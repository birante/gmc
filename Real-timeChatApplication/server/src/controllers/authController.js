import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { User } from '../models/User.js';
import { signToken } from '../utils/jwt.js';
import { conflict, unauthorized } from '../utils/httpError.js';
import { randomAvatarColor } from '../utils/colors.js';

export const registerSchema = z.object({
  username: z
    .string({ required_error: "Le nom d'utilisateur est requis" })
    .trim()
    .min(2, "Le nom d'utilisateur doit contenir au moins 2 caractères")
    .max(30, "Le nom d'utilisateur ne doit pas dépasser 30 caractères")
    .regex(/^[\p{L}\p{N}_.-]+$/u, "Le nom d'utilisateur ne peut contenir que lettres, chiffres, . _ -"),
  email: z.string({ required_error: "L'email est requis" }).trim().toLowerCase().email('Email invalide'),
  password: z
    .string({ required_error: 'Le mot de passe est requis' })
    .min(6, 'Le mot de passe doit contenir au moins 6 caractères')
    .max(100),
});

export const loginSchema = z.object({
  email: z.string({ required_error: "L'email est requis" }).trim().toLowerCase().email('Email invalide'),
  password: z.string({ required_error: 'Le mot de passe est requis' }).min(1, 'Le mot de passe est requis'),
});

const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

export async function register(req, res) {
  const { username, email, password } = req.validated.body;
  const existing = await User.findOne({
    $or: [{ email }, { username: new RegExp(`^${escapeRegex(username)}$`, 'i') }],
  });
  if (existing) {
    throw conflict(existing.email === email ? 'Cet email est déjà utilisé' : "Ce nom d'utilisateur est déjà pris");
  }
  const passwordHash = await bcrypt.hash(password, 10);
  const user = await User.create({ username, email, passwordHash, avatarColor: randomAvatarColor() });
  res.status(201).json({ token: signToken(user), user: user.toPublic() });
}

export async function login(req, res) {
  const { email, password } = req.validated.body;
  const user = await User.findOne({ email });
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    throw unauthorized('Email ou mot de passe incorrect');
  }
  res.json({ token: signToken(user), user: user.toPublic() });
}

export function me(req, res) {
  res.json({ user: req.user.toPublic() });
}

export function logout(_req, res) {
  // JWT sans état : le client supprime son jeton et ferme son socket.
  res.status(204).end();
}
