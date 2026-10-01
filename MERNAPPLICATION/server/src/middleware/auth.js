import jwt from 'jsonwebtoken';
import { verifyToken } from '../utils/token.js';
import { User } from '../models/User.js';
import { HttpError } from '../utils/httpError.js';

const extractToken = (req) => {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  return scheme === 'Bearer' && token ? token : null;
};

const loadUser = async (token) => {
  try {
    const payload = verifyToken(token);
    return await User.findById(payload.sub);
  } catch (err) {
    if (err instanceof jwt.TokenExpiredError) throw new HttpError(401, 'Session expirée, veuillez vous reconnecter');
    if (err instanceof jwt.JsonWebTokenError) throw new HttpError(401, 'Jeton invalide');
    throw err;
  }
};

export const requireAuth = async (req, _res, next) => {
  try {
    const token = extractToken(req);
    if (!token) throw new HttpError(401, 'Authentification requise');
    const user = await loadUser(token);
    if (!user) throw new HttpError(401, 'Utilisateur introuvable');
    req.user = user;
    next();
  } catch (err) {
    next(err);
  }
};

/** Authentification facultative : renseigne req.user si un jeton valide est présent. */
export const optionalAuth = async (req, _res, next) => {
  const token = extractToken(req);
  if (!token) return next();
  try {
    req.user = (await loadUser(token)) || undefined;
  } catch {
    req.user = undefined;
  }
  next();
};
