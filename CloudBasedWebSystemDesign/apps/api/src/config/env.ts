import { z } from 'zod';

const booleanString = z
  .enum(['true', 'false', '1', '0'])
  .optional()
  .transform((v) => v === 'true' || v === '1');

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(4000),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
  CORS_ORIGINS: z.string().default('http://localhost:5173'),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  JWT_SECRET: z.string().min(32, 'JWT_SECRET must be at least 32 characters'),
  JWT_EXPIRES_IN: z.string().default('8h'),
  SEED_ON_START: booleanString,
  SEED_DEMO_DATA: booleanString,
  ADMIN_EMAIL: z.email().default('admin@vaxtrack.sn'),
  ADMIN_PASSWORD: z.string().min(8).optional(),
  SMS_PROVIDER: z.enum(['console']).default('console'),
  REMINDER_WINDOW_DAYS: z.coerce.number().int().min(0).max(30).default(3),
  WEB_DIST_DIR: z.string().optional(),
  RATE_LIMIT_MAX: z.coerce.number().int().positive().default(300),
});

export type Env = z.infer<typeof envSchema>;

function loadEnv(): Env {
  const parsed = envSchema.safeParse(process.env);
  if (!parsed.success) {
    const details = parsed.error.issues.map((i) => `  - ${i.path.join('.')}: ${i.message}`).join('\n');
    // Fail fast: a misconfigured service must not start.
    throw new Error(`Invalid environment configuration:\n${details}`);
  }
  return parsed.data;
}

export const env = loadEnv();
export const corsOrigins = env.CORS_ORIGINS.split(',')
  .map((o) => o.trim())
  .filter(Boolean);
