import { rateLimit } from 'express-rate-limit';
import { env } from '../config/env.js';

const common = {
  standardHeaders: 'draft-8' as const,
  legacyHeaders: false,
  skip: () => env.NODE_ENV === 'test',
  message: { error: { code: 'RATE_LIMITED', message: 'Too many requests, please try again later' } },
};

/** Global limiter for the whole API. */
export const apiLimiter = rateLimit({ ...common, windowMs: 15 * 60 * 1000, limit: env.RATE_LIMIT_MAX });

/** Stricter limiter for credential and public lookup endpoints (brute-force protection). */
export const sensitiveLimiter = rateLimit({ ...common, windowMs: 15 * 60 * 1000, limit: 20 });
