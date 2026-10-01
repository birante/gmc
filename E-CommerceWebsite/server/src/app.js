import express from 'express';
import path from 'node:path';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import helmet from 'helmet';
import cors from 'cors';
import morgan from 'morgan';
import mongoose from 'mongoose';
import authRoutes from './routes/auth.js';
import productRoutes from './routes/products.js';
import orderRoutes from './routes/orders.js';
import { listCategories } from './controllers/productController.js';
import { asyncHandler } from './utils/httpError.js';
import { notFound, errorHandler } from './middleware/error.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const clientDist = path.resolve(__dirname, '../../client/dist');

export function createApp() {
  const app = express();
  app.set('trust proxy', 1);
  app.disable('x-powered-by');

  app.use(
    helmet({
      contentSecurityPolicy: {
        useDefaults: true,
        directives: {
          'img-src': ["'self'", 'https:', 'data:'],
          // kamal-proxy gère le TLS ; évite de casser un test local en HTTP
          'upgrade-insecure-requests': null
        }
      },
      crossOriginEmbedderPolicy: false
    })
  );
  app.use(cors());
  app.use(express.json({ limit: '100kb' }));
  if (process.env.NODE_ENV !== 'test') app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

  app.get('/up', (_req, res) => {
    if (mongoose.connection.readyState !== 1) return res.status(503).type('text').send('DB DOWN');
    res.status(200).type('text').send('OK');
  });

  app.use('/api/auth', authRoutes);
  app.use('/api/products', productRoutes);
  app.get('/api/categories', asyncHandler(listCategories));
  app.use('/api/orders', orderRoutes);
  app.use('/api', notFound);

  if (fs.existsSync(clientDist)) {
    app.use(express.static(clientDist, { index: false, maxAge: '1h' }));
    app.get('*', (_req, res) => res.sendFile(path.join(clientDist, 'index.html')));
  }

  app.use(notFound);
  app.use(errorHandler);
  return app;
}

export default createApp;
