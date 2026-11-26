import express, { Express, Request, Response, NextFunction } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import swaggerUi from 'swagger-ui-express';
import { config } from './config';
import { checkDatabaseConnection } from './database/prisma';
import { errorHandler } from './middleware/error-handler';
import { apiRateLimiter } from './middleware/rate-limiter';
import { swaggerDocument } from './docs/swagger';
import { NotFoundError } from './common/errors/app-error';

// Import module routers
import { authRouter } from './modules/auth/auth.routes';
import { usersRouter } from './modules/users/users.routes';
import { journeysRouter } from './modules/journeys/journeys.routes';
import { sessionsRouter } from './modules/sessions/sessions.routes';
import { groupsRouter } from './modules/groups/groups.routes';
import { reflectionsRouter } from './modules/reflections/reflections.routes';
import { updatesRouter } from './modules/updates/updates.routes';
import { dashboardRouter } from './modules/dashboard/dashboard.routes';
import { syncRouter } from './modules/sync/sync.routes';
import { archiveRouter } from './modules/archive/archive.routes';
import { queueRouter } from './modules/queue/queue.routes';
import { notificationsRouter } from './modules/notifications/notifications.routes';

export function createApp(): Express {
  const app = express();

  // Basic security and parsing
  app.use(helmet());
  app.use(
    cors({
      origin: config.CORS_ALLOWED_ORIGINS === '*' ? '*' : config.CORS_ALLOWED_ORIGINS.split(','),
      credentials: true,
    })
  );
  app.use(express.json({ limit: '2mb' }));
  app.use(express.urlencoded({ extended: true, limit: '2mb' }));

  // General rate limiter
  app.use(apiRateLimiter);

  // Health Checks (Render requirement: must respond with 200)
  app.get('/health/live', (_req: Request, res: Response) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
  });

  app.get('/health/ready', async (_req: Request, res: Response) => {
    const isDbConnected = await checkDatabaseConnection();
    if (isDbConnected) {
      res.status(200).json({ status: 'ready', database: 'connected' });
    } else {
      res.status(503).json({ status: 'not_ready', database: 'disconnected' });
    }
  });

  // Swagger Documentation
  app.use('/api/v1/docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
  app.use('/docs', (_req: Request, res: Response) => {
    res.redirect('/api/v1/docs');
  });

  // API v1 Routes
  const apiV1Router = express.Router();
  apiV1Router.use('/auth', authRouter);
  apiV1Router.use('/users', usersRouter);
  apiV1Router.use('/journeys', journeysRouter);
  apiV1Router.use('/sessions', sessionsRouter);
  apiV1Router.use('/groups', groupsRouter);
  apiV1Router.use('/reflections', reflectionsRouter);
  apiV1Router.use('/updates', updatesRouter);
  apiV1Router.use('/dashboard', dashboardRouter);
  apiV1Router.use('/sync', syncRouter);
  apiV1Router.use('/archive', archiveRouter);
  apiV1Router.use('/queue', queueRouter);
  apiV1Router.use('/notifications', notificationsRouter);

  app.use('/api/v1', apiV1Router);

  // 404 handler for unknown routes
  app.use((req: Request, _res: Response, next: NextFunction) => {
    next(new NotFoundError(`Cannot ${req.method} ${req.originalUrl}`));
  });

  // Global Error Handler
  app.use(errorHandler);

  return app;
}

export const app = createApp();
