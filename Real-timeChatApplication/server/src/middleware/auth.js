import { User } from '../models/User.js';
import { verifyToken } from '../utils/jwt.js';
import { unauthorized } from '../utils/httpError.js';

export async function userFromToken(token) {
  if (!token) return null;
  try {
    const payload = verifyToken(token);
    return await User.findById(payload.sub);
  } catch {
    return null;
  }
}

export async function requireAuth(req, _res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) return next(unauthorized());
  const user = await userFromToken(token);
  if (!user) return next(unauthorized('Session invalide ou expirée'));
  req.user = user;
  next();
}
