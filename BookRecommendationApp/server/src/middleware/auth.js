import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import { getJwtSecret } from '../utils/config.js';
import { HttpError } from '../utils/httpError.js';

async function resolveUser(req) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) return null;
  let payload;
  try {
    payload = jwt.verify(token, getJwtSecret());
  } catch {
    throw new HttpError(401, 'Jeton invalide ou expiré');
  }
  const user = await User.findById(payload.sub);
  if (!user) throw new HttpError(401, 'Utilisateur introuvable');
  return user;
}

export async function requireAuth(req, _res, next) {
  try {
    const user = await resolveUser(req);
    if (!user) throw new HttpError(401, 'Authentification requise');
    req.user = user;
    next();
  } catch (err) {
    next(err);
  }
}

/** Renseigne req.user si un jeton valide est fourni, sans l'exiger. */
export async function optionalAuth(req, _res, next) {
  try {
    req.user = (await resolveUser(req)) || null;
  } catch {
    req.user = null;
  }
  next();
}
