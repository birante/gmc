import type { NextFunction, Request, Response } from 'express';
import type { Role } from '@prisma/client';
import { forbidden, unauthorized } from '../lib/errors.js';
import { verifyToken, type AuthUser } from '../lib/jwt.js';

/** Verifies the `Authorization: Bearer <jwt>` header and attaches `req.user`. */
export function authenticate(req: Request, _res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) return next(unauthorized());
  try {
    req.user = verifyToken(header.slice('Bearer '.length).trim());
    next();
  } catch {
    next(unauthorized('Invalid or expired token'));
  }
}

/** Role-based access control: allow the request only for the listed roles. */
export function requireRole(...roles: Role[]) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.user) return next(unauthorized());
    if (!roles.includes(req.user.role)) return next(forbidden());
    next();
  };
}

/** Returns the authenticated user or throws (for use inside controllers). */
export function currentUser(req: Request): AuthUser {
  if (!req.user) throw unauthorized();
  return req.user;
}
