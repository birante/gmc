import { existsSync } from 'node:fs';
import path from 'node:path';
import compression from 'compression';
import cors from 'cors';
import express, { type Express } from 'express';
import helmet from 'helmet';
import { pinoHttp } from 'pino-http';
import swaggerUi from 'swagger-ui-express';
import { corsOrigins, env } from './config/env.js';
import { createContainer, type ContainerOptions } from './container.js';
import { openApiDocument } from './docs/openapi.js';
import { logger } from './lib/logger.js';
import { errorHandler, notFoundHandler } from './middleware/error-handler.js';
import { apiLimiter } from './middleware/rate-limit.js';
import { authRouter } from './modules/auth/auth.routes.js';
import { clinicsRouter } from './modules/clinics/clinics.routes.js';
import { dashboardRouter } from './modules/dashboard/dashboard.routes.js';
import { healthRouter } from './modules/health/health.routes.js';
import { immunizationsRouter } from './modules/immunizations/immunizations.routes.js';
import { patientsRouter } from './modules/patients/patients.routes.js';
import { publicRouter } from './modules/public/public.routes.js';
import { remindersRouter } from './modules/reminders/reminders.routes.js';
import { usersRouter } from './modules/users/users.routes.js';
import { vaccinesRouter } from './modules/vaccines/vaccines.routes.js';

export interface AppOptions extends ContainerOptions {
  /** Directory of the built React app to serve (single-service deployment). */
  webDistDir?: string;
}

export function createApp(options: AppOptions): Express {
  const { repos, services, controllers } = createContainer(options);
  const app = express();

  app.disable('x-powered-by');
  app.set('trust proxy', 1); // Render / most PaaS sit behind one reverse proxy.

  app.use(
    pinoHttp({
      logger,
      autoLogging: { ignore: (req) => req.url === '/health' },
      customLogLevel: (_req, res, err) => (err || res.statusCode >= 500 ? 'error' : res.statusCode >= 400 ? 'warn' : 'info'),
    }),
  );
  app.use(
    helmet({
      contentSecurityPolicy: {
        directives: {
          ...helmet.contentSecurityPolicy.getDefaultDirectives(),
          // Swagger UI ships inline styles/scripts.
          'script-src': ["'self'", "'unsafe-inline'"],
          'style-src': ["'self'", "'unsafe-inline'"],
        },
      },
    }),
  );
  app.use(cors({ origin: corsOrigins, credentials: false, maxAge: 600 }));
  app.use(compression());
  app.use(express.json({ limit: '100kb' }));

  app.use('/health', healthRouter(options.db));

  const api = express.Router();
  api.use(apiLimiter);
  api.get('/openapi.json', (_req, res) => res.json(openApiDocument));
  api.use('/docs', swaggerUi.serve, swaggerUi.setup(openApiDocument, { customSiteTitle: 'VaxTrack API' }));
  api.use('/health', healthRouter(options.db));
  api.use('/auth', authRouter(controllers.auth));
  api.use('/users', usersRouter(controllers.users));
  api.use('/clinics', clinicsRouter(controllers.clinics));
  api.use('/vaccines', vaccinesRouter(repos.vaccines));
  api.use('/patients', patientsRouter(controllers.patients));
  api.use('/immunizations', immunizationsRouter(controllers.immunizations));
  api.use('/dashboard', dashboardRouter(services.dashboard));
  api.use('/reminders', remindersRouter(services.reminders));
  api.use('/public', publicRouter(services.public));
  api.use(notFoundHandler);
  app.use('/api', api);

  // Optionally serve the compiled SPA from the same origin (one Render service, no CORS needed).
  const webDir = options.webDistDir ? path.resolve(options.webDistDir) : undefined;
  if (webDir && existsSync(path.join(webDir, 'index.html'))) {
    app.use(express.static(webDir, { index: false, maxAge: '1h' }));
    app.get(/^\/(?!api\/).*/, (_req, res) => res.sendFile(path.join(webDir, 'index.html')));
    logger.info({ webDir }, 'Serving front-end');
  }

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}

export { env };
