import dotenv from 'dotenv';

dotenv.config({ quiet: true });

const isProduction = process.env.NODE_ENV === 'production';

if (isProduction && !process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET est obligatoire en production');
}

export const config = {
  env: process.env.NODE_ENV || 'development',
  isProduction,
  isTest: process.env.NODE_ENV === 'test',
  port: Number(process.env.PORT) || 3000,
  mongoUri: process.env.MONGODB_URI || 'mongodb://localhost:27017/waxtaan',
  jwtSecret: process.env.JWT_SECRET || 'dev-secret-waxtaan',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  seedOnStart: process.env.SEED_ON_START === 'true',
  clientOrigin: process.env.CLIENT_ORIGIN || '',
};
