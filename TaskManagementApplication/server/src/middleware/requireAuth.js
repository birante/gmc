import { User } from '../models/User.js';
import { verifyToken } from '../utils/token.js';
import { HttpError } from '../utils/HttpError.js';

export async function requireAuth(req, _res, next) {
  try {
    const header = req.headers.authorization || '';
    const [scheme, token] = header.split(' ');
    if (scheme !== 'Bearer' || !token) throw new HttpError(401, 'Authentification requise');
    let payload;
    try {
      payload = verifyToken(token);
    } catch {
      throw new HttpError(401, 'Jeton invalide ou expiré');
    }
    const user = await User.findById(payload.sub);
    if (!user) throw new HttpError(401, 'Utilisateur introuvable');
    req.user = user;
    next();
  } catch (err) {
    next(err);
  }
}
