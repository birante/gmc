import jwt, { type SignOptions } from 'jsonwebtoken';
import type { Role } from '@prisma/client';
import { env } from '../config/env.js';

export interface AuthUser {
  id: string;
  role: Role;
  clinicId: string | null;
}

interface TokenPayload {
  sub: string;
  role: Role;
  clinicId: string | null;
}

export function signToken(user: AuthUser): string {
  const payload: TokenPayload = { sub: user.id, role: user.role, clinicId: user.clinicId };
  return jwt.sign(payload, env.JWT_SECRET, {
    expiresIn: env.JWT_EXPIRES_IN as SignOptions['expiresIn'],
    issuer: 'vaxtrack',
  });
}

export function verifyToken(token: string): AuthUser {
  const decoded = jwt.verify(token, env.JWT_SECRET, { issuer: 'vaxtrack' }) as TokenPayload;
  return { id: decoded.sub, role: decoded.role, clinicId: decoded.clinicId ?? null };
}
