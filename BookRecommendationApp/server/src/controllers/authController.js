import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import { getJwtSecret, JWT_EXPIRES_IN } from '../utils/config.js';
import { HttpError } from '../utils/httpError.js';

export function signToken(user) {
  return jwt.sign({ sub: user._id.toString(), username: user.username }, getJwtSecret(), { expiresIn: JWT_EXPIRES_IN });
}

export async function register(req, res) {
  const { username, email, password, favoriteGenres = [], bio = '' } = req.body;
  const exists = await User.findOne({ $or: [{ email: email.toLowerCase() }, { username }] });
  if (exists) throw new HttpError(409, exists.username === username ? "Ce nom d'utilisateur est déjà pris" : 'Cet email est déjà utilisé');
  const passwordHash = await bcrypt.hash(password, 10);
  const user = await User.create({ username, email, passwordHash, bio, favoriteGenres });
  res.status(201).json({ token: signToken(user), user: user.toPublic() });
}

export async function login(req, res) {
  const { email, password } = req.body;
  const user = await User.findOne({ email: email.toLowerCase() }).select('+passwordHash');
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    throw new HttpError(401, 'Email ou mot de passe incorrect');
  }
  res.json({ token: signToken(user), user: user.toPublic() });
}

export async function me(req, res) {
  res.json({ user: req.user.toPublic() });
}
