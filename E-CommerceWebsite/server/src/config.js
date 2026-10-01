import 'dotenv/config';

const env = process.env.NODE_ENV || 'development';

if (env === 'production' && !process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET est obligatoire en production');
}

export const config = {
  env,
  port: Number(process.env.PORT) || 3000,
  mongoUri: process.env.MONGODB_URI || 'mongodb://localhost:27017/boutik',
  jwtSecret: process.env.JWT_SECRET || 'dev-secret-change-me',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  seedOnStart: process.env.SEED_ON_START === 'true',
  adminPassword: process.env.ADMIN_PASSWORD || 'admin12345'
};
