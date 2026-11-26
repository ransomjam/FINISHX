import { Router } from 'express';
import { sessionsController } from './sessions.controller';
import { authenticate } from '../../middleware/authenticate';
import { validateBody, validateQuery } from '../../middleware/validate';
import {
  startSessionSchema,
  endSessionSchema,
  reflectSessionSchema,
  skipSessionSchema,
  listSessionsQuerySchema,
} from './sessions.schema';

export const sessionsRouter = Router();

sessionsRouter.use(authenticate);

sessionsRouter.get('/upcoming', sessionsController.getUpcoming);
sessionsRouter.get('/', validateQuery(listSessionsQuerySchema), sessionsController.list);

sessionsRouter.post('/:id/start', validateBody(startSessionSchema), sessionsController.start);
sessionsRouter.post('/:id/end', validateBody(endSessionSchema), sessionsController.end);
sessionsRouter.post('/:id/reflect', validateBody(reflectSessionSchema), sessionsController.reflect);
sessionsRouter.post('/:id/skip', validateBody(skipSessionSchema), sessionsController.skip);
