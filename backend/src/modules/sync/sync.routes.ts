import { Router } from 'express';
import { syncController } from './sync.controller';
import { authenticate } from '../../middleware/authenticate';
import { validateBody } from '../../middleware/validate';
import { syncBatchSchema } from './sync.schema';

export const syncRouter = Router();

syncRouter.use(authenticate);

syncRouter.post('/events', validateBody(syncBatchSchema), syncController.processBatch);
