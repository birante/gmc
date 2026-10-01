import { z } from 'zod';
import { User } from '../models/User.js';
import { signToken } from '../utils/token.js';
import { HttpError } from '../utils/httpError.js';

export const registerSchema = z.object({
  name: z.string().trim().min(2, 'au moins 2 caractères').max(80),
  email: z.string().trim().toLowerCase().email('email invalide'),
  password: z.string().min(6, 'au moins 6 caractères').max(128)
});

export const loginSchema = z.object({
  email: z.string().trim().toLowerCase().email('email invalide'),
  password: z.string().min(1, 'requis')
});

export async function register(req, res) {
  const { name, email, password } = req.body;
  if (await User.exists({ email })) throw new HttpError(409, 'Cet email est déjà utilisé');
  const user = await User.create({ name, email, passwordHash: await User.hashPassword(password), role: 'client' });
  res.status(201).json({ token: signToken(user), user });
}

export async function login(req, res) {
  const { email, password } = req.body;
  const user = await User.findOne({ email });
  if (!user || !(await user.checkPassword(password))) {
    throw new HttpError(401, 'Email ou mot de passe incorrect');
  }
  res.json({ token: signToken(user), user });
}

export async function me(req, res) {
  res.json({ user: req.user });
}
